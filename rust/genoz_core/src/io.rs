//! Abertura de arquivos com detecção de compressão e escrita BGZF.
//!
//! BGZF (SAMv1.pdf, seção 4.1) é gzip em blocos independentes de até 64 KiB,
//! com o subcampo extra `BC`. Todo BGZF é um gzip válido de múltiplos membros,
//! então a leitura usa `MultiGzDecoder`; a distinção importa porque só BGZF
//! pode ser indexado (tabix/CSI).

use std::io::{self, BufRead, BufReader, Read, Write};

use flate2::read::MultiGzDecoder;
use flate2::write::DeflateEncoder;
use serde::Serialize;

use crate::Result;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Compression {
    None,
    /// gzip comum: legível, mas não indexável.
    Gzip,
    /// BGZF: gzip em blocos, indexável por tabix/CSI.
    Bgzf,
}

impl Compression {
    pub fn label(self) -> &'static str {
        match self {
            Compression::None => "nenhuma (texto)",
            Compression::Gzip => "gzip comum (não indexável)",
            Compression::Bgzf => "BGZF (indexável)",
        }
    }
}

pub fn detect_compression(prefix: &[u8]) -> Compression {
    if prefix.len() < 2 || prefix[0] != 0x1f || prefix[1] != 0x8b {
        return Compression::None;
    }
    let has_extra = prefix.len() > 3 && prefix[3] & 0x04 != 0;
    if has_extra && prefix.len() >= 14 && prefix[12] == b'B' && prefix[13] == b'C' {
        Compression::Bgzf
    } else {
        Compression::Gzip
    }
}

const READ_BUF: usize = 1 << 16;

/// Abre qualquer fonte de bytes, descompactando automaticamente se for gzip/BGZF.
pub fn open_reader<'a, R: Read + 'a>(reader: R) -> Result<(Compression, Box<dyn BufRead + 'a>)> {
    let mut buffered = BufReader::with_capacity(READ_BUF, reader);
    let compression = detect_compression(buffered.fill_buf()?);
    let out: Box<dyn BufRead + 'a> = match compression {
        Compression::None => Box::new(buffered),
        Compression::Gzip | Compression::Bgzf => {
            Box::new(BufReader::with_capacity(READ_BUF, MultiGzDecoder::new(buffered)))
        }
    };
    Ok((compression, out))
}

/// Tamanho máximo de dados por bloco BGZF (mesmo valor usado pelo htslib).
const BGZF_BLOCK_DATA: usize = 0xff00;

/// Bloco vazio que marca o fim de um arquivo BGZF (SAMv1, 4.1.2).
pub const BGZF_EOF: [u8; 28] = [
    0x1f, 0x8b, 0x08, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x06, 0x00, 0x42, 0x43, 0x02, 0x00, 0x1b, 0x00, 0x03,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
];

/// Escritor BGZF. É obrigatório chamar [`BgzfWriter::finish`] no fim.
pub struct BgzfWriter<W: Write> {
    inner: W,
    buf: Vec<u8>,
}

impl<W: Write> BgzfWriter<W> {
    pub fn new(inner: W) -> Self {
        Self { inner, buf: Vec::with_capacity(BGZF_BLOCK_DATA) }
    }

    fn write_block(&mut self, data: &[u8]) -> io::Result<()> {
        let mut enc = DeflateEncoder::new(Vec::new(), flate2::Compression::default());
        enc.write_all(data)?;
        let cdata = enc.finish()?;
        // BSIZE = tamanho total do bloco - 1 (cabeçalho 18 + dados + rodapé 8).
        let bsize = u16::try_from(cdata.len() + 25).map_err(|_| io::Error::other("bloco BGZF excedeu 64 KiB"))?;
        let mut header = [0x1f, 0x8b, 0x08, 0x04, 0, 0, 0, 0, 0, 0xff, 0x06, 0x00, b'B', b'C', 0x02, 0x00, 0, 0];
        header[16..18].copy_from_slice(&bsize.to_le_bytes());
        self.inner.write_all(&header)?;
        self.inner.write_all(&cdata)?;
        self.inner.write_all(&crc32fast::hash(data).to_le_bytes())?;
        self.inner.write_all(&(data.len() as u32).to_le_bytes())?;
        Ok(())
    }

    pub fn finish(mut self) -> io::Result<W> {
        if !self.buf.is_empty() {
            let data = std::mem::take(&mut self.buf);
            self.write_block(&data)?;
        }
        self.inner.write_all(&BGZF_EOF)?;
        self.inner.flush()?;
        Ok(self.inner)
    }
}

impl<W: Write> Write for BgzfWriter<W> {
    fn write(&mut self, data: &[u8]) -> io::Result<usize> {
        let take = data.len().min(BGZF_BLOCK_DATA - self.buf.len());
        self.buf.extend_from_slice(&data[..take]);
        if self.buf.len() == BGZF_BLOCK_DATA {
            let block = std::mem::take(&mut self.buf);
            self.write_block(&block)?;
            self.buf = block;
            self.buf.clear();
        }
        Ok(take)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.inner.flush()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn bgzf(data: &[u8]) -> Vec<u8> {
        let mut w = BgzfWriter::new(Vec::new());
        w.write_all(data).unwrap();
        w.finish().unwrap()
    }

    #[test]
    fn bgzf_round_trip_multi_block() {
        let data: Vec<u8> = (0..200_000u32).flat_map(|i| format!("{i}\n").into_bytes()).collect();
        let packed = bgzf(&data);
        assert_eq!(detect_compression(&packed), Compression::Bgzf);
        assert!(packed.ends_with(&BGZF_EOF));
        let (c, mut r) = open_reader(&packed[..]).unwrap();
        assert_eq!(c, Compression::Bgzf);
        let mut out = Vec::new();
        r.read_to_end(&mut out).unwrap();
        assert_eq!(out, data);
    }

    #[test]
    fn plain_gzip_is_not_bgzf() {
        let mut enc = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
        enc.write_all(b"##fileformat=VCFv4.3\n").unwrap();
        let gz = enc.finish().unwrap();
        assert_eq!(detect_compression(&gz), Compression::Gzip);
    }

    #[test]
    fn plain_text_passthrough() {
        let (c, mut r) = open_reader(&b"abc"[..]).unwrap();
        assert_eq!(c, Compression::None);
        let mut s = String::new();
        r.read_to_string(&mut s).unwrap();
        assert_eq!(s, "abc");
    }
}

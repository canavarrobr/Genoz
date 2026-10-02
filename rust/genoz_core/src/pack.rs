//! Pacote de projeto (conteúdo do cofre `.genoz`, Módulo 11): sequência de arquivos
//! em fluxo, sem índice no fim (dá para escrever e ler sem voltar no arquivo).
//!
//! Formato: `GNZPACK1` · entradas (`1` · tamanho do caminho u16 · caminho UTF-8 ·
//! tamanho u64 · bytes) · `0` (fim). Caminhos são relativos, com `/`, sem `..`.

use std::io::{self, Read, Write};

use crate::error::{GenozError, Result};

pub const PACK_MAGIC: &[u8; 8] = b"GNZPACK1";

/// Caminho seguro dentro do pacote (nada de sair da pasta de destino ao extrair).
pub fn valid_path(p: &str) -> bool {
    !p.is_empty()
        && p.len() <= 1024
        && !p.starts_with('/')
        && !p.contains('\\')
        && !p.contains(':')
        && !p.contains('\0')
        && p.split('/').all(|c| !c.is_empty() && c != "." && c != "..")
}

pub struct PackWriter<W: Write> {
    out: W,
}

impl<W: Write> PackWriter<W> {
    pub fn new(mut out: W) -> io::Result<Self> {
        out.write_all(PACK_MAGIC)?;
        Ok(Self { out })
    }

    /// Acrescenta um arquivo; `data` precisa ter exatamente `size` bytes.
    pub fn add(&mut self, path: &str, size: u64, data: &mut dyn Read) -> Result<()> {
        if !valid_path(path) {
            return Err(GenozError::InvalidParam(format!("caminho inválido no pacote: {path}")));
        }
        self.out.write_all(&[1])?;
        self.out.write_all(&(path.len() as u16).to_le_bytes())?;
        self.out.write_all(path.as_bytes())?;
        self.out.write_all(&size.to_le_bytes())?;
        let copied = io::copy(&mut data.take(size), &mut self.out)?;
        if copied != size {
            return Err(GenozError::InvalidParam(format!("{path}: o arquivo mudou de tamanho durante a exportação")));
        }
        Ok(())
    }

    pub fn add_bytes(&mut self, path: &str, data: &[u8]) -> Result<()> {
        self.add(path, data.len() as u64, &mut &data[..])
    }

    pub fn finish(mut self) -> io::Result<W> {
        self.out.write_all(&[0])?;
        self.out.flush()?;
        Ok(self.out)
    }
}

fn corrupt() -> GenozError {
    GenozError::InvalidParam("pacote do projeto corrompido".into())
}

/// Percorre o pacote; `on_entry` recebe caminho, tamanho e um leitor com os bytes
/// (o que ele não ler é descartado). Erros de leitura do cofre passam adiante.
pub fn read_pack<R: Read>(mut r: R, mut on_entry: impl FnMut(&str, u64, &mut dyn Read) -> Result<()>) -> Result<()> {
    let mut magic = [0u8; 8];
    r.read_exact(&mut magic)?;
    if &magic != PACK_MAGIC {
        return Err(corrupt());
    }
    loop {
        let mut kind = [0u8; 1];
        r.read_exact(&mut kind)?;
        match kind[0] {
            0 => return Ok(()),
            1 => {}
            _ => return Err(corrupt()),
        }
        let mut len = [0u8; 2];
        r.read_exact(&mut len)?;
        let mut path = vec![0u8; u16::from_le_bytes(len) as usize];
        r.read_exact(&mut path)?;
        let path = String::from_utf8(path).map_err(|_| corrupt())?;
        if !valid_path(&path) {
            return Err(corrupt());
        }
        let mut size = [0u8; 8];
        r.read_exact(&mut size)?;
        let size = u64::from_le_bytes(size);
        let mut entry = (&mut r).take(size);
        on_entry(&path, size, &mut entry)?;
        io::copy(&mut entry, &mut io::sink())?;
        if entry.limit() != 0 {
            return Err(io::Error::from(io::ErrorKind::UnexpectedEof).into());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_and_partial_reads() {
        let mut w = PackWriter::new(Vec::new()).unwrap();
        w.add_bytes("projeto.json", b"{\"nome\":\"x\"}").unwrap();
        w.add_bytes("arquivos/a.vcf", &[b'A'; 70_000]).unwrap();
        w.add_bytes("vazio", b"").unwrap();
        let bytes = w.finish().unwrap();

        let mut seen = Vec::new();
        read_pack(&bytes[..], |p, size, r| {
            // Lê só um pedaço: o resto é descartado sem desalinhar o próximo.
            let mut first = [0u8; 2];
            let n = r.read(&mut first)?;
            seen.push((p.to_string(), size, first[..n].to_vec()));
            Ok(())
        })
        .unwrap();
        assert_eq!(seen[0], ("projeto.json".into(), 12, b"{\"".to_vec()));
        assert_eq!(seen[1].0, "arquivos/a.vcf");
        assert_eq!(seen[1].1, 70_000);
        assert_eq!(seen[2], ("vazio".into(), 0, vec![]));
    }

    #[test]
    fn rejects_unsafe_paths_and_truncation() {
        for bad in ["../x", "/etc/passwd", "a/../b", "a\\b", "C:/x", "", "a//b", "./a"] {
            assert!(!valid_path(bad), "{bad}");
            assert!(PackWriter::new(Vec::new()).unwrap().add_bytes(bad, b"x").is_err());
        }
        assert!(valid_path("projetos/p1/arquivos/f1.vcf.gz"));

        let mut w = PackWriter::new(Vec::new()).unwrap();
        w.add_bytes("a", &[1; 100]).unwrap();
        let bytes = w.finish().unwrap();
        assert!(read_pack(&bytes[..50], |_, _, _| Ok(())).is_err());
        assert!(read_pack(&bytes[..bytes.len() - 1], |_, _, _| Ok(())).is_err());
        assert!(read_pack(&b"PK\x03\x04xxxx"[..], |_, _, _| Ok(())).is_err());

        // Tamanho declarado diferente do conteúdo.
        let mut w = PackWriter::new(Vec::new()).unwrap();
        assert!(w.add("a", 10, &mut &b"curto"[..]).is_err());
    }
}

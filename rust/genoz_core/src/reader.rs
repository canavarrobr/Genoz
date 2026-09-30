//! Leitor VCF em streaming.

use std::io::{BufRead, Read};

use serde::Serialize;

use crate::header::VcfHeader;
use crate::io::{open_reader, Compression};
use crate::record::{parse_record, ParsedLine};
use crate::{GenozError, Result};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Severity {
    /// A linha foi descartada.
    Error,
    /// A linha foi aceita, mas merece atenção.
    Warning,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum IssueCode {
    MissingFileFormat,
    UnsupportedVersion,
    TooFewColumns,
    SampleCountMismatch,
    InvalidChrom,
    InvalidPos,
    InvalidRef,
    InvalidAlt,
    AltEqualsRef,
    InvalidQual,
    GtNotFirst,
    InvalidGenotype,
    GenotypeAlleleOutOfRange,
    ContigNotInHeader,
    UnsortedPositions,
    ChromNotContiguous,
    EmptyLine,
    NotUtf8,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Issue {
    /// Linha do arquivo (1-based); 0 = arquivo como um todo.
    pub line: u64,
    pub severity: Severity,
    pub code: IssueCode,
    pub message: String,
}

impl Issue {
    pub fn error(line: u64, code: IssueCode, message: String) -> Self {
        Self { line, severity: Severity::Error, code, message }
    }

    pub fn warning(line: u64, code: IssueCode, message: String) -> Self {
        Self { line, severity: Severity::Warning, code, message }
    }
}

pub struct VcfReader<'a> {
    inner: Box<dyn BufRead + 'a>,
    header: VcfHeader,
    compression: Compression,
    line_no: u64,
    buf: Vec<u8>,
    header_issues: Vec<Issue>,
}

impl<'a> VcfReader<'a> {
    /// Lê o cabeçalho. Falha se não houver a linha `#CHROM`.
    pub fn new<R: Read + 'a>(source: R) -> Result<Self> {
        let (compression, inner) = open_reader(source)?;
        let mut reader = VcfReader {
            inner,
            header: VcfHeader::default(),
            compression,
            line_no: 0,
            buf: Vec::with_capacity(1024),
            header_issues: Vec::new(),
        };
        reader.read_header()?;
        Ok(reader)
    }

    pub fn header(&self) -> &VcfHeader {
        &self.header
    }

    pub fn compression(&self) -> Compression {
        self.compression
    }

    /// Avisos encontrados no cabeçalho (ex.: `##fileformat` ausente).
    pub fn header_issues(&self) -> &[Issue] {
        &self.header_issues
    }

    /// Lê a próxima linha crua (sem `\r\n`). `Ok(None)` no fim do arquivo.
    fn next_line(&mut self) -> Result<Option<std::result::Result<String, u64>>> {
        self.buf.clear();
        let n = self.inner.read_until(b'\n', &mut self.buf)?;
        if n == 0 {
            return Ok(None);
        }
        self.line_no += 1;
        while matches!(self.buf.last(), Some(b'\n' | b'\r')) {
            self.buf.pop();
        }
        Ok(Some(match std::str::from_utf8(&self.buf) {
            Ok(s) => Ok(s.to_string()),
            Err(_) => Err(self.line_no),
        }))
    }

    fn read_header(&mut self) -> Result<()> {
        loop {
            let line = match self.next_line()? {
                None if self.line_no == 0 => return Err(GenozError::InvalidHeader("o arquivo está vazio".into())),
                None => {
                    return Err(GenozError::InvalidHeader(
                        "linha '#CHROM' não encontrada; o arquivo não parece ser VCF".into(),
                    ))
                }
                // Comentários com acentos em Latin-1/Windows-1252 são comuns;
                // aceitamos com aviso em vez de recusar o arquivo inteiro.
                Some(Err(line)) => {
                    self.header_issues.push(Issue::warning(
                        line,
                        IssueCode::NotUtf8,
                        "linha do cabeçalho com caracteres fora de UTF-8; acentos podem aparecer trocados".into(),
                    ));
                    String::from_utf8_lossy(&self.buf).into_owned()
                }
                Some(Ok(l)) => l,
            };
            if self.line_no == 1 && !line.starts_with("##fileformat=VCF") {
                self.header_issues.push(Issue::warning(
                    0,
                    IssueCode::MissingFileFormat,
                    "a primeira linha deveria ser '##fileformat=VCFv4.x'".into(),
                ));
            }
            if line.starts_with("##") {
                self.header.push_meta_line(&line);
            } else if let Some(cols) = line.strip_prefix("#CHROM") {
                let cols: Vec<&str> = cols.split('\t').skip(1).collect();
                let expected = ["POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO"];
                if cols.len() < expected.len() || cols[..expected.len()] != expected {
                    return Err(GenozError::InvalidHeader(
                        "a linha '#CHROM' não tem as colunas obrigatórias separadas por TAB".into(),
                    ));
                }
                if cols.len() > 8 {
                    if cols[7] != "FORMAT" {
                        return Err(GenozError::InvalidHeader("a 9ª coluna do cabeçalho deveria ser FORMAT".into()));
                    }
                    self.header.samples = cols[8..].iter().map(|s| s.to_string()).collect();
                }
                break;
            } else if line.trim().is_empty() {
                continue;
            } else {
                return Err(GenozError::InvalidHeader(format!(
                    "linha {} aparece antes de '#CHROM'; o arquivo não parece ser VCF",
                    self.line_no
                )));
            }
        }
        if let Some(ff) = &self.header.file_format {
            let supported = ["VCFv4.1", "VCFv4.2", "VCFv4.3", "VCFv4.4", "VCFv4.5"];
            if !supported.contains(&ff.as_str()) {
                self.header_issues.push(Issue::warning(
                    0,
                    IssueCode::UnsupportedVersion,
                    format!("versão '{ff}' não testada; suportadas: VCFv4.1 a VCFv4.5"),
                ));
            }
        }
        Ok(())
    }

    /// Próxima linha de dados interpretada. `Ok(None)` no fim do arquivo.
    /// `Err` apenas para falhas fatais de leitura (ex.: gzip corrompido).
    pub fn next_parsed(&mut self) -> Result<Option<ParsedLine>> {
        loop {
            let line = match self.next_line()? {
                None => return Ok(None),
                Some(Err(line)) => {
                    return Ok(Some(ParsedLine {
                        record: None,
                        issues: vec![Issue::error(line, IssueCode::NotUtf8, "linha não é texto UTF-8 válido".into())],
                    }))
                }
                Some(Ok(l)) => l,
            };
            if line.is_empty() {
                continue;
            }
            return Ok(Some(parse_record(&line, self.line_no, &self.header)));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_non_vcf() {
        let txt = "# This data file generated by 23andMe\n# rsid\tchromosome\tposition\tgenotype\nrs1\t1\t100\tAA\n";
        let err = VcfReader::new(txt.as_bytes()).err().unwrap();
        assert!(matches!(err, GenozError::InvalidHeader(_)));
    }

    #[test]
    fn rejects_empty() {
        assert!(matches!(VcfReader::new(&b""[..]).err().unwrap(), GenozError::InvalidHeader(_)));
    }

    #[test]
    fn latin1_header_is_accepted_with_warning() {
        // 0xE3 = "ã" em Latin-1 (inválido em UTF-8).
        let mut vcf = b"##fileformat=VCFv4.2\n##comment=amostra de Jo\xe3o\n".to_vec();
        vcf.extend_from_slice(b"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n1\t10\t.\tA\tG\t.\t.\t.\n");
        let mut r = VcfReader::new(&vcf[..]).unwrap();
        assert_eq!(r.header_issues()[0].code, IssueCode::NotUtf8);
        assert!(r.next_parsed().unwrap().unwrap().record.is_some());
    }

    #[test]
    fn crlf_and_blank_lines() {
        let vcf = "##fileformat=VCFv4.2\r\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\r\n\r\n1\t10\t.\tA\tG\t.\tPASS\t.\r\n";
        let mut r = VcfReader::new(vcf.as_bytes()).unwrap();
        let p = r.next_parsed().unwrap().unwrap();
        assert_eq!(p.record.unwrap().pos, 10);
        assert!(r.next_parsed().unwrap().is_none());
    }
}

//! FASTA de referência local, com índice `.fai` (o mesmo formato do `samtools faidx`).
//!
//! Usado para: (1) normalização completa de indels — alinhamento à esquerda e
//! aparo (Tan, Abecasis & Kang, 2015); (2) conferir se o REF de um VCF bate com a
//! referência (REF diferente = build errado); (3) saber a base de referência de
//! sítios de chip sem registro no VCF.
//!
//! Só FASTA sem compressão (busca direta por posição). O índice pode vir pronto
//! (`.fai`) ou ser criado numa passada pelo arquivo.

use std::collections::HashMap;
use std::io::{BufRead, Read, Seek, SeekFrom};

use crate::chrom::canonical_chrom;
use crate::{GenozError, Result};

/// Uma linha do `.fai`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FaiEntry {
    pub name: String,
    pub length: u64,
    /// Byte onde começa a sequência.
    pub offset: u64,
    pub line_bases: u64,
    /// Bases + quebra de linha (`\n` ou `\r\n`).
    pub line_bytes: u64,
}

#[derive(Debug, Clone, Default)]
pub struct FastaIndex {
    pub entries: Vec<FaiEntry>,
    by_canonical: HashMap<String, usize>,
}

impl FastaIndex {
    fn from_entries(entries: Vec<FaiEntry>) -> Self {
        let by_canonical = entries.iter().enumerate().map(|(i, e)| (canonical_chrom(&e.name), i)).collect();
        Self { entries, by_canonical }
    }

    /// Lê um `.fai` (5 colunas separadas por TAB).
    pub fn parse(text: &str) -> Result<Self> {
        let mut entries = Vec::new();
        for (i, line) in text.lines().enumerate().filter(|(_, l)| !l.trim().is_empty()) {
            let c: Vec<&str> = line.split('\t').collect();
            let num = |k: usize| -> Result<u64> {
                c.get(k)
                    .and_then(|v| v.trim().parse().ok())
                    .ok_or_else(|| GenozError::InvalidParam(format!("índice .fai inválido na linha {}", i + 1)))
            };
            if c.len() < 5 {
                return Err(GenozError::InvalidParam(format!("índice .fai inválido na linha {}", i + 1)));
            }
            entries.push(FaiEntry {
                name: c[0].to_string(),
                length: num(1)?,
                offset: num(2)?,
                line_bases: num(3)?,
                line_bytes: num(4)?,
            });
        }
        Ok(Self::from_entries(entries))
    }

    /// Cria o índice lendo o FASTA inteiro uma vez.
    pub fn build<R: Read>(source: R) -> Result<Self> {
        let mut reader = std::io::BufReader::with_capacity(1 << 20, source);
        let mut entries: Vec<FaiEntry> = Vec::new();
        let mut offset = 0u64;
        let mut line = Vec::new();
        // Estado da sequência atual: tamanho da linha, se já vimos uma linha mais curta.
        let mut cur: Option<FaiEntry> = None;
        let mut short_seen = false;
        loop {
            line.clear();
            let n = reader.read_until(b'\n', &mut line)? as u64;
            if n == 0 {
                break;
            }
            let start = offset;
            offset += n;
            if line.first() == Some(&b'>') {
                if let Some(e) = cur.take() {
                    entries.push(e);
                }
                let name =
                    String::from_utf8_lossy(&line[1..]).split_whitespace().next().unwrap_or_default().to_string();
                if name.is_empty() {
                    return Err(GenozError::InvalidParam(format!("FASTA: cabeçalho sem nome no byte {start}")));
                }
                cur = Some(FaiEntry { name, length: 0, offset, line_bases: 0, line_bytes: 0 });
                short_seen = false;
                continue;
            }
            let Some(e) = cur.as_mut() else {
                if line.iter().all(u8::is_ascii_whitespace) {
                    continue;
                }
                return Err(GenozError::InvalidParam("FASTA: sequência antes do primeiro '>'".into()));
            };
            let bases = line.iter().filter(|b| !b.is_ascii_whitespace()).count() as u64;
            if bases == 0 {
                continue;
            }
            if e.line_bases == 0 {
                e.line_bases = bases;
                e.line_bytes = n;
            } else if short_seen || bases > e.line_bases || (bases == e.line_bases && n != e.line_bytes) {
                return Err(GenozError::InvalidParam(format!(
                    "FASTA: linhas de tamanhos diferentes em '{}' (não dá para indexar)",
                    e.name
                )));
            } else if bases < e.line_bases {
                short_seen = true;
            }
            e.length += bases;
        }
        if let Some(e) = cur.take() {
            entries.push(e);
        }
        if entries.is_empty() {
            return Err(GenozError::InvalidParam("o arquivo não parece ser FASTA (nenhum '>')".into()));
        }
        Ok(Self::from_entries(entries))
    }

    /// Texto `.fai` (igual ao do `samtools faidx`).
    pub fn to_fai(&self) -> String {
        self.entries
            .iter()
            .map(|e| format!("{}\t{}\t{}\t{}\t{}\n", e.name, e.length, e.offset, e.line_bases, e.line_bytes))
            .collect()
    }

    /// Entrada pelo nome canônico (`chr7` e `7` são o mesmo cromossomo).
    pub fn get(&self, chrom: &str) -> Option<&FaiEntry> {
        self.by_canonical.get(&canonical_chrom(chrom)).map(|&i| &self.entries[i])
    }
}

/// Fonte de bases de referência (FASTA indexado, ou qualquer outra).
pub trait SequenceSource {
    /// Bases `start..=end` (1-based), em maiúsculas. `None` se o cromossomo não existe.
    fn fetch(&mut self, chrom: &str, start: u64, end: u64) -> Result<Option<Vec<u8>>>;

    fn base(&mut self, chrom: &str, pos: u64) -> Result<Option<u8>> {
        Ok(self.fetch(chrom, pos, pos)?.and_then(|v| v.first().copied()))
    }

    /// Comprimento do cromossomo, se conhecido.
    fn length(&self, chrom: &str) -> Option<u64>;
}

/// FASTA com índice e acesso por posição.
pub struct IndexedFasta<R: Read + Seek> {
    pub index: FastaIndex,
    reader: R,
}

impl<R: Read + Seek> IndexedFasta<R> {
    pub fn new(reader: R, index: FastaIndex) -> Self {
        Self { index, reader }
    }
}

impl<R: Read + Seek> SequenceSource for IndexedFasta<R> {
    fn fetch(&mut self, chrom: &str, start: u64, end: u64) -> Result<Option<Vec<u8>>> {
        let Some(e) = self.index.get(chrom).cloned() else { return Ok(None) };
        if start == 0 || start > end || start > e.length {
            return Ok(Some(Vec::new()));
        }
        let end = end.min(e.length);
        let byte_of = |p: u64| e.offset + (p - 1) / e.line_bases * e.line_bytes + (p - 1) % e.line_bases;
        let (first, last) = (byte_of(start), byte_of(end));
        let mut raw = vec![0u8; (last - first + 1) as usize];
        self.reader.seek(SeekFrom::Start(first))?;
        self.reader.read_exact(&mut raw)?;
        let mut out: Vec<u8> = raw.into_iter().filter(|b| !b.is_ascii_whitespace()).collect();
        out.make_ascii_uppercase();
        Ok(Some(out))
    }

    fn length(&self, chrom: &str) -> Option<u64> {
        self.index.get(chrom).map(|e| e.length)
    }
}

/// Abre um FASTA do disco: usa `<arquivo>.fai` se existir; senão cria o índice
/// (e tenta gravá-lo ao lado, como o `samtools faidx`). Devolve também se o
/// índice foi criado agora.
pub fn open_fasta(path: &std::path::Path) -> Result<(IndexedFasta<std::io::BufReader<std::fs::File>>, bool)> {
    let mut head = [0u8; 2];
    let n = std::fs::File::open(path)?.read(&mut head)?;
    if n == 2 && head == [0x1f, 0x8b] {
        return Err(GenozError::InvalidParam(
            "FASTA compactado: descompacte (gunzip) para permitir a busca por posição".into(),
        ));
    }
    let fai = std::path::PathBuf::from(format!("{}.fai", path.display()));
    let (index, created) = match std::fs::read_to_string(&fai) {
        Ok(text) => (FastaIndex::parse(&text)?, false),
        Err(_) => {
            let index = FastaIndex::build(std::fs::File::open(path)?)?;
            let _ = std::fs::write(&fai, index.to_fai());
            (index, true)
        }
    };
    let reader = std::io::BufReader::with_capacity(64 * 1024, std::fs::File::open(path)?);
    Ok((IndexedFasta::new(reader, index), created))
}

/// Resumo de um FASTA importado.
#[derive(Debug, Clone, Default, serde::Serialize)]
pub struct FastaSummary {
    pub sequences: u64,
    pub total_bases: u64,
    /// Nomes e comprimentos (os primeiros 50).
    pub names: Vec<(String, u64)>,
    /// Texto do índice `.fai` (o app grava ao lado do arquivo).
    pub fai: String,
}

/// Inspeção de um FASTA: indexa (valida) e deduz o build pelos comprimentos
/// dos cromossomos, como no cabeçalho de um VCF.
pub fn inspect_fasta<R: Read>(source: R) -> Result<(crate::inspect::InspectReport, FastaSummary)> {
    use crate::inspect::{ChromCount, InspectReport, Verdict};
    let (index, fatal) = match FastaIndex::build(source) {
        Ok(i) => (i, None),
        Err(e) => (FastaIndex::default(), Some(e.user_message())),
    };
    let contigs: Vec<crate::header::Contig> = index
        .entries
        .iter()
        .map(|e| crate::header::Contig {
            id: e.name.clone(),
            canonical: canonical_chrom(&e.name),
            length: Some(e.length),
            assembly: None,
        })
        .collect();
    let build = crate::build::guess_build(&contigs, None);
    let summary = FastaSummary {
        sequences: index.entries.len() as u64,
        total_bases: index.entries.iter().map(|e| e.length).sum(),
        names: index.entries.iter().take(50).map(|e| (e.name.clone(), e.length)).collect(),
        fai: index.to_fai(),
    };
    let report = InspectReport {
        core_version: crate::CORE_VERSION,
        digest: None,
        compression: crate::io::Compression::None,
        file_format: Some("fasta".into()),
        build,
        chrom_style: crate::chrom::ChromStyle::Unknown,
        contigs_in_header: index.entries.len(),
        info_fields: 0,
        format_fields: 0,
        samples: Vec::new(),
        records_read: 0,
        records_ok: 0,
        records_rejected: 0,
        multiallelic: 0,
        biallelic_after_split: 0,
        by_kind: Default::default(),
        by_chrom: index
            .entries
            .iter()
            .map(|e| ChromCount { chrom: canonical_chrom(&e.name), raw: e.name.clone(), records: e.length })
            .collect(),
        filter_pass: 0,
        filter_failed: 0,
        filter_missing: 0,
        sorted: true,
        errors: u64::from(fatal.is_some()),
        warnings: 0,
        issue_counts: Default::default(),
        issues: Vec::new(),
        issues_truncated: false,
        verdict: if fatal.is_some() { Verdict::Invalid } else { Verdict::Valid },
        fatal,
    };
    Ok((report, summary))
}

/// Resultado da normalização de uma variante.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Normalized {
    pub pos: u64,
    pub reference: String,
    pub alt: String,
}

/// Alinha à esquerda e apara uma variante bialélica (VT normalize, Tan et al. 2015).
/// SNVs e alelos simbólicos (`<DEL>`, `*`…) voltam como estão.
pub fn left_align(
    seq: &mut dyn SequenceSource,
    chrom: &str,
    pos: u64,
    reference: &str,
    alt: &str,
) -> Result<Normalized> {
    let unchanged = || Normalized { pos, reference: reference.into(), alt: alt.into() };
    let plain = |s: &str| !s.is_empty() && s.bytes().all(|b| b.is_ascii_alphabetic());
    if !plain(reference) || !plain(alt) || (reference.len() == 1 && alt.len() == 1) {
        return Ok(unchanged());
    }
    let mut r: Vec<u8> = reference.to_ascii_uppercase().into_bytes();
    let mut a: Vec<u8> = alt.to_ascii_uppercase().into_bytes();
    let mut p = pos;
    // Janela de bases à esquerda, buscada aos poucos.
    let mut window: Vec<u8> = Vec::new();
    let mut window_start = p;
    loop {
        let mut changed = false;
        if r.len() > 1 || a.len() > 1 {
            if let (Some(x), Some(y)) = (r.last(), a.last()) {
                if x == y {
                    r.pop();
                    a.pop();
                    changed = true;
                }
            }
        }
        if r.is_empty() || a.is_empty() {
            if p <= 1 {
                break;
            }
            p -= 1;
            if p < window_start {
                let from = p.saturating_sub(99).max(1);
                match seq.fetch(chrom, from, p)? {
                    Some(w) if w.len() as u64 == p - from + 1 => {
                        window = w;
                        window_start = from;
                    }
                    _ => return Ok(unchanged()),
                }
            }
            let b = window[(p - window_start) as usize];
            r.insert(0, b);
            a.insert(0, b);
            changed = true;
        }
        if !changed {
            break;
        }
    }
    // Apara à esquerda, mantendo uma base de âncora.
    while r.len() >= 2 && a.len() >= 2 && r[0] == a[0] {
        r.remove(0);
        a.remove(0);
        p += 1;
    }
    Ok(Normalized {
        pos: p,
        reference: String::from_utf8(r).expect("ASCII"),
        alt: String::from_utf8(a).expect("ASCII"),
    })
}

/// Sequência em memória (testes e entradas pequenas).
pub struct MemorySequence(pub HashMap<String, Vec<u8>>);

impl SequenceSource for MemorySequence {
    fn fetch(&mut self, chrom: &str, start: u64, end: u64) -> Result<Option<Vec<u8>>> {
        let Some(s) = self.0.get(&canonical_chrom(chrom)) else { return Ok(None) };
        if start == 0 || start > end || start as usize > s.len() {
            return Ok(Some(Vec::new()));
        }
        Ok(Some(s[(start - 1) as usize..(end as usize).min(s.len())].to_ascii_uppercase()))
    }

    fn length(&self, chrom: &str) -> Option<u64> {
        self.0.get(&canonical_chrom(chrom)).map(|s| s.len() as u64)
    }
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use super::*;

    const FA: &str = ">chr1 descrição\nACGTACGTAC\nGTTTTTTTGA\nCC\n>chr2\nAAAA\nCCCC\n";

    #[test]
    fn indice_igual_ao_samtools_faidx() {
        let idx = FastaIndex::build(FA.as_bytes()).unwrap();
        // samtools faidx: nome, comprimento, offset, bases por linha, bytes por linha
        // ">chr1 descrição\n" ocupa 18 bytes (ç e ã têm 2 bytes em UTF-8).
        assert_eq!(idx.to_fai(), "chr1\t22\t18\t10\t11\nchr2\t8\t49\t4\t5\n");
        assert_eq!(FastaIndex::parse(&idx.to_fai()).unwrap().entries, idx.entries);
    }

    #[test]
    fn busca_por_posicao_atravessando_linhas() {
        let idx = FastaIndex::build(FA.as_bytes()).unwrap();
        let mut fa = IndexedFasta::new(Cursor::new(FA.as_bytes().to_vec()), idx);
        assert_eq!(fa.fetch("1", 9, 13).unwrap().unwrap(), b"ACGTT");
        assert_eq!(fa.fetch("chr2", 4, 5).unwrap().unwrap(), b"AC");
        assert_eq!(fa.base("chr1", 22).unwrap(), Some(b'C'));
        assert_eq!(fa.fetch("chr9", 1, 2).unwrap(), None);
        assert_eq!(fa.length("1"), Some(22));
    }

    #[test]
    fn linhas_irregulares_nao_indexam() {
        assert!(FastaIndex::build(">a\nACG\nACGT\n".as_bytes()).is_err());
        assert!(FastaIndex::build("ACGT\n".as_bytes()).is_err());
    }

    fn seq() -> MemorySequence {
        //            1234567890123
        MemorySequence(HashMap::from([("1".to_string(), b"GATTTTTTACGCA".to_vec())]))
    }

    #[test]
    fn alinha_delecao_em_repeticao_a_esquerda() {
        // Deleção de um T representada no fim da repetição TTTTTT (pos 7: TT > T)
        let n = left_align(&mut seq(), "1", 7, "TT", "T").unwrap();
        assert_eq!(n, Normalized { pos: 2, reference: "AT".into(), alt: "A".into() });
        // Mesma deleção escrita de outra forma converge para a mesma representação.
        let m = left_align(&mut seq(), "1", 4, "TTT", "TT").unwrap();
        assert_eq!(m, n);
    }

    #[test]
    fn alinha_insercao_e_apara() {
        // Inserção de T no fim da repetição: pos 8 T > TT  → G A[T…]
        let n = left_align(&mut seq(), "1", 8, "T", "TT").unwrap();
        assert_eq!(n, Normalized { pos: 2, reference: "A".into(), alt: "AT".into() });
        // Bases redundantes nas duas pontas são aparadas.
        let m = left_align(&mut seq(), "1", 9, "ACG", "AG").unwrap();
        assert_eq!(m, Normalized { pos: 9, reference: "AC".into(), alt: "A".into() });
    }

    #[test]
    fn snv_e_simbolicos_ficam_como_estao() {
        assert_eq!(left_align(&mut seq(), "1", 3, "T", "C").unwrap().pos, 3);
        assert_eq!(left_align(&mut seq(), "1", 3, "T", "<DEL>").unwrap().alt, "<DEL>");
    }
}

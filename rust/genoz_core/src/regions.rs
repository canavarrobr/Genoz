//! Conjuntos de regiões genômicas (BED). Ver BEDv1.pdf.
//!
//! BED usa coordenadas 0-based, semiabertas: `chr1 0 100` cobre as posições
//! VCF 1..=100. Internamente guardamos exatamente assim e convertemos na consulta.

use std::collections::HashMap;
use std::io::{BufRead, Read};

use serde::Serialize;

use crate::chrom::canonical_chrom;
use crate::io::open_reader;
use crate::reader::{Issue, IssueCode};
use crate::Result;

#[derive(Debug, Clone, Default)]
pub struct RegionSet {
    /// Intervalos [início, fim) 0-based, ordenados e sem sobreposição.
    by_chrom: HashMap<String, Vec<(u64, u64)>>,
}

#[derive(Debug, Clone, Serialize)]
pub struct RegionSetSummary {
    pub chromosomes: usize,
    pub intervals: usize,
    /// Total de bases cobertas.
    pub bases: u64,
}

impl RegionSet {
    /// Adiciona um intervalo 0-based semiaberto. Chame [`RegionSet::finish`] depois.
    pub fn add(&mut self, chrom: &str, start: u64, end: u64) {
        if end > start {
            self.by_chrom.entry(canonical_chrom(chrom)).or_default().push((start, end));
        }
    }

    /// Ordena e funde intervalos sobrepostos ou adjacentes.
    pub fn finish(&mut self) {
        for v in self.by_chrom.values_mut() {
            v.sort_unstable();
            let mut merged: Vec<(u64, u64)> = Vec::with_capacity(v.len());
            for &(s, e) in v.iter() {
                match merged.last_mut() {
                    Some(last) if s <= last.1 => last.1 = last.1.max(e),
                    _ => merged.push((s, e)),
                }
            }
            *v = merged;
        }
    }

    /// A posição VCF (1-based) está coberta?
    pub fn contains(&self, canonical: &str, pos: u64) -> bool {
        let Some(v) = self.by_chrom.get(canonical) else { return false };
        let p0 = pos.saturating_sub(1);
        match v.binary_search_by(|&(s, _)| s.cmp(&p0)) {
            Ok(_) => true,
            Err(0) => false,
            Err(i) => p0 < v[i - 1].1,
        }
    }

    pub fn summary(&self) -> RegionSetSummary {
        RegionSetSummary {
            chromosomes: self.by_chrom.len(),
            intervals: self.by_chrom.values().map(Vec::len).sum(),
            bases: self.by_chrom.values().flatten().map(|(s, e)| e - s).sum(),
        }
    }
}

/// Lê um BED (texto ou .gz). Linhas inválidas viram problemas; as válidas são usadas.
pub fn read_bed<R: Read>(source: R) -> Result<(RegionSet, Vec<Issue>)> {
    let (_, mut reader) = open_reader(source)?;
    let mut set = RegionSet::default();
    let mut issues = Vec::new();
    let mut line = String::new();
    let mut n = 0u64;
    loop {
        line.clear();
        if reader.read_line(&mut line)? == 0 {
            break;
        }
        n += 1;
        let l = line.trim_end_matches(['\r', '\n']);
        if l.is_empty() || l.starts_with('#') || l.starts_with("track") || l.starts_with("browser") {
            continue;
        }
        let cols: Vec<&str> = l.split(['\t', ' ']).filter(|c| !c.is_empty()).collect();
        let parsed = match cols.as_slice() {
            [c, s, e, ..] => s.parse::<u64>().ok().zip(e.parse::<u64>().ok()).map(|(s, e)| (*c, s, e)),
            _ => None,
        };
        match parsed {
            Some((c, s, e)) if e >= s => set.add(c, s, e),
            Some(_) => issues.push(Issue::error(n, IssueCode::InvalidPos, "fim menor que o início".into())),
            None => issues.push(Issue::error(
                n,
                IssueCode::TooFewColumns,
                "esperado: cromossomo, início, fim (separados por TAB)".into(),
            )),
        }
    }
    set.finish();
    Ok((set, issues))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn coordinates_are_half_open() {
        let (set, issues) = read_bed("chr1\t0\t100\n1\t200\t300\n".as_bytes()).unwrap();
        assert!(issues.is_empty());
        assert!(set.contains("1", 1));
        assert!(set.contains("1", 100));
        assert!(!set.contains("1", 101));
        assert!(!set.contains("1", 200));
        assert!(set.contains("1", 201));
        assert!(set.contains("1", 300));
        assert!(!set.contains("2", 50));
    }

    #[test]
    fn merges_overlaps() {
        let (set, _) = read_bed("track name=x\n1\t10\t20\n1\t15\t30\n1\t30\t40\n2\t0\t5\n".as_bytes()).unwrap();
        let s = set.summary();
        assert_eq!((s.chromosomes, s.intervals, s.bases), (2, 2, 35));
    }

    #[test]
    fn bad_lines_are_reported() {
        let (_, issues) = read_bed("1\t10\n1\t50\t20\n1\tx\t9\n".as_bytes()).unwrap();
        assert_eq!(issues.iter().map(|i| i.line).collect::<Vec<_>>(), [1, 2, 3]);
    }
}

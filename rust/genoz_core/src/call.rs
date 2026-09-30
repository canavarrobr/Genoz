//! Chamadas normalizadas de uma amostra, em ordem, prontas para comparar.
//!
//! Para cada registro do VCF: escolhe a amostra, divide multialélicos, apara
//! bases redundantes e aplica o portão de qualidade ([`CallFilter`]).
//! Como aparar pode avançar a posição de um registro, um pequeno buffer
//! reordena as chamadas dentro do cromossomo.

use std::collections::{BTreeMap, VecDeque};
use std::io::Read;

use serde::{Deserialize, Serialize};

use crate::filter::CallFilter;
use crate::header::VcfHeader;
use crate::normalize::{split_multiallelic, trim_alleles};
use crate::reader::VcfReader;
use crate::record::{Filter, Genotype, Record, SplitOrigin, VariantKind};
use crate::{GenozError, Result};

/// Qual amostra usar de um VCF.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case", tag = "by", content = "value")]
pub enum SampleSelector {
    #[default]
    First,
    Index(usize),
    Name(String),
}

impl SampleSelector {
    /// `None` para VCF sem amostras (apenas sítios).
    pub fn resolve(&self, header: &VcfHeader) -> Result<Option<usize>> {
        if header.samples.is_empty() {
            return match self {
                SampleSelector::First => Ok(None),
                _ => Err(GenozError::InvalidParam("este VCF não tem amostras (apenas sítios)".into())),
            };
        }
        match self {
            SampleSelector::First => Ok(Some(0)),
            SampleSelector::Index(i) if *i < header.samples.len() => Ok(Some(*i)),
            SampleSelector::Name(n) => header.samples.iter().position(|s| s == n).map(Some).ok_or_else(|| {
                GenozError::InvalidParam(format!(
                    "amostra '{n}' não encontrada; disponíveis: {}",
                    header.samples.join(", ")
                ))
            }),
            SampleSelector::Index(i) => Err(GenozError::InvalidParam(format!(
                "amostra nº {} não existe; o arquivo tem {}",
                i + 1,
                header.samples.len()
            ))),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FilterState {
    Pass,
    /// `.` na coluna FILTER.
    NotApplied,
    Failed,
}

impl From<&Filter> for FilterState {
    fn from(f: &Filter) -> Self {
        match f {
            Filter::Pass => FilterState::Pass,
            Filter::Missing => FilterState::NotApplied,
            Filter::Failed(_) => FilterState::Failed,
        }
    }
}

/// Uma variante bialélica normalizada, vista por uma amostra.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Call {
    pub chrom: String,
    pub pos: u64,
    pub reference: String,
    pub alt: String,
    pub kind: VariantKind,
    /// `None` em VCF sem amostras ou sem campo GT.
    pub genotype: Option<Genotype>,
    pub qual: Option<f64>,
    pub filter: FilterState,
    pub dp: Option<u32>,
    pub gq: Option<u32>,
    pub ids: Vec<String>,
    pub line: u64,
    pub split: Option<SplitOrigin>,
    /// Passou no portão de qualidade?
    pub quality_ok: bool,
}

impl Call {
    /// Número de cópias do alelo ALT; `None` se ausente ou sem genótipo.
    pub fn dosage(&self) -> Option<u32> {
        let g = self.genotype.as_ref()?;
        if g.is_missing() {
            return None;
        }
        Some(g.alleles.iter().filter(|a| **a == Some(1)).count() as u32)
    }

    /// A amostra carrega o alelo? VCF sem genótipo: a presença do registro basta.
    pub fn is_carrier(&self) -> bool {
        match &self.genotype {
            None => true,
            Some(_) => self.dosage().is_some_and(|d| d > 0),
        }
    }

    pub fn is_missing(&self) -> bool {
        self.genotype.as_ref().is_some_and(Genotype::is_missing)
    }

    pub fn is_explicit_ref(&self) -> bool {
        self.genotype.as_ref().is_some_and(Genotype::is_hom_ref)
    }

    /// Genótipo sem fase, com alelos ordenados (para comparar `0|1` com `1/0`).
    pub fn genotype_key(&self) -> Option<Vec<u32>> {
        let g = self.genotype.as_ref()?;
        let mut v: Vec<u32> = g.alleles.iter().map(|a| a.unwrap_or(u32::MAX)).collect();
        v.sort_unstable();
        Some(v)
    }

    pub fn is_transition(&self) -> bool {
        self.kind == VariantKind::Snv
            && matches!((self.reference.as_str(), self.alt.as_str()), ("A", "G") | ("G", "A") | ("C", "T") | ("T", "C"))
    }
}

/// Item do fluxo: uma chamada ou um bloco de referência de gVCF.
#[derive(Debug, Clone, PartialEq, Serialize)]
pub enum StreamItem {
    Call(Call),
    /// Trecho confirmado como referência (gVCF, `<NON_REF>`/`<*>` com GT 0/0). 1-based, inclusivo.
    RefBlock {
        chrom: String,
        start: u64,
        end: u64,
    },
}

impl StreamItem {
    pub fn chrom(&self) -> &str {
        match self {
            StreamItem::Call(c) => &c.chrom,
            StreamItem::RefBlock { chrom, .. } => chrom,
        }
    }

    pub fn pos(&self) -> u64 {
        match self {
            StreamItem::Call(c) => c.pos,
            StreamItem::RefBlock { start, .. } => *start,
        }
    }
}

type BufKey = (u64, u8, String, String, u64);

/// Fluxo de chamadas normalizadas de uma amostra.
pub struct CallStream<'a> {
    reader: VcfReader<'a>,
    header: VcfHeader,
    sample: Option<usize>,
    filter: CallFilter,
    buffer: BTreeMap<BufKey, StreamItem>,
    buf_chrom: Option<String>,
    ready: VecDeque<StreamItem>,
    seq: u64,
    done: bool,
    /// Linhas descartadas por erro de formato.
    pub rejected_lines: u64,
    /// Registros lidos (antes da divisão).
    pub records: u64,
}

impl<'a> CallStream<'a> {
    pub fn new<R: Read + 'a>(source: R, sample: &SampleSelector, filter: CallFilter) -> Result<Self> {
        let reader = VcfReader::new(source)?;
        let header = reader.header().clone();
        let sample = sample.resolve(&header)?;
        Ok(Self {
            reader,
            header,
            sample,
            filter,
            buffer: BTreeMap::new(),
            buf_chrom: None,
            ready: VecDeque::new(),
            seq: 0,
            done: false,
            rejected_lines: 0,
            records: 0,
        })
    }

    pub fn header(&self) -> &VcfHeader {
        &self.header
    }

    pub fn sample_name(&self) -> Option<&str> {
        self.sample.map(|i| self.header.samples[i].as_str())
    }

    fn flush_below(&mut self, pos: Option<u64>) {
        while let Some(entry) = self.buffer.first_entry() {
            if pos.is_some_and(|p| entry.key().0 >= p) {
                break;
            }
            self.ready.push_back(entry.remove());
        }
    }

    fn push(&mut self, item: StreamItem) {
        let key = match &item {
            StreamItem::RefBlock { start, .. } => (*start, 0, String::new(), String::new(), self.seq),
            StreamItem::Call(c) => (c.pos, 1, c.reference.clone(), c.alt.clone(), self.seq),
        };
        self.seq += 1;
        self.buffer.insert(key, item);
    }

    fn process(&mut self, rec: Record) {
        if self.buf_chrom.as_deref() != Some(rec.chrom.as_str()) {
            self.flush_below(None);
            self.buf_chrom = Some(rec.chrom.clone());
        } else {
            // Registros futuros têm posição >= a atual e aparar só aumenta a posição,
            // então tudo abaixo da posição atual já está na ordem final.
            self.flush_below(Some(rec.pos));
        }
        for mut part in split_multiallelic(&rec, &self.header) {
            trim_alleles(&mut part);
            if let Some(item) = self.to_item(&part) {
                self.push(item);
            }
        }
    }

    fn to_item(&self, rec: &Record) -> Option<StreamItem> {
        let alt = rec.alts.first()?;
        let genotype = self.sample.and_then(|i| rec.samples.get(i)).and_then(|s| s.gt.clone());
        if alt == "<NON_REF>" || alt == "<*>" {
            // Só é bloco de referência quando o registro original era `REF <NON_REF>`
            // com 0/0. Em `G A,<NON_REF>` a amostra tem uma variante na posição.
            let is_ref = rec.split.is_none() && genotype.as_ref().is_some_and(Genotype::is_hom_ref);
            if !is_ref {
                return None;
            }
            let end = match rec.info_value("END") {
                Some(Some(e)) => e.parse().ok()?,
                _ => rec.pos + rec.reference.len() as u64 - 1,
            };
            return Some(StreamItem::RefBlock { chrom: rec.chrom.clone(), start: rec.pos, end });
        }
        if alt == "*" || alt == "." {
            return None;
        }
        let format_value = |key: &str| -> Option<u32> {
            let i = self.sample?;
            let fi = rec.format.iter().position(|k| k == key)?;
            rec.samples.get(i)?.values.get(fi)?.parse().ok()
        };
        let dp = format_value("DP").or_else(|| match rec.info_value("DP") {
            Some(Some(v)) if self.sample.is_none() => v.parse().ok(),
            _ => None,
        });
        Some(StreamItem::Call(Call {
            chrom: rec.chrom.clone(),
            pos: rec.pos,
            reference: rec.reference.clone(),
            alt: alt.clone(),
            kind: VariantKind::classify(&rec.reference, alt),
            genotype,
            qual: rec.qual,
            filter: FilterState::from(&rec.filter),
            dp,
            gq: format_value("GQ"),
            ids: rec.ids.clone(),
            line: rec.line,
            split: rec.split,
            quality_ok: self.filter.accepts(rec, self.sample),
        }))
    }

    /// Próximo item em ordem de posição dentro do cromossomo.
    pub fn next_item(&mut self) -> Result<Option<StreamItem>> {
        loop {
            if let Some(item) = self.ready.pop_front() {
                return Ok(Some(item));
            }
            if self.done {
                return Ok(None);
            }
            match self.reader.next_parsed()? {
                None => {
                    self.flush_below(None);
                    self.done = true;
                }
                Some(p) => match p.record {
                    None => self.rejected_lines += 1,
                    Some(rec) => {
                        self.records += 1;
                        self.process(rec);
                    }
                },
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const VCF: &str = "##fileformat=VCFv4.3\n\
##INFO=<ID=END,Number=1,Type=Integer,Description=\"\">\n\
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS2\n\
1\t100\t.\tCAT\tCGT\t50\tPASS\t.\tGT:DP:GQ\t0/1:10:30\t0/0:8:20\n\
1\t101\t.\tA\tC\t50\tPASS\t.\tGT:DP:GQ\t1/1:12:40\t./.:.:.\n\
1\t200\t.\tG\t<NON_REF>\t.\t.\tEND=300\tGT\t0/0\t0/0\n\
1\t400\t.\tA\tG,*\t50\tq10\t.\tGT\t1/2\t0/1\n\
2\t5\t.\tT\tA\t.\t.\t.\tGT\t0|1\t1|0\n";

    fn items(sample: SampleSelector) -> Vec<StreamItem> {
        let mut s = CallStream::new(VCF.as_bytes(), &sample, CallFilter::default()).unwrap();
        let mut out = Vec::new();
        while let Some(i) = s.next_item().unwrap() {
            out.push(i);
        }
        out
    }

    #[test]
    fn trimmed_mnv_is_reordered_and_blocks_kept() {
        let v = items(SampleSelector::First);
        let desc: Vec<String> = v
            .iter()
            .map(|i| match i {
                StreamItem::Call(c) => format!("{}:{}:{}>{}", c.chrom, c.pos, c.reference, c.alt),
                StreamItem::RefBlock { chrom, start, end } => format!("{chrom}:{start}-{end}"),
            })
            .collect();
        // CAT>CGT em 100 vira A>G em 101 e fica antes de A>C (mesma posição, ordem por ALT).
        assert_eq!(desc, ["1:101:A>C", "1:101:A>G", "1:200-300", "1:400:A>G", "2:5:T>A"]);
    }

    #[test]
    fn genotype_semantics() {
        let v = items(SampleSelector::Name("S2".into()));
        let calls: Vec<&Call> = v
            .iter()
            .filter_map(|i| match i {
                StreamItem::Call(c) => Some(c),
                _ => None,
            })
            .collect();
        assert!(calls[0].is_missing()); // 101 A>C: ./.
        assert!(calls[1].is_explicit_ref()); // 101 A>G (vindo de 100): 0/0
        assert_eq!(calls[2].dosage(), Some(1)); // 400 A>G: S2 é 0/1 e o ALT 1 é G
        assert_eq!(calls[3].genotype_key(), Some(vec![0, 1]));
        assert_eq!(calls[2].filter, FilterState::Failed);
    }

    #[test]
    fn unknown_sample_lists_available() {
        let err =
            CallStream::new(VCF.as_bytes(), &SampleSelector::Name("X".into()), CallFilter::default()).err().unwrap();
        assert!(err.to_string().contains("S1, S2"));
    }
}

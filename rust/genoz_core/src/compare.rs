//! Comparação A × B.
//!
//! Chave: `CHROM:POS:REF:ALT` após harmonizar cromossomos, dividir
//! multialélicos e aparar alelos. O genótipo é comparado separadamente.
//!
//! Princípio científico: **ausência de registro não é genótipo de referência**.
//! Cada lado recebe um [`SideState`] que diz *por que* achamos o que achamos
//! (0/0 explícito, bloco gVCF, BED chamável ou simplesmente ausente).
//!
//! Dois modos, com resultados idênticos:
//! - *streaming*: os dois arquivos são ordenados de forma compatível; memória constante;
//! - *em memória*: fallback quando a ordem dos cromossomos difere ou há desordem.

use std::collections::{BTreeMap, HashMap, HashSet, VecDeque};
use std::io::{BufRead, Read};

use serde::{Deserialize, Serialize};

use crate::build::{guess_build, BuildGuess, Confidence, GenomeBuild};
use crate::call::{Call, CallStream, FilterState, SampleSelector, StreamItem};
use crate::chrom::{canonical_chrom, chrom_sort_key};
use crate::fasta::SequenceSource;
use crate::filter::CallFilter;
use crate::io::open_reader;
use crate::reader::VcfReader;
use crate::record::VariantKind;
use crate::regions::RegionSet;
use crate::stats::SampleStats;
use crate::{GenozError, Result};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Category {
    Shared,
    GenotypeDifference,
    OnlyA,
    OnlyB,
    MissingUncertain,
    NotAssessed,
}

impl Category {
    pub const ALL: [Category; 6] = [
        Category::Shared,
        Category::GenotypeDifference,
        Category::OnlyA,
        Category::OnlyB,
        Category::MissingUncertain,
        Category::NotAssessed,
    ];

    pub fn label(self) -> &'static str {
        match self {
            Category::Shared => "compartilhada",
            Category::GenotypeDifference => "genótipo diferente",
            Category::OnlyA => "somente em A",
            Category::OnlyB => "somente em B",
            Category::MissingUncertain => "ausente/incerta",
            Category::NotAssessed => "não avaliada",
        }
    }

    pub fn code(self) -> &'static str {
        match self {
            Category::Shared => "shared",
            Category::GenotypeDifference => "genotype_difference",
            Category::OnlyA => "only_a",
            Category::OnlyB => "only_b",
            Category::MissingUncertain => "missing_uncertain",
            Category::NotAssessed => "not_assessed",
        }
    }

    pub fn from_code(s: &str) -> Option<Self> {
        Category::ALL.into_iter().find(|c| c.code() == s)
    }
}

/// O que se sabe de um lado numa posição.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SideState {
    /// Carrega o alelo e passou no portão de qualidade.
    Carrier,
    /// Carrega o alelo, mas foi reprovado no portão de qualidade.
    LowQuality,
    /// Genótipo 0/0 explícito.
    ExplicitRef,
    /// Genótipo ausente (`./.`), ou 0/0 de baixa qualidade.
    Missing,
    /// Sem registro, mas a posição está num bloco de referência gVCF.
    AbsentRefBlock,
    /// Sem registro, dentro do BED de regiões chamáveis.
    AbsentCallable,
    /// Sem registro e sem informação de cobertura.
    AbsentUnknown,
    /// Sem registro e fora do BED de regiões chamáveis.
    NotAssessed,
}

impl SideState {
    pub fn is_carrier(self) -> bool {
        self == SideState::Carrier
    }

    pub fn code(self) -> &'static str {
        match self {
            SideState::Carrier => "carrier",
            SideState::LowQuality => "low_quality",
            SideState::ExplicitRef => "explicit_ref",
            SideState::Missing => "missing",
            SideState::AbsentRefBlock => "absent_ref_block",
            SideState::AbsentCallable => "absent_callable",
            SideState::AbsentUnknown => "absent_unknown",
            SideState::NotAssessed => "not_assessed",
        }
    }

    pub fn from_code(s: &str) -> Option<Self> {
        [
            SideState::Carrier,
            SideState::LowQuality,
            SideState::ExplicitRef,
            SideState::Missing,
            SideState::AbsentRefBlock,
            SideState::AbsentCallable,
            SideState::AbsentUnknown,
            SideState::NotAssessed,
        ]
        .into_iter()
        .find(|c| c.code() == s)
    }

    pub fn label(self) -> &'static str {
        match self {
            SideState::Carrier => "carrega o alelo",
            SideState::LowQuality => "carrega, mas baixa qualidade",
            SideState::ExplicitRef => "0/0 explícito",
            SideState::Missing => "genótipo ausente",
            SideState::AbsentRefBlock => "referência (bloco gVCF)",
            SideState::AbsentCallable => "sem registro (região chamável)",
            SideState::AbsentUnknown => "sem registro",
            SideState::NotAssessed => "fora da região avaliada",
        }
    }
}

/// Visão de um lado numa linha de resultado.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SideView {
    pub state: SideState,
    pub gt: Option<String>,
    pub qual: Option<f64>,
    pub dp: Option<u32>,
    pub gq: Option<u32>,
    pub filter: Option<FilterState>,
}

impl SideView {
    fn absent(state: SideState) -> Self {
        Self { state, gt: None, qual: None, dp: None, gq: None, filter: None }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ComparisonRow {
    pub chrom: String,
    pub pos: u64,
    pub reference: String,
    pub alt: String,
    pub kind: VariantKind,
    pub category: Category,
    pub ids: Vec<String>,
    pub a: SideView,
    pub b: SideView,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Truth {
    A,
    B,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct CompareOptions {
    pub call_filter: CallFilter,
    /// Amostra tratada como "verdade" para precisão/sensibilidade/F1.
    pub truth: Option<Truth>,
    /// Permite comparar mesmo com builds diferentes (não recomendado).
    pub allow_build_mismatch: bool,
    /// Força o modo em memória (testes).
    pub force_in_memory: bool,
    /// Indels alinhados à esquerda com um FASTA local antes de comparar.
    /// Só aparece no JSON quando ligado (análises antigas mantêm o mesmo ID).
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub normalize_with_reference: bool,
}

/// Uma das entradas da comparação. `open` é chamado mais de uma vez
/// (varredura de ordem + leitura), por isso é uma fábrica de leitores.
pub struct CompareInput<'a> {
    pub label: String,
    pub open: Box<dyn FnMut() -> Result<Box<dyn Read + 'a>> + 'a>,
    pub sample: SampleSelector,
    pub callable: Option<RegionSet>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CompareMode {
    Streaming,
    InMemory,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct ClassMetrics {
    pub true_positives: u64,
    pub false_positives: u64,
    pub false_negatives: u64,
    pub precision: Option<f64>,
    pub recall: Option<f64>,
    pub f1: Option<f64>,
}

impl ClassMetrics {
    fn finish(&mut self) {
        let r = |a: u64, b: u64| (a + b > 0).then(|| a as f64 / (a + b) as f64);
        self.precision = r(self.true_positives, self.false_positives);
        self.recall = r(self.true_positives, self.false_negatives);
        self.f1 = match (self.precision, self.recall) {
            (Some(p), Some(r)) if p + r > 0.0 => Some(2.0 * p * r / (p + r)),
            _ => None,
        };
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct BenchmarkMetrics {
    pub truth: Truth,
    pub all: ClassMetrics,
    pub snv: ClassMetrics,
    pub indel: ClassMetrics,
}

#[derive(Debug, Clone, Serialize)]
pub struct SideInfo {
    pub label: String,
    pub sample: Option<String>,
    pub build: BuildGuess,
    pub records: u64,
    pub rejected_lines: u64,
    pub duplicate_keys: u64,
    pub callable_regions: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct CompareSummary {
    pub core_version: &'static str,
    pub mode: CompareMode,
    pub a: SideInfo,
    pub b: SideInfo,
    pub rows: u64,
    pub counts: BTreeMap<Category, u64>,
    pub by_kind: BTreeMap<Category, BTreeMap<VariantKind, u64>>,
    pub by_chrom: Vec<ChromCategoryCounts>,
    /// Sítios carregados pelos dois lados (compartilhadas + genótipo diferente).
    pub sites_in_both: u64,
    /// Compartilhadas / (compartilhadas + genótipo diferente).
    pub genotype_concordance: Option<f64>,
    /// Sítios em ambos / sítios em qualquer lado (sem incertos e não avaliados).
    pub jaccard: Option<f64>,
    pub benchmark: Option<BenchmarkMetrics>,
    pub options: CompareOptions,
    pub warnings: Vec<String>,
    /// Só na comparação chip × sequenciamento ([`crate::chip_compare`]).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub chip: Option<crate::chip_compare::ChipCompareInfo>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ChromCategoryCounts {
    pub chrom: String,
    pub counts: BTreeMap<Category, u64>,
}

pub struct CompareOutcome {
    pub summary: CompareSummary,
    pub stats_a: SampleStats,
    pub stats_b: SampleStats,
}

// ---------------------------------------------------------------------------
// Varredura de ordem
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default)]
struct OrderInfo {
    chroms: Vec<String>,
    sorted: bool,
}

/// Lê só CHROM e POS para saber se o arquivo está ordenado e em que ordem
/// aparecem os cromossomos.
fn scan_order<R: Read>(source: R) -> Result<OrderInfo> {
    let (_, mut r) = open_reader(source)?;
    let mut info = OrderInfo { chroms: Vec::new(), sorted: true };
    let mut seen = HashSet::new();
    let mut last: Option<(String, u64)> = None;
    let mut line = Vec::new();
    loop {
        line.clear();
        if r.read_until(b'\n', &mut line)? == 0 {
            break;
        }
        if line.first() == Some(&b'#') || line.iter().all(u8::is_ascii_whitespace) {
            continue;
        }
        let mut cols = line.split(|b| *b == b'\t');
        let (Some(c), Some(p)) = (cols.next(), cols.next()) else { continue };
        let chrom = canonical_chrom(&String::from_utf8_lossy(c));
        let Some(pos) = std::str::from_utf8(p).ok().and_then(|p| p.trim().parse::<u64>().ok()) else { continue };
        match &mut last {
            Some((lc, lp)) if *lc == chrom => {
                if pos < *lp {
                    info.sorted = false;
                }
                *lp = pos;
            }
            _ => {
                if !seen.insert(chrom.clone()) {
                    info.sorted = false;
                }
                info.chroms.push(chrom.clone());
                last = Some((chrom, pos));
            }
        }
    }
    Ok(info)
}

/// Ordem conjunta dos cromossomos, se as duas ordens forem compatíveis.
fn merged_rank(a: &[String], b: &[String]) -> Option<HashMap<String, f64>> {
    let mut rank: HashMap<String, f64> = a.iter().enumerate().map(|(i, c)| (c.clone(), i as f64 * 1000.0)).collect();
    let mut last_rank = f64::NEG_INFINITY;
    let mut offset = 1.0;
    let mut pending_before_first = -1_000_000.0;
    for c in b {
        match rank.get(c) {
            Some(&r) => {
                if r < last_rank {
                    return None;
                }
                last_rank = r;
                offset = 1.0;
            }
            None => {
                let r = if last_rank == f64::NEG_INFINITY {
                    pending_before_first += 1.0;
                    pending_before_first
                } else {
                    offset += 1.0;
                    last_rank + offset
                };
                rank.insert(c.clone(), r);
                last_rank = r;
            }
        }
    }
    Some(rank)
}

// ---------------------------------------------------------------------------
// Fontes de itens
// ---------------------------------------------------------------------------

enum Source<'a> {
    Stream(Box<CallStream<'a>>),
    Memory { items: std::vec::IntoIter<StreamItem>, records: u64, rejected: u64 },
}

impl Source<'_> {
    fn next(&mut self) -> Result<Option<StreamItem>> {
        match self {
            Source::Stream(s) => s.next_item(),
            Source::Memory { items, .. } => Ok(items.next()),
        }
    }

    /// (registros lidos, linhas descartadas)
    fn counters(&self) -> (u64, u64) {
        match self {
            Source::Stream(s) => (s.records, s.rejected_lines),
            Source::Memory { records, rejected, .. } => (*records, *rejected),
        }
    }
}

struct Side<'a> {
    source: Source<'a>,
    peeked: Option<StreamItem>,
    blocks: VecDeque<(String, u64, u64)>,
    callable: Option<RegionSet>,
    last_key: Option<(String, u64, String, String)>,
    duplicates: u64,
    stats: SampleStats,
}

impl Side<'_> {
    fn peek(&mut self) -> Result<Option<&StreamItem>> {
        if self.peeked.is_none() {
            self.peeked = self.source.next()?;
        }
        Ok(self.peeked.as_ref())
    }

    fn take(&mut self) -> Option<StreamItem> {
        self.peeked.take()
    }

    /// Estado de um lado sem registro na posição.
    fn absent_state(&mut self, chrom: &str, pos: u64) -> SideState {
        if let Some(bed) = &self.callable {
            return if bed.contains(chrom, pos) { SideState::AbsentCallable } else { SideState::NotAssessed };
        }
        while self.blocks.front().is_some_and(|(c, _, e)| c != chrom || *e < pos) {
            self.blocks.pop_front();
        }
        if self.blocks.iter().any(|(c, s, e)| c == chrom && *s <= pos && pos <= *e) {
            SideState::AbsentRefBlock
        } else {
            SideState::AbsentUnknown
        }
    }
}

fn present_state(call: &Call) -> SideState {
    if call.is_missing() {
        SideState::Missing
    } else if call.is_carrier() {
        if call.quality_ok {
            SideState::Carrier
        } else {
            SideState::LowQuality
        }
    } else if call.quality_ok {
        SideState::ExplicitRef
    } else {
        SideState::Missing
    }
}

fn view(call: &Call, state: SideState) -> SideView {
    SideView {
        state,
        gt: call.genotype.as_ref().map(ToString::to_string),
        qual: call.qual,
        dp: call.dp,
        gq: call.gq,
        filter: Some(call.filter),
    }
}

fn categorize(a: SideState, b: SideState, a_call: Option<&Call>, b_call: Option<&Call>) -> Option<Category> {
    use SideState::*;
    let confident_absent = |s: SideState| matches!(s, ExplicitRef | AbsentRefBlock | AbsentCallable | AbsentUnknown);
    match (a, b) {
        (Carrier, Carrier) => {
            let (ga, gb) = (a_call?.genotype_key(), b_call?.genotype_key());
            Some(match (ga, gb) {
                (Some(x), Some(y)) if x != y => Category::GenotypeDifference,
                _ => Category::Shared,
            })
        }
        (Carrier, other) => Some(if confident_absent(other) {
            Category::OnlyA
        } else if other == NotAssessed {
            Category::NotAssessed
        } else {
            Category::MissingUncertain
        }),
        (other, Carrier) => Some(if confident_absent(other) {
            Category::OnlyB
        } else if other == NotAssessed {
            Category::NotAssessed
        } else {
            Category::MissingUncertain
        }),
        (LowQuality, _) | (_, LowQuality) => Some(Category::MissingUncertain),
        _ => None,
    }
}

type Key = (f64, u64, String, String);

/// Posição de um cromossomo na ordem conjunta dos dois arquivos.
type RankFn = Box<dyn Fn(&str) -> f64>;

fn key_of(item: &StreamItem, rank: &dyn Fn(&str) -> f64) -> (Key, bool) {
    match item {
        StreamItem::RefBlock { chrom, start, .. } => ((rank(chrom), *start, String::new(), String::new()), true),
        StreamItem::Call(c) => ((rank(&c.chrom), c.pos, c.reference.clone(), c.alt.clone()), false),
    }
}

fn cmp_key(x: &Key, y: &Key) -> std::cmp::Ordering {
    x.0.total_cmp(&y.0).then(x.1.cmp(&y.1)).then_with(|| x.2.cmp(&y.2)).then_with(|| x.3.cmp(&y.3))
}

/// Lê um lado inteiro para memória, ordenado pela ordem natural.
fn load_sorted(stream: &mut CallStream) -> Result<Vec<StreamItem>> {
    let mut v = Vec::new();
    while let Some(i) = stream.next_item()? {
        v.push(i);
    }
    sort_items(&mut v);
    Ok(v)
}

fn sort_items(v: &mut [StreamItem]) {
    v.sort_by(|x, y| {
        let kx = (chrom_sort_key(x.chrom()), x.pos(), matches!(x, StreamItem::Call(_)));
        let ky = (chrom_sort_key(y.chrom()), y.pos(), matches!(y, StreamItem::Call(_)));
        kx.cmp(&ky).then_with(|| match (x, y) {
            (StreamItem::Call(a), StreamItem::Call(b)) => (&a.reference, &a.alt).cmp(&(&b.reference, &b.alt)),
            _ => std::cmp::Ordering::Equal,
        })
    });
}

/// Executa a comparação. Cada linha é entregue a `sink` em ordem genômica.
pub fn compare(
    a: &mut CompareInput,
    b: &mut CompareInput,
    opts: &CompareOptions,
    sink: &mut dyn FnMut(&ComparisonRow) -> Result<()>,
) -> Result<CompareOutcome> {
    compare_with_reference(a, b, opts, None, sink)
}

/// Normalização completa dos dois lados com o FASTA: confere o REF e alinha os
/// indels à esquerda. Devolve (normalizados, REF diferentes do FASTA, sem o cromossomo no FASTA).
fn normalize_items(items: &mut [StreamItem], seq: &mut dyn SequenceSource) -> Result<(u64, u64, u64)> {
    let (mut moved, mut mismatched, mut missing_chrom) = (0u64, 0u64, 0u64);
    for item in items.iter_mut() {
        let StreamItem::Call(c) = item else { continue };
        let len = c.reference.len() as u64;
        if c.reference.bytes().all(|b| b.is_ascii_alphabetic()) && len > 0 {
            match seq.fetch(&c.chrom, c.pos, c.pos + len - 1)? {
                None => {
                    missing_chrom += 1;
                    continue;
                }
                Some(r) if !r.eq_ignore_ascii_case(c.reference.as_bytes()) => mismatched += 1,
                _ => {}
            }
        }
        if c.kind.is_indel() {
            let n = crate::fasta::left_align(seq, &c.chrom, c.pos, &c.reference, &c.alt)?;
            if n.pos != c.pos || n.reference != c.reference || n.alt != c.alt {
                moved += 1;
                c.pos = n.pos;
                c.reference = n.reference;
                c.alt = n.alt;
            }
        }
    }
    sort_items(items);
    Ok((moved, mismatched, missing_chrom))
}

/// Como [`compare`], com normalização completa por FASTA quando `reference` vier.
/// A normalização pode mudar posições, então usa o modo em memória (reordena).
pub fn compare_with_reference(
    a: &mut CompareInput,
    b: &mut CompareInput,
    opts: &CompareOptions,
    mut reference: Option<&mut dyn SequenceSource>,
    sink: &mut dyn FnMut(&ComparisonRow) -> Result<()>,
) -> Result<CompareOutcome> {
    let mut warnings = Vec::new();
    let mut options = opts.clone();
    options.normalize_with_reference = reference.is_some();

    let header_a = VcfReader::new((a.open)()?)?.header().clone();
    let header_b = VcfReader::new((b.open)()?)?.header().clone();
    let build_a = guess_build(&header_a.contigs, header_a.reference.as_deref());
    let build_b = guess_build(&header_b.contigs, header_b.reference.as_deref());
    let known = |g: &BuildGuess| g.build != GenomeBuild::Unknown;
    if known(&build_a) && known(&build_b) && build_a.build != build_b.build {
        let both_sure = build_a.confidence == Confidence::High && build_b.confidence == Confidence::High;
        let msg = format!(
            "A usa {} e B usa {}: as coordenadas não correspondem entre builds diferentes",
            build_a.build.label(),
            build_b.build.label()
        );
        if both_sure && !opts.allow_build_mismatch {
            return Err(GenozError::InvalidParam(format!("comparação recusada: {msg}")));
        }
        warnings.push(format!("atenção: {msg}"));
    }
    if !known(&build_a) || !known(&build_b) {
        warnings.push(
            "build de referência não identificado em pelo menos um arquivo; confira se ambos usam o mesmo".into(),
        );
    }
    let build = if known(&build_a) { build_a.build } else { build_b.build };

    let order_a = scan_order((a.open)()?)?;
    let order_b = scan_order((b.open)()?)?;
    let rank_map = if reference.is_some() || opts.force_in_memory || !order_a.sorted || !order_b.sorted {
        None
    } else {
        merged_rank(&order_a.chroms, &order_b.chroms)
    };
    let mode = if rank_map.is_some() { CompareMode::Streaming } else { CompareMode::InMemory };
    if mode == CompareMode::InMemory && !opts.force_in_memory && reference.is_none() {
        warnings
            .push("arquivos fora de ordem ou com ordens de cromossomos diferentes: comparação feita em memória".into());
    }

    let mut stream_a = CallStream::new((a.open)()?, &a.sample, opts.call_filter.clone())?;
    let mut stream_b = CallStream::new((b.open)()?, &b.sample, opts.call_filter.clone())?;
    let sample_a = stream_a.sample_name().map(str::to_string);
    let sample_b = stream_b.sample_name().map(str::to_string);

    let (source_a, source_b, rank): (Source, Source, RankFn) = match rank_map {
        Some(map) => (
            Source::Stream(Box::new(stream_a)),
            Source::Stream(Box::new(stream_b)),
            Box::new(move |c: &str| map.get(c).copied().unwrap_or(f64::MAX)),
        ),
        None => {
            let mut va = load_sorted(&mut stream_a)?;
            let mut vb = load_sorted(&mut stream_b)?;
            if let Some(seq) = reference.take() {
                let (ma, xa, ca) = normalize_items(&mut va, seq)?;
                let (mb, xb, cb) = normalize_items(&mut vb, seq)?;
                warnings
                    .push(format!("normalização com o FASTA: {} indels de A e {} de B alinhados à esquerda", ma, mb));
                if xa + xb > 0 {
                    warnings.push(format!(
                        "atenção: {} registros com REF diferente do FASTA (A: {xa}, B: {xb}); confira se o FASTA é do mesmo build",
                        xa + xb
                    ));
                }
                if ca + cb > 0 {
                    warnings
                        .push(format!("{} registros em cromossomos que o FASTA não tem (não normalizados)", ca + cb));
                }
            }
            // Classificação natural convertida em número (mesma ordem de chrom_sort_key).
            let mut all: Vec<String> = va.iter().chain(&vb).map(|i| i.chrom().to_string()).collect();
            all.sort_by_key(|c| chrom_sort_key(c));
            all.dedup();
            let map: HashMap<String, f64> = all.into_iter().enumerate().map(|(i, c)| (c, i as f64)).collect();
            (
                Source::Memory { items: va.into_iter(), records: stream_a.records, rejected: stream_a.rejected_lines },
                Source::Memory { items: vb.into_iter(), records: stream_b.records, rejected: stream_b.rejected_lines },
                Box::new(move |c: &str| map.get(c).copied().unwrap_or(f64::MAX)),
            )
        }
    };

    let mut side_a = Side {
        source: source_a,
        peeked: None,
        blocks: VecDeque::new(),
        callable: a.callable.take(),
        last_key: None,
        duplicates: 0,
        stats: SampleStats::new(a.label.clone(), build),
    };
    let mut side_b = Side {
        source: source_b,
        peeked: None,
        blocks: VecDeque::new(),
        callable: b.callable.take(),
        last_key: None,
        duplicates: 0,
        stats: SampleStats::new(b.label.clone(), build),
    };

    let mut counts: BTreeMap<Category, u64> = Category::ALL.iter().map(|c| (*c, 0)).collect();
    let mut by_kind: BTreeMap<Category, BTreeMap<VariantKind, u64>> = BTreeMap::new();
    let mut by_chrom: Vec<ChromCategoryCounts> = Vec::new();
    let mut bench = opts.truth.map(|truth| BenchmarkMetrics {
        truth,
        all: ClassMetrics::default(),
        snv: ClassMetrics::default(),
        indel: ClassMetrics::default(),
    });
    let mut rows = 0u64;

    loop {
        let ka = side_a.peek()?.map(|i| key_of(i, &*rank));
        let kb = side_b.peek()?.map(|i| key_of(i, &*rank));
        let (take_a, take_b) = match (&ka, &kb) {
            (None, None) => break,
            (Some(_), None) => (true, false),
            (None, Some(_)) => (false, true),
            (Some((x, bx)), Some((y, by))) => {
                // Blocos de referência vêm antes das chamadas na mesma posição.
                match cmp_key(x, y).then(by.cmp(bx)) {
                    std::cmp::Ordering::Less => (true, false),
                    std::cmp::Ordering::Greater => (false, true),
                    std::cmp::Ordering::Equal => (true, true),
                }
            }
        };

        let mut call_a = None;
        let mut call_b = None;
        for (take, side, slot) in [(take_a, &mut side_a, &mut call_a), (take_b, &mut side_b, &mut call_b)] {
            if !take {
                continue;
            }
            match side.take() {
                Some(StreamItem::RefBlock { chrom, start, end }) => {
                    side.stats.observe_ref_block();
                    side.blocks.push_back((chrom, start, end));
                }
                Some(StreamItem::Call(c)) => {
                    let key = (c.chrom.clone(), c.pos, c.reference.clone(), c.alt.clone());
                    if side.last_key.as_ref() == Some(&key) {
                        side.duplicates += 1;
                        continue;
                    }
                    side.last_key = Some(key);
                    side.stats.observe(&c);
                    *slot = Some(c);
                }
                None => {}
            }
        }
        let reference = match (&call_a, &call_b) {
            (Some(c), _) | (None, Some(c)) => c,
            (None, None) => continue,
        };
        let (chrom, pos) = (reference.chrom.clone(), reference.pos);
        let state_a = match &call_a {
            Some(c) => present_state(c),
            None => side_a.absent_state(&chrom, pos),
        };
        let state_b = match &call_b {
            Some(c) => present_state(c),
            None => side_b.absent_state(&chrom, pos),
        };
        let Some(category) = categorize(state_a, state_b, call_a.as_ref(), call_b.as_ref()) else { continue };

        let mut ids: Vec<String> = Vec::new();
        for c in call_a.iter().chain(call_b.iter()) {
            for id in &c.ids {
                if !ids.contains(id) {
                    ids.push(id.clone());
                }
            }
        }
        let row = ComparisonRow {
            chrom: chrom.clone(),
            pos,
            reference: reference.reference.clone(),
            alt: reference.alt.clone(),
            kind: reference.kind,
            category,
            ids,
            a: call_a.as_ref().map_or_else(|| SideView::absent(state_a), |c| view(c, state_a)),
            b: call_b.as_ref().map_or_else(|| SideView::absent(state_b), |c| view(c, state_b)),
        };

        rows += 1;
        *counts.entry(category).or_default() += 1;
        *by_kind.entry(category).or_default().entry(row.kind).or_default() += 1;
        match by_chrom.last_mut() {
            Some(last) if last.chrom == chrom => *last.counts.entry(category).or_default() += 1,
            _ => by_chrom.push(ChromCategoryCounts { chrom: chrom.clone(), counts: BTreeMap::from([(category, 1)]) }),
        }
        if let Some(bm) = &mut bench {
            let (tp, fp, fn_) = match (category, bm.truth) {
                (Category::Shared | Category::GenotypeDifference, _) => (1, 0, 0),
                (Category::OnlyA, Truth::A) | (Category::OnlyB, Truth::B) => (0, 0, 1),
                (Category::OnlyA, Truth::B) | (Category::OnlyB, Truth::A) => (0, 1, 0),
                _ => (0, 0, 0),
            };
            let mut classes: Vec<&mut ClassMetrics> = vec![&mut bm.all];
            if row.kind == VariantKind::Snv {
                classes.push(&mut bm.snv);
            } else if row.kind.is_indel() {
                classes.push(&mut bm.indel);
            }
            for m in classes {
                m.true_positives += tp;
                m.false_positives += fp;
                m.false_negatives += fn_;
            }
        }
        sink(&row)?;
    }

    if let Some(bm) = &mut bench {
        bm.all.finish();
        bm.snv.finish();
        bm.indel.finish();
    }
    side_a.stats.finish();
    side_b.stats.finish();

    let (rec_a, rej_a) = side_a.source.counters();
    let (rec_b, rej_b) = side_b.source.counters();
    for (label, rej) in [(&a.label, rej_a), (&b.label, rej_b)] {
        if rej > 0 {
            warnings.push(format!("{label}: {rej} linhas inválidas foram ignoradas (veja a inspeção do arquivo)"));
        }
    }

    let n = |c: Category| counts.get(&c).copied().unwrap_or(0);
    let both = n(Category::Shared) + n(Category::GenotypeDifference);
    let union = both + n(Category::OnlyA) + n(Category::OnlyB);
    let summary = CompareSummary {
        core_version: crate::CORE_VERSION,
        mode,
        a: SideInfo {
            label: a.label.clone(),
            sample: sample_a,
            build: build_a,
            records: rec_a,
            rejected_lines: rej_a,
            duplicate_keys: side_a.duplicates,
            callable_regions: side_a.callable.is_some(),
        },
        b: SideInfo {
            label: b.label.clone(),
            sample: sample_b,
            build: build_b,
            records: rec_b,
            rejected_lines: rej_b,
            duplicate_keys: side_b.duplicates,
            callable_regions: side_b.callable.is_some(),
        },
        rows,
        by_kind,
        by_chrom,
        sites_in_both: both,
        genotype_concordance: (both > 0).then(|| n(Category::Shared) as f64 / both as f64),
        jaccard: (union > 0).then(|| both as f64 / union as f64),
        counts,
        benchmark: bench,
        options,
        warnings,
        chip: None,
    };
    Ok(CompareOutcome { summary, stats_a: side_a.stats, stats_b: side_b.stats })
}

/// Resultado de [`compare_to_store`]: linhas gravadas + índice + resumo.
pub struct StoredComparison<W> {
    pub rows_out: W,
    pub index: crate::results::RowIndex,
    pub outcome: CompareOutcome,
}

/// Compara e grava as linhas no formato paginável (`rows.bgz`).
pub fn compare_to_store<W: std::io::Write>(
    a: &mut CompareInput,
    b: &mut CompareInput,
    opts: &CompareOptions,
    rows_out: W,
) -> Result<StoredComparison<W>> {
    compare_to_store_with(a, b, opts, None, rows_out)
}

/// Como [`compare_to_store`], com normalização por FASTA opcional.
pub fn compare_to_store_with<W: std::io::Write>(
    a: &mut CompareInput,
    b: &mut CompareInput,
    opts: &CompareOptions,
    reference: Option<&mut dyn SequenceSource>,
    rows_out: W,
) -> Result<StoredComparison<W>> {
    let mut writer = crate::results::ResultWriter::new(rows_out)?;
    let outcome = compare_with_reference(a, b, opts, reference, &mut |row| writer.push(row))?;
    let (rows_out, index) = writer.finish()?;
    Ok(StoredComparison { rows_out, index, outcome })
}

/// Parâmetros de uma comparação no manifesto. Única fonte para CLI e app:
/// o ID da análise (derivado destes parâmetros) precisa ser o mesmo em
/// qualquer plataforma.
pub fn manifest_parameters(
    opts: &CompareOptions,
    sample_a: &SampleSelector,
    sample_b: &SampleSelector,
) -> serde_json::Value {
    serde_json::json!({ "options": opts, "sample_a": sample_a, "sample_b": sample_b })
}

/// JSON formatado e determinístico (mesma entrada → mesmos bytes).
pub fn to_json_bytes<T: Serialize>(value: &T) -> Vec<u8> {
    let mut v = serde_json::to_vec_pretty(value).expect("tipos serializáveis");
    v.push(b'\n');
    v
}

#[cfg(test)]
mod normalization_tests {
    use std::collections::HashMap;

    use super::*;
    use crate::fasta::MemorySequence;

    fn vcf(pos: u64, r: &str, a: &str) -> String {
        format!(
            "##fileformat=VCFv4.3\n##contig=<ID=1,length=13>\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"g\">\n\
             #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n1\t{pos}\t.\t{r}\t{a}\t50\tPASS\t.\tGT\t0/1\n"
        )
    }

    fn input(text: String) -> CompareInput<'static> {
        CompareInput {
            label: "x".into(),
            open: Box::new(move || Ok(Box::new(std::io::Cursor::new(text.clone().into_bytes())) as Box<dyn Read>)),
            sample: SampleSelector::First,
            callable: None,
        }
    }

    #[test]
    fn mesma_delecao_escrita_de_dois_jeitos_so_casa_com_fasta() {
        //                    1234567890123
        let reference = b"GATTTTTTACGCA".to_vec();
        let run = |with_fasta: bool| {
            let mut a = input(vcf(7, "TT", "T"));
            let mut b = input(vcf(4, "TTT", "TT"));
            let mut seq = MemorySequence(HashMap::from([("1".to_string(), reference.clone())]));
            let mut rows = Vec::new();
            let out = compare_with_reference(
                &mut a,
                &mut b,
                &CompareOptions::default(),
                if with_fasta { Some(&mut seq) } else { None },
                &mut |r| {
                    rows.push(r.clone());
                    Ok(())
                },
            )
            .unwrap();
            (rows, out.summary)
        };
        let (rows, s) = run(false);
        assert_eq!(rows.len(), 2, "sem FASTA: duas variantes diferentes");
        assert!(!s.options.normalize_with_reference);
        let (rows, s) = run(true);
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].category, Category::Shared);
        assert_eq!((rows[0].pos, rows[0].reference.as_str(), rows[0].alt.as_str()), (2, "AT", "A"));
        assert!(s.options.normalize_with_reference);
        assert!(serde_json::to_string(&s.options).unwrap().contains("normalize_with_reference"));
        assert!(!serde_json::to_string(&CompareOptions::default()).unwrap().contains("normalize"));
    }
}

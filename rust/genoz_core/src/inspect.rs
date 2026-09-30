//! Inspeção de um VCF: validação + resumo numa única passada em streaming.

use std::collections::{BTreeMap, HashSet};
use std::io::Read;
use std::path::Path;

use serde::Serialize;

use crate::build::{guess_build, BuildGuess};
use crate::chrom::{chrom_sort_key, ChromStyle, ChromStyleDetector};
use crate::digest::{sha256_reader, FileDigest};
use crate::io::Compression;
use crate::normalize::split_multiallelic;
use crate::reader::{Issue, IssueCode, Severity, VcfReader};
use crate::record::{Filter, VariantKind};
use crate::Result;

#[derive(Debug, Clone)]
pub struct InspectOptions {
    /// Máximo de problemas guardados com detalhe (as contagens são sempre completas).
    pub max_issues: usize,
}

impl Default for InspectOptions {
    fn default() -> Self {
        Self { max_issues: 200 }
    }
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct SampleSummary {
    pub name: String,
    pub hom_ref: u64,
    pub het: u64,
    pub hom_alt: u64,
    pub missing: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct ChromCount {
    pub chrom: String,
    /// Nome como aparece no arquivo.
    pub raw: String,
    pub records: u64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Verdict {
    /// Nenhum problema.
    Valid,
    /// Utilizável; há avisos.
    ValidWithWarnings,
    /// Há linhas descartadas, mas outras são utilizáveis.
    PartiallyValid,
    /// Nada utilizável ou leitura interrompida.
    Invalid,
}

#[derive(Debug, Clone, Serialize)]
pub struct InspectReport {
    pub core_version: &'static str,
    pub digest: Option<FileDigest>,
    pub compression: Compression,
    pub file_format: Option<String>,
    pub build: BuildGuess,
    pub chrom_style: ChromStyle,
    pub contigs_in_header: usize,
    pub info_fields: usize,
    pub format_fields: usize,
    pub samples: Vec<SampleSummary>,

    /// Linhas de dados lidas (válidas ou não).
    pub records_read: u64,
    pub records_ok: u64,
    pub records_rejected: u64,
    pub multiallelic: u64,
    /// Registros bialélicos após dividir os multialélicos.
    pub biallelic_after_split: u64,
    /// Contagem por tipo, após a divisão de multialélicos.
    pub by_kind: BTreeMap<VariantKind, u64>,
    pub by_chrom: Vec<ChromCount>,
    pub filter_pass: u64,
    pub filter_failed: u64,
    pub filter_missing: u64,
    pub sorted: bool,

    pub errors: u64,
    pub warnings: u64,
    pub issue_counts: BTreeMap<IssueCode, u64>,
    pub issues: Vec<Issue>,
    pub issues_truncated: bool,
    /// Erro que interrompeu a leitura no meio (ex.: gzip truncado).
    pub fatal: Option<String>,
    pub verdict: Verdict,
}

struct Collector {
    max: usize,
    issues: Vec<Issue>,
    counts: BTreeMap<IssueCode, u64>,
    errors: u64,
    warnings: u64,
    truncated: bool,
}

impl Collector {
    fn push(&mut self, issue: Issue) {
        *self.counts.entry(issue.code).or_default() += 1;
        match issue.severity {
            Severity::Error => self.errors += 1,
            Severity::Warning => self.warnings += 1,
        }
        if self.issues.len() < self.max {
            self.issues.push(issue);
        } else {
            self.truncated = true;
        }
    }
}

/// Inspeciona um VCF a partir de qualquer fonte de bytes (sem calcular hash).
pub fn inspect<R: Read>(source: R, opts: &InspectOptions) -> Result<InspectReport> {
    let mut reader = VcfReader::new(source)?;
    let header = reader.header().clone();
    let mut col = Collector {
        max: opts.max_issues,
        issues: Vec::new(),
        counts: BTreeMap::new(),
        errors: 0,
        warnings: 0,
        truncated: false,
    };
    for issue in reader.header_issues().to_vec() {
        col.push(issue);
    }

    let mut samples: Vec<SampleSummary> =
        header.samples.iter().map(|n| SampleSummary { name: n.clone(), ..Default::default() }).collect();
    let mut style = ChromStyleDetector::default();
    let mut by_chrom: BTreeMap<String, ChromCount> = BTreeMap::new();
    let mut by_kind: BTreeMap<VariantKind, u64> = BTreeMap::new();
    let (mut read, mut ok, mut rejected, mut multi, mut split_total) = (0u64, 0u64, 0u64, 0u64, 0u64);
    let (mut pass, mut failed, mut missing_filter) = (0u64, 0u64, 0u64);
    let mut sorted = true;
    let mut current: Option<(String, u64)> = None;
    let mut seen_chroms: HashSet<String> = HashSet::new();
    let mut warned_order: HashSet<String> = HashSet::new();
    let mut warned_contig: HashSet<String> = HashSet::new();
    let mut fatal = None;
    let mut fields = crate::fields::FieldValidator::default();

    loop {
        let parsed = match reader.next_parsed() {
            Ok(Some(p)) => p,
            Ok(None) => break,
            Err(e) => {
                fatal = Some(e.user_message());
                break;
            }
        };
        read += 1;
        for issue in parsed.issues {
            col.push(issue);
        }
        let Some(rec) = parsed.record else {
            rejected += 1;
            continue;
        };
        ok += 1;
        for issue in fields.check(&rec, &header) {
            col.push(issue);
        }

        style.observe(&rec.raw_chrom);
        if !header.contigs.is_empty() && !header.has_contig(&rec.chrom) && warned_contig.insert(rec.chrom.clone()) {
            col.push(Issue::warning(
                rec.line,
                IssueCode::ContigNotInHeader,
                format!("cromossomo '{}' não está declarado no cabeçalho", rec.raw_chrom),
            ));
        }
        match &mut current {
            Some((chrom, last)) if *chrom == rec.chrom => {
                if rec.pos < *last && warned_order.insert(rec.chrom.clone()) {
                    sorted = false;
                    col.push(Issue::warning(
                        rec.line,
                        IssueCode::UnsortedPositions,
                        format!("posições fora de ordem em '{}'; o arquivo não poderá ser indexado", rec.raw_chrom),
                    ));
                }
                *last = rec.pos;
            }
            _ => {
                if !seen_chroms.insert(rec.chrom.clone()) && warned_order.insert(rec.chrom.clone()) {
                    sorted = false;
                    col.push(Issue::warning(
                        rec.line,
                        IssueCode::ChromNotContiguous,
                        format!("o cromossomo '{}' aparece em blocos separados", rec.raw_chrom),
                    ));
                }
                current = Some((rec.chrom.clone(), rec.pos));
            }
        }

        by_chrom
            .entry(rec.chrom.clone())
            .or_insert_with(|| ChromCount { chrom: rec.chrom.clone(), raw: rec.raw_chrom.clone(), records: 0 })
            .records += 1;
        match &rec.filter {
            Filter::Pass => pass += 1,
            Filter::Missing => missing_filter += 1,
            Filter::Failed(_) => failed += 1,
        }
        for (summary, data) in samples.iter_mut().zip(&rec.samples) {
            match &data.gt {
                None => summary.missing += 1,
                Some(g) if g.is_missing() => summary.missing += 1,
                Some(g) if g.is_hom_ref() => summary.hom_ref += 1,
                Some(g) if g.is_het() => summary.het += 1,
                Some(_) => summary.hom_alt += 1,
            }
        }
        if rec.is_multiallelic() {
            multi += 1;
            for part in split_multiallelic(&rec, &header) {
                split_total += 1;
                *by_kind.entry(part.kind()).or_default() += 1;
            }
        } else {
            split_total += 1;
            *by_kind.entry(rec.kind()).or_default() += 1;
        }
    }

    let mut by_chrom: Vec<ChromCount> = by_chrom.into_values().collect();
    by_chrom.sort_by_key(|c| chrom_sort_key(&c.chrom));

    let verdict = if fatal.is_some() || ok == 0 {
        Verdict::Invalid
    } else if col.errors > 0 {
        Verdict::PartiallyValid
    } else if col.warnings > 0 {
        Verdict::ValidWithWarnings
    } else {
        Verdict::Valid
    };

    Ok(InspectReport {
        core_version: crate::CORE_VERSION,
        digest: None,
        compression: reader.compression(),
        file_format: header.file_format.clone(),
        build: guess_build(&header.contigs, header.reference.as_deref()),
        chrom_style: style.style(),
        contigs_in_header: header.contigs.len(),
        info_fields: header.info.len(),
        format_fields: header.format.len(),
        samples,
        records_read: read,
        records_ok: ok,
        records_rejected: rejected,
        multiallelic: multi,
        biallelic_after_split: split_total,
        by_kind,
        by_chrom,
        filter_pass: pass,
        filter_failed: failed,
        filter_missing: missing_filter,
        sorted,
        errors: col.errors,
        warnings: col.warnings,
        issue_counts: col.counts,
        issues: col.issues,
        issues_truncated: col.truncated,
        fatal,
        verdict,
    })
}

/// Inspeciona um arquivo em disco, incluindo o SHA-256 dos bytes brutos.
pub fn inspect_path(path: &Path, opts: &InspectOptions) -> Result<InspectReport> {
    let digest = sha256_reader(std::fs::File::open(path)?)?;
    let mut report = inspect(std::fs::File::open(path)?, opts)?;
    report.digest = Some(digest);
    Ok(report)
}

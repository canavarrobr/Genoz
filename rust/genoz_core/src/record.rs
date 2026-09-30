//! Registro VCF (uma linha de dados) e genótipos. Ver VCFv4.5.pdf, seção 1.6.

use std::fmt::Write as _;

use serde::{Deserialize, Serialize};

use crate::chrom::canonical_chrom;
use crate::header::VcfHeader;
use crate::reader::{Issue, IssueCode};

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Genotype {
    /// `None` = alelo ausente (`.`).
    pub alleles: Vec<Option<u32>>,
    pub phased: bool,
}

impl Genotype {
    pub fn parse(s: &str) -> Option<Genotype> {
        if s.is_empty() {
            return None;
        }
        let mut alleles = Vec::with_capacity(2);
        let (mut saw_phased, mut saw_unphased) = (false, false);
        // VCF 4.4+ permite prefixo de fase no primeiro alelo (ex.: "|0|1").
        let body = match s.as_bytes()[0] {
            b'|' => {
                saw_phased = true;
                &s[1..]
            }
            b'/' => {
                saw_unphased = true;
                &s[1..]
            }
            _ => s,
        };
        let mut start = 0;
        for (i, ch) in body.char_indices() {
            if ch == '/' || ch == '|' {
                alleles.push(parse_allele(&body[start..i])?);
                if ch == '|' {
                    saw_phased = true;
                } else {
                    saw_unphased = true;
                }
                start = i + 1;
            }
        }
        alleles.push(parse_allele(&body[start..])?);
        Some(Genotype { alleles, phased: saw_phased && !saw_unphased })
    }

    pub fn ploidy(&self) -> usize {
        self.alleles.len()
    }

    pub fn is_missing(&self) -> bool {
        self.alleles.iter().any(Option::is_none)
    }

    pub fn is_hom_ref(&self) -> bool {
        !self.is_missing() && self.alleles.iter().all(|a| *a == Some(0))
    }

    pub fn is_het(&self) -> bool {
        !self.is_missing() && self.alleles.windows(2).any(|w| w[0] != w[1])
    }

    pub fn is_hom_alt(&self) -> bool {
        !self.is_missing() && !self.is_het() && self.alleles.first().is_some_and(|a| *a != Some(0))
    }

    pub fn max_allele(&self) -> Option<u32> {
        self.alleles.iter().flatten().copied().max()
    }
}

impl std::fmt::Display for Genotype {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let sep = if self.phased { '|' } else { '/' };
        for (i, a) in self.alleles.iter().enumerate() {
            if i > 0 {
                f.write_char(sep)?;
            }
            match a {
                Some(n) => write!(f, "{n}")?,
                None => f.write_char('.')?,
            }
        }
        Ok(())
    }
}

fn parse_allele(s: &str) -> Option<Option<u32>> {
    match s {
        "." => Some(None),
        n if !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit()) => n.parse().ok().map(Some),
        _ => None,
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case", tag = "status", content = "filters")]
pub enum Filter {
    Pass,
    /// `.`: filtros não aplicados.
    Missing,
    Failed(Vec<String>),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum VariantKind {
    Snv,
    Mnv,
    Insertion,
    Deletion,
    /// Indel sem base âncora comum ou com troca de bases.
    Complex,
    /// Alelo simbólico (`<DEL>`, `<CNV>`...) ou breakend.
    Structural,
    /// `*` (deleção sobreposta) ou ALT ausente.
    Other,
}

impl VariantKind {
    pub fn classify(reference: &str, alt: &str) -> VariantKind {
        if alt.starts_with('<') || alt.contains('[') || alt.contains(']') {
            return VariantKind::Structural;
        }
        if alt == "*" || alt == "." || alt.is_empty() {
            return VariantKind::Other;
        }
        let (r, a) = (reference.len(), alt.len());
        if r == a {
            return if r == 1 { VariantKind::Snv } else { VariantKind::Mnv };
        }
        let (rb, ab) = (reference.as_bytes(), alt.as_bytes());
        if r == 1 && a > 1 && rb[0].eq_ignore_ascii_case(&ab[0]) {
            VariantKind::Insertion
        } else if a == 1 && r > 1 && rb[0].eq_ignore_ascii_case(&ab[0]) {
            VariantKind::Deletion
        } else {
            VariantKind::Complex
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            VariantKind::Snv => "SNV",
            VariantKind::Mnv => "MNV",
            VariantKind::Insertion => "inserção",
            VariantKind::Deletion => "deleção",
            VariantKind::Complex => "indel complexo",
            VariantKind::Structural => "estrutural/simbólico",
            VariantKind::Other => "outro",
        }
    }

    pub fn is_indel(self) -> bool {
        matches!(self, VariantKind::Insertion | VariantKind::Deletion | VariantKind::Complex)
    }
}

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct SampleData {
    pub gt: Option<Genotype>,
    /// Valores brutos, alinhados com `Record::format` (inclui GT).
    pub values: Vec<String>,
}

/// Origem de um registro produzido pela divisão de multialélicos.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub struct SplitOrigin {
    /// Índice 1-based do ALT original.
    pub alt_index: u32,
    pub n_alts: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Record {
    /// Nome canônico (ver [`crate::chrom`]).
    pub chrom: String,
    /// Nome exatamente como estava no arquivo.
    pub raw_chrom: String,
    /// Posição 1-based.
    pub pos: u64,
    pub ids: Vec<String>,
    pub reference: String,
    pub alts: Vec<String>,
    pub qual: Option<f64>,
    pub filter: Filter,
    /// Pares chave/valor na ordem original; `None` = flag.
    pub info: Vec<(String, Option<String>)>,
    pub format: Vec<String>,
    pub samples: Vec<SampleData>,
    /// Número da linha no arquivo (1-based).
    pub line: u64,
    pub split: Option<SplitOrigin>,
}

impl Record {
    pub fn is_multiallelic(&self) -> bool {
        self.alts.len() > 1
    }

    pub fn kind(&self) -> VariantKind {
        match self.alts.as_slice() {
            [] => VariantKind::Other,
            [alt] => VariantKind::classify(&self.reference, alt),
            alts => {
                let first = VariantKind::classify(&self.reference, &alts[0]);
                if alts.iter().all(|a| VariantKind::classify(&self.reference, a) == first) {
                    first
                } else {
                    VariantKind::Complex
                }
            }
        }
    }

    pub fn info_value(&self, key: &str) -> Option<Option<&str>> {
        self.info.iter().find(|(k, _)| k == key).map(|(_, v)| v.as_deref())
    }

    /// Serializa de volta para uma linha VCF (sem `\n`).
    pub fn to_vcf_line(&self) -> String {
        let mut s = String::with_capacity(128);
        let join = |v: &[String], sep: &str| if v.is_empty() { ".".to_string() } else { v.join(sep) };
        let _ = write!(
            s,
            "{}\t{}\t{}\t{}\t{}\t",
            self.raw_chrom,
            self.pos,
            join(&self.ids, ";"),
            self.reference,
            join(&self.alts, ",")
        );
        match self.qual {
            Some(q) => {
                let _ = write!(s, "{}", format_qual(q));
            }
            None => s.push('.'),
        }
        s.push('\t');
        match &self.filter {
            Filter::Pass => s.push_str("PASS"),
            Filter::Missing => s.push('.'),
            Filter::Failed(f) => s.push_str(&f.join(";")),
        }
        s.push('\t');
        if self.info.is_empty() {
            s.push('.');
        } else {
            for (i, (k, v)) in self.info.iter().enumerate() {
                if i > 0 {
                    s.push(';');
                }
                s.push_str(k);
                if let Some(v) = v {
                    s.push('=');
                    s.push_str(v);
                }
            }
        }
        if !self.format.is_empty() {
            s.push('\t');
            s.push_str(&self.format.join(":"));
            for sample in &self.samples {
                s.push('\t');
                if sample.values.is_empty() {
                    s.push('.');
                } else {
                    s.push_str(&sample.values.join(":"));
                }
            }
        }
        s
    }
}

fn format_qual(q: f64) -> String {
    if q.fract() == 0.0 && q.abs() < 1e15 {
        format!("{}", q as i64)
    } else {
        format!("{q}")
    }
}

/// Resultado da interpretação de uma linha de dados.
#[derive(Debug)]
pub struct ParsedLine {
    /// `None` quando a linha tem erro que impede o uso.
    pub record: Option<Record>,
    pub issues: Vec<Issue>,
}

fn valid_ref(r: &str) -> bool {
    !r.is_empty() && r.bytes().all(|b| matches!(b.to_ascii_uppercase(), b'A' | b'C' | b'G' | b'T' | b'N'))
}

fn valid_alt(a: &str) -> bool {
    if a == "*" {
        return true;
    }
    if a.starts_with('<') {
        return a.ends_with('>') && a.len() > 2;
    }
    if a.contains('[') || a.contains(']') || a.starts_with('.') || a.ends_with('.') {
        return true; // breakend (VCFv4.5, seção 5.4)
    }
    valid_ref(a)
}

/// Interpreta uma linha de dados. Nunca entra em pânico com entrada inválida.
pub fn parse_record(line: &str, line_no: u64, header: &VcfHeader) -> ParsedLine {
    let mut issues = Vec::new();
    let fail = |code, msg: String, mut issues: Vec<Issue>| {
        issues.push(Issue::error(line_no, code, msg));
        ParsedLine { record: None, issues }
    };

    let cols: Vec<&str> = line.split('\t').collect();
    let n_samples = header.samples.len();
    if cols.len() < 8 {
        return fail(
            IssueCode::TooFewColumns,
            format!("esperadas ao menos 8 colunas separadas por TAB, encontradas {}", cols.len()),
            issues,
        );
    }
    let expected = if n_samples > 0 { 9 + n_samples } else { 8 };
    if n_samples == 0 && cols.len() > 8 {
        issues.push(Issue::warning(
            line_no,
            IssueCode::SampleCountMismatch,
            "há colunas de amostra, mas o cabeçalho não declara amostras; elas serão ignoradas".into(),
        ));
    } else if n_samples > 0 && cols.len() != expected {
        return fail(
            IssueCode::SampleCountMismatch,
            format!("esperadas {expected} colunas ({n_samples} amostras), encontradas {}", cols.len()),
            issues,
        );
    }

    let raw_chrom = cols[0];
    if raw_chrom.is_empty() || raw_chrom.contains(char::is_whitespace) {
        return fail(IssueCode::InvalidChrom, "cromossomo vazio ou com espaços".into(), issues);
    }
    let pos = match cols[1].parse::<u64>() {
        Ok(p) => p,
        Err(_) => return fail(IssueCode::InvalidPos, format!("posição inválida: '{}'", truncate(cols[1])), issues),
    };
    if pos == 0 {
        issues.push(Issue::warning(
            line_no,
            IssueCode::InvalidPos,
            "posição 0 indica telômero; aceita, mas incomum".into(),
        ));
    }
    let reference = cols[3].to_ascii_uppercase();
    if !valid_ref(&reference) {
        return fail(
            IssueCode::InvalidRef,
            format!("REF inválido: '{}' (use apenas A, C, G, T, N)", truncate(cols[3])),
            issues,
        );
    }
    let alts: Vec<String> = if cols[4] == "." {
        Vec::new()
    } else {
        cols[4].split(',').map(|a| if a.starts_with('<') { a.to_string() } else { a.to_ascii_uppercase() }).collect()
    };
    if let Some(bad) = alts.iter().find(|a| !valid_alt(a)) {
        return fail(IssueCode::InvalidAlt, format!("ALT inválido: '{}'", truncate(bad)), issues);
    }
    if alts.contains(&reference) {
        issues.push(Issue::warning(line_no, IssueCode::AltEqualsRef, "um ALT é idêntico ao REF".into()));
    }

    let qual = match cols[5] {
        "." => None,
        q => match q.parse::<f64>() {
            Ok(v) if v.is_finite() => Some(v),
            _ => {
                issues.push(Issue::warning(
                    line_no,
                    IssueCode::InvalidQual,
                    format!("QUAL inválido: '{}'; tratado como ausente", truncate(q)),
                ));
                None
            }
        },
    };
    let filter = match cols[6] {
        "PASS" => Filter::Pass,
        "." | "" => Filter::Missing,
        f => Filter::Failed(f.split(';').map(str::to_string).collect()),
    };
    let info = if cols[7] == "." || cols[7].is_empty() {
        Vec::new()
    } else {
        cols[7]
            .split(';')
            .filter(|kv| !kv.is_empty())
            .map(|kv| match kv.split_once('=') {
                Some((k, v)) => (k.to_string(), Some(v.to_string())),
                None => (kv.to_string(), None),
            })
            .collect()
    };

    let (format, samples) = if n_samples > 0 {
        let format: Vec<String> =
            if cols[8] == "." { Vec::new() } else { cols[8].split(':').map(str::to_string).collect() };
        let gt_pos = format.iter().position(|k| k == "GT");
        if gt_pos.is_some_and(|p| p != 0) {
            issues.push(Issue::warning(
                line_no,
                IssueCode::GtNotFirst,
                "GT deveria ser o primeiro campo de FORMAT".into(),
            ));
        }
        let mut samples = Vec::with_capacity(n_samples);
        for (si, col) in cols[9..].iter().enumerate() {
            let values: Vec<String> = if *col == "." && format.len() != 1 {
                Vec::new()
            } else {
                col.split(':').map(str::to_string).collect()
            };
            if values.len() > format.len() {
                return fail(
                    IssueCode::InvalidGenotype,
                    format!("amostra {} tem mais valores que as chaves de FORMAT", header.samples[si]),
                    issues,
                );
            }
            let gt = match gt_pos.and_then(|p| values.get(p)) {
                None => None,
                Some(raw) => match Genotype::parse(raw) {
                    Some(g) => {
                        if g.max_allele().is_some_and(|m| m as usize > alts.len()) {
                            return fail(
                                IssueCode::GenotypeAlleleOutOfRange,
                                format!(
                                    "genótipo da amostra {} usa alelo inexistente (há {} ALT)",
                                    header.samples[si],
                                    alts.len()
                                ),
                                issues,
                            );
                        }
                        Some(g)
                    }
                    None => {
                        return fail(
                            IssueCode::InvalidGenotype,
                            format!("genótipo inválido na amostra {}", header.samples[si]),
                            issues,
                        )
                    }
                },
            };
            samples.push(SampleData { gt, values });
        }
        (format, samples)
    } else {
        (Vec::new(), Vec::new())
    };

    let ids = if cols[2] == "." { Vec::new() } else { cols[2].split(';').map(str::to_string).collect() };
    ParsedLine {
        record: Some(Record {
            chrom: canonical_chrom(raw_chrom),
            raw_chrom: raw_chrom.to_string(),
            pos,
            ids,
            reference,
            alts,
            qual,
            filter,
            info,
            format,
            samples,
            line: line_no,
            split: None,
        }),
        issues,
    }
}

fn truncate(s: &str) -> String {
    if s.chars().count() > 40 {
        let t: String = s.chars().take(40).collect();
        format!("{t}…")
    } else {
        s.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn header(samples: &[&str]) -> VcfHeader {
        VcfHeader { samples: samples.iter().map(|s| s.to_string()).collect(), ..Default::default() }
    }

    #[test]
    fn genotype_parsing() {
        let g = Genotype::parse("0|1").unwrap();
        assert!(g.phased && g.is_het());
        assert!(Genotype::parse("1/1").unwrap().is_hom_alt());
        assert!(Genotype::parse("0/0").unwrap().is_hom_ref());
        assert!(Genotype::parse("./.").unwrap().is_missing());
        assert!(Genotype::parse("1/2").unwrap().is_het());
        assert_eq!(Genotype::parse("1").unwrap().ploidy(), 1);
        assert_eq!(Genotype::parse("|0|1").unwrap().to_string(), "0|1");
        assert!(Genotype::parse("0/a").is_none());
        assert!(Genotype::parse("").is_none());
        assert!(!Genotype::parse("0/1|1").unwrap().phased);
    }

    #[test]
    fn kinds() {
        assert_eq!(VariantKind::classify("A", "G"), VariantKind::Snv);
        assert_eq!(VariantKind::classify("AC", "GT"), VariantKind::Mnv);
        assert_eq!(VariantKind::classify("A", "ATT"), VariantKind::Insertion);
        assert_eq!(VariantKind::classify("ATT", "A"), VariantKind::Deletion);
        assert_eq!(VariantKind::classify("AT", "GCC"), VariantKind::Complex);
        assert_eq!(VariantKind::classify("A", "<DEL>"), VariantKind::Structural);
        assert_eq!(VariantKind::classify("A", "A[2:321682["), VariantKind::Structural);
        assert_eq!(VariantKind::classify("A", "*"), VariantKind::Other);
    }

    #[test]
    fn round_trip_line() {
        let h = header(&["S1", "S2"]);
        let line = "chr1\t100\trs1\tA\tG,T\t50.5\tPASS\tDP=10;AF=0.5,0.1;DB\tGT:DP\t0|1:5\t1/2:.";
        let p = parse_record(line, 1, &h);
        assert!(p.issues.is_empty(), "{:?}", p.issues);
        let r = p.record.unwrap();
        assert_eq!(r.chrom, "1");
        assert_eq!(r.info_value("DB"), Some(None));
        assert_eq!(r.info_value("DP"), Some(Some("10")));
        assert!(r.is_multiallelic());
        assert_eq!(r.to_vcf_line(), line);
    }

    #[test]
    fn errors_are_reported_not_panics() {
        let h = header(&["S1"]);
        for (line, code) in [
            ("1\t100\t.\tA", IssueCode::TooFewColumns),
            ("1\tabc\t.\tA\tG\t.\t.\t.\tGT\t0/1", IssueCode::InvalidPos),
            ("1\t100\t.\tZ\tG\t.\t.\t.\tGT\t0/1", IssueCode::InvalidRef),
            ("1\t100\t.\tA\tG!\t.\t.\t.\tGT\t0/1", IssueCode::InvalidAlt),
            ("1\t100\t.\tA\tG\t.\t.\t.\tGT\t0/2", IssueCode::GenotypeAlleleOutOfRange),
            ("1\t100\t.\tA\tG\t.\t.\t.\tGT\t0/x", IssueCode::InvalidGenotype),
            ("1\t100\t.\tA\tG\t.\t.\t.\tGT", IssueCode::SampleCountMismatch),
        ] {
            let p = parse_record(line, 7, &h);
            assert!(p.record.is_none(), "{line}");
            assert_eq!(p.issues.last().unwrap().code, code, "{line}");
            assert_eq!(p.issues.last().unwrap().line, 7);
        }
    }

    #[test]
    fn missing_sample_column() {
        let h = header(&["S1"]);
        let r = parse_record("1\t5\t.\tA\tG\t.\t.\t.\tGT:DP\t.", 1, &h).record.unwrap();
        assert!(r.samples[0].gt.is_none());
    }
}

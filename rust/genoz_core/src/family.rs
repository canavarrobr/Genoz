//! Família e populações (Módulo 12, ADR-018): parentesco KING-robust, IBS0,
//! matriz N × N, interseções, runs of homozygosity e trio — numa só passada sobre
//! um VCF multiamostra com chamada conjunta.
//!
//! Por que só VCF conjunto: o parentesco precisa de quem é homozigoto de referência
//! (ADR-010: em VCF de uma pessoa só, ausência não é referência). Só autossomos e
//! SNVs bialélicos; chamada reprovada no portão de qualidade = ausente.
//!
//! Referência: Manichaikul A et al. Robust relationship inference in genome-wide
//! association studies. Bioinformatics 2010;26:2867–2873 (eq. 2, eq. 9 e Tabela 1).

use std::collections::BTreeMap;
use std::io::Read;

use serde::{Deserialize, Serialize};

use crate::error::{GenozError, Result};
use crate::filter::CallFilter;
use crate::reader::VcfReader;
use crate::record::Record;

pub const MAX_SAMPLES: usize = 32;
/// Eventos do trio guardados na lista (as contagens são sempre completas).
pub const MAX_TRIO_EVENTS: usize = 5000;
/// Abaixo disso o parentesco é instável e vira "insuficiente".
pub const MIN_SITES: u64 = 100;
/// π0 (eq. 2) usa frequências da própria amostra: com poucas pessoas elas são grosseiras,
/// mas bastam para separar pai/mãe–filho (IBS0 ≈ 0) de irmãos (π0 ≈ 1/4) dentro do 1º grau —
/// é só para isso que o π0 é usado.
pub const MIN_SAMPLES_FOR_PI0: usize = 3;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TrioRoles {
    pub child: String,
    pub father: String,
    pub mother: String,
}

/// Parâmetros do ROH (inspirados nos padrões do `plink --homozyg`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct RohParams {
    pub min_kb: u64,
    pub min_snps: u32,
    pub max_het: u32,
    pub max_missing: u32,
    pub max_gap_kb: u64,
    /// Densidade mínima: no máximo 1 SNP a cada `max_kb_per_snp` kb, em média.
    pub max_kb_per_snp: u64,
}

impl Default for RohParams {
    fn default() -> Self {
        Self { min_kb: 1000, min_snps: 100, max_het: 1, max_missing: 5, max_gap_kb: 1000, max_kb_per_snp: 50 }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct FamilyOptions {
    pub call_filter: CallFilter,
    /// Amostras escolhidas (vazio = todas, até [`MAX_SAMPLES`]).
    pub samples: Vec<String>,
    pub trio: Option<TrioRoles>,
    pub roh: RohParams,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Relation {
    /// Mesma pessoa (duplicata) ou gêmeos idênticos.
    Duplicate,
    ParentOffspring,
    FullSiblings,
    /// 1º grau sem como separar pai/mãe–filho de irmãos (poucas amostras).
    FirstDegree,
    SecondDegree,
    ThirdDegree,
    Unrelated,
    Insufficient,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct SiteCounts {
    pub records: u64,
    /// SNVs bialélicos autossômicos usados.
    pub used: u64,
    pub skipped_multiallelic: u64,
    pub skipped_not_snv: u64,
    pub skipped_not_autosomal: u64,
    pub rejected_lines: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PairStats {
    pub a: usize,
    pub b: usize,
    /// SNPs com genótipo nas duas amostras (M).
    pub sites: u64,
    pub het_a: u64,
    pub het_b: u64,
    pub het_het: u64,
    /// Homozigotos opostos (AA × aa): nenhum alelo idêntico por estado.
    pub ibs0: u64,
    /// Genótipos idênticos.
    pub identical: u64,
    pub concordance: Option<f64>,
    /// KING-robust (eq. 9).
    pub kinship: Option<f64>,
    /// π0 estimado pela eq. 2 (só com amostras suficientes).
    pub pi0: Option<f64>,
    pub relation: Relation,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Intersection {
    /// Índices das amostras que carregam o alelo alternativo.
    pub samples: Vec<usize>,
    pub count: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RohRun {
    pub chrom: String,
    pub start: u64,
    pub end: u64,
    pub snps: u32,
    pub hets: u32,
    pub missing: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SampleRoh {
    pub sample: usize,
    pub genotyped: u64,
    pub heterozygous: u64,
    pub runs: Vec<RohRun>,
    pub total_kb: u64,
    /// Comprimento em ROH / extensão autossômica coberta pelos SNPs.
    pub froh: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TrioEvent {
    pub chrom: String,
    pub pos: u64,
    pub reference: String,
    pub alt: String,
    /// `de_novo` ou `mendelian_error`.
    pub kind: String,
    pub child: String,
    pub father: String,
    pub mother: String,
    pub child_qual: Option<f64>,
    pub child_dp: Option<u32>,
    pub child_gq: Option<u32>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, PartialEq)]
pub struct TrioResult {
    pub child: usize,
    pub father: usize,
    pub mother: usize,
    /// Sítios com os três genotipados.
    pub sites: u64,
    pub consistent: u64,
    pub de_novo_candidates: u64,
    pub other_errors: u64,
    /// Filho(a) heterozigoto(a): alelo alternativo vindo do pai / da mãe (sítios informativos).
    pub paternal: u64,
    pub maternal: u64,
    pub ambiguous: u64,
    pub error_rate: Option<f64>,
    pub events: Vec<TrioEvent>,
    pub events_truncated: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FamilyResult {
    pub core_version: String,
    pub samples: Vec<String>,
    pub options: FamilyOptions,
    pub sites: SiteCounts,
    pub pairs: Vec<PairStats>,
    /// Portadores por amostra (SNVs usados).
    pub carriers: Vec<u64>,
    pub intersections: Vec<Intersection>,
    pub roh: Vec<SampleRoh>,
    /// `None` quando o VCF não está ordenado (ROH depende da ordem).
    pub roh_available: bool,
    pub trio: Option<TrioResult>,
    pub warnings: Vec<String>,
}

/// Parâmetros gravados no manifesto (o ID da análise depende deles).
pub fn manifest_parameters(opts: &FamilyOptions) -> serde_json::Value {
    serde_json::to_value(opts).expect("serializável")
}

/// Inverso de [`manifest_parameters`] (reexecução).
pub fn options_from_manifest(p: &serde_json::Value) -> Result<FamilyOptions> {
    serde_json::from_value(p.clone())
        .map_err(|e| GenozError::InvalidParam(format!("manifesto: parâmetros inválidos ({e})")))
}

/// Classe pela Tabela 1 do KING (limiares em potências de 2).
pub fn classify(kinship: f64, pi0: Option<f64>) -> Relation {
    let t = |e: f64| 2f64.powf(-e);
    if kinship > t(1.5) {
        Relation::Duplicate
    } else if kinship > t(2.5) {
        match pi0 {
            Some(p) if p < 0.1 => Relation::ParentOffspring,
            Some(p) if p < 0.365 => Relation::FullSiblings,
            _ => Relation::FirstDegree,
        }
    } else if kinship > t(3.5) {
        Relation::SecondDegree
    } else if kinship > t(4.5) {
        Relation::ThirdDegree
    } else {
        Relation::Unrelated
    }
}

/// Dosagem do alelo alternativo (0, 1, 2) de uma amostra diploide; `None` = ausente.
fn dosage(rec: &Record, i: usize, filter: &CallFilter) -> Option<u8> {
    let gt = rec.samples.get(i)?.gt.as_ref()?;
    if gt.alleles.len() != 2 || !filter.accepts(rec, Some(i)) {
        return None;
    }
    let mut d = 0u8;
    for a in &gt.alleles {
        match a {
            Some(0) => {}
            Some(1) => d += 1,
            _ => return None,
        }
    }
    Some(d)
}

fn gt_text(d: Option<u8>) -> String {
    match d {
        None => "./.".into(),
        Some(0) => "0/0".into(),
        Some(1) => "0/1".into(),
        Some(_) => "1/1".into(),
    }
}

fn is_autosome(chrom: &str) -> bool {
    chrom.parse::<u32>().is_ok_and(|n| (1..=22).contains(&n))
}

fn is_snv(rec: &Record) -> bool {
    let base = |s: &str| s.len() == 1 && matches!(s.as_bytes()[0].to_ascii_uppercase(), b'A' | b'C' | b'G' | b'T');
    base(&rec.reference) && rec.alts.len() == 1 && base(&rec.alts[0])
}

#[derive(Default, Clone)]
struct PairAcc {
    sites: u64,
    het_a: u64,
    het_b: u64,
    het_het: u64,
    ibs0: u64,
    identical: u64,
    expected_ibs0: f64,
}

#[derive(Default)]
struct RohState {
    start: u64,
    last_hom: u64,
    snps: u32,
    hets: u32,
    missing: u32,
    active: bool,
    runs: Vec<RohRun>,
    genotyped: u64,
    heterozygous: u64,
}

impl RohState {
    fn close(&mut self, chrom: &str, p: &RohParams) {
        if self.active {
            // Saturado: num VCF fora de ordem o resultado é descartado, mas não pode estourar.
            let len = self.last_hom.saturating_sub(self.start) + 1;
            if self.snps >= p.min_snps
                && len >= p.min_kb * 1000
                && len <= u64::from(self.snps) * p.max_kb_per_snp * 1000
            {
                self.runs.push(RohRun {
                    chrom: chrom.to_string(),
                    start: self.start,
                    end: self.last_hom,
                    snps: self.snps,
                    hets: self.hets,
                    missing: self.missing,
                });
            }
        }
        self.active = false;
        self.snps = 0;
        self.hets = 0;
        self.missing = 0;
    }

    fn observe(&mut self, chrom: &str, pos: u64, d: Option<u8>, p: &RohParams) {
        match d {
            None => {
                if self.active {
                    // O ausente que passa do limite fecha o trecho e não conta nele.
                    if self.missing + 1 > p.max_missing {
                        self.close(chrom, p);
                    } else {
                        self.missing += 1;
                    }
                }
            }
            Some(1) => {
                self.genotyped += 1;
                self.heterozygous += 1;
                if self.active {
                    if self.hets + 1 > p.max_het {
                        self.close(chrom, p);
                    } else {
                        self.hets += 1;
                    }
                }
            }
            Some(_) => {
                self.genotyped += 1;
                if !self.active {
                    self.active = true;
                    self.start = pos;
                }
                self.snps += 1;
                self.last_hom = pos;
            }
        }
    }
}

fn resolve_samples(header_samples: &[String], opts: &FamilyOptions) -> Result<Vec<usize>> {
    if header_samples.len() < 2 {
        return Err(GenozError::InvalidParam(
            "o VCF precisa ter ao menos 2 amostras com chamada conjunta (parentesco, ROH e trio)".into(),
        ));
    }
    let chosen: Vec<usize> = if opts.samples.is_empty() {
        (0..header_samples.len()).collect()
    } else {
        let mut v = Vec::new();
        for name in &opts.samples {
            let i = header_samples
                .iter()
                .position(|s| s == name)
                .ok_or_else(|| GenozError::InvalidParam(format!("amostra '{name}' não está no VCF")))?;
            if v.contains(&i) {
                return Err(GenozError::InvalidParam(format!("amostra '{name}' escolhida duas vezes")));
            }
            v.push(i);
        }
        v
    };
    if chosen.len() < 2 {
        return Err(GenozError::InvalidParam("escolha ao menos 2 amostras".into()));
    }
    if chosen.len() > MAX_SAMPLES {
        return Err(GenozError::InvalidParam(format!(
            "escolha no máximo {MAX_SAMPLES} amostras (o VCF tem {})",
            header_samples.len()
        )));
    }
    Ok(chosen)
}

/// Analisa um VCF multiamostra.
pub fn analyze_family<R: Read>(source: R, opts: &FamilyOptions) -> Result<FamilyResult> {
    let mut reader = VcfReader::new(source)?;
    let header_samples = reader.header().samples.clone();
    let cols = resolve_samples(&header_samples, opts)?;
    let n = cols.len();
    let names: Vec<String> = cols.iter().map(|&c| header_samples[c].clone()).collect();
    let index_of = |name: &str| -> Result<usize> {
        names
            .iter()
            .position(|s| s == name)
            .ok_or_else(|| GenozError::InvalidParam(format!("amostra do trio '{name}' não está entre as escolhidas")))
    };
    let trio_idx = match &opts.trio {
        Some(t) => {
            let (c, f, m) = (index_of(&t.child)?, index_of(&t.father)?, index_of(&t.mother)?);
            if c == f || c == m || f == m {
                return Err(GenozError::InvalidParam("filho(a), pai e mãe precisam ser amostras diferentes".into()));
            }
            Some((c, f, m))
        }
        None => None,
    };

    let mut counts = SiteCounts::default();
    let mut pairs = vec![PairAcc::default(); n * (n - 1) / 2];
    let mut carriers = vec![0u64; n];
    let mut masks: BTreeMap<u32, u64> = BTreeMap::new();
    let mut roh: Vec<RohState> = (0..n).map(|_| RohState::default()).collect();
    let mut roh_chrom = String::new();
    let mut last_pos = 0u64;
    let mut seen_chroms: Vec<String> = Vec::new();
    let mut sorted = true;
    let mut span: BTreeMap<String, (u64, u64)> = BTreeMap::new();
    let mut trio = trio_idx.map(|(c, f, m)| TrioResult { child: c, father: f, mother: m, ..Default::default() });
    let p = &opts.roh;
    let mut d = vec![None::<u8>; n];

    while let Some(parsed) = reader.next_parsed()? {
        let Some(rec) = parsed.record else {
            counts.rejected_lines += 1;
            continue;
        };
        counts.records += 1;
        if !is_autosome(&rec.chrom) {
            counts.skipped_not_autosomal += 1;
            continue;
        }
        if rec.is_multiallelic() {
            counts.skipped_multiallelic += 1;
            continue;
        }
        if !is_snv(&rec) {
            counts.skipped_not_snv += 1;
            continue;
        }
        counts.used += 1;
        for (k, &c) in cols.iter().enumerate() {
            d[k] = dosage(&rec, c, &opts.call_filter);
        }

        // Ordem: ROH depende de posições crescentes dentro do cromossomo.
        if rec.chrom != roh_chrom {
            if seen_chroms.contains(&rec.chrom) {
                sorted = false;
            }
            for st in &mut roh {
                st.close(&roh_chrom, p);
            }
            roh_chrom = rec.chrom.clone();
            seen_chroms.push(rec.chrom.clone());
        } else if rec.pos < last_pos {
            sorted = false;
        } else if rec.pos - last_pos > p.max_gap_kb * 1000 {
            for st in &mut roh {
                st.close(&roh_chrom, p);
            }
        }
        last_pos = rec.pos;
        let e = span.entry(rec.chrom.clone()).or_insert((rec.pos, rec.pos));
        e.0 = e.0.min(rec.pos);
        e.1 = e.1.max(rec.pos);
        for (k, st) in roh.iter_mut().enumerate() {
            st.observe(&rec.chrom, rec.pos, d[k], p);
        }

        // Frequência alélica na amostra escolhida (eq. 3) → esperado de IBS0 sem parentesco (eq. 2).
        let (alt, called) = d.iter().flatten().fold((0u32, 0u32), |(a, c), &x| (a + u32::from(x), c + 2));
        let expected = if called > 0 {
            let q = f64::from(alt) / f64::from(called);
            2.0 * q * q * (1.0 - q) * (1.0 - q)
        } else {
            0.0
        };

        let mut mask = 0u32;
        for k in 0..n {
            if d[k].is_some_and(|x| x > 0) {
                carriers[k] += 1;
                mask |= 1 << k;
            }
        }
        if mask != 0 {
            *masks.entry(mask).or_default() += 1;
        }

        let mut idx = 0;
        for a in 0..n {
            for b in a + 1..n {
                if let (Some(x), Some(y)) = (d[a], d[b]) {
                    let acc = &mut pairs[idx];
                    acc.sites += 1;
                    acc.het_a += u64::from(x == 1);
                    acc.het_b += u64::from(y == 1);
                    acc.het_het += u64::from(x == 1 && y == 1);
                    acc.ibs0 += u64::from((x == 0 && y == 2) || (x == 2 && y == 0));
                    acc.identical += u64::from(x == y);
                    acc.expected_ibs0 += expected;
                }
                idx += 1;
            }
        }

        if let Some(t) = trio.as_mut() {
            if let (Some(c), Some(f), Some(m)) = (d[t.child], d[t.father], d[t.mother]) {
                t.sites += 1;
                let alleles = |g: u8| -> &'static [u8] {
                    match g {
                        0 => &[0],
                        1 => &[0, 1],
                        _ => &[1],
                    }
                };
                let ok = alleles(f).iter().any(|x| alleles(m).iter().any(|y| x + y == c));
                if ok {
                    t.consistent += 1;
                    if c == 1 {
                        if f == 0 || m == 2 {
                            t.maternal += 1;
                        } else if m == 0 || f == 2 {
                            t.paternal += 1;
                        } else {
                            t.ambiguous += 1;
                        }
                    }
                } else {
                    let de_novo = c == 1 && f == 0 && m == 0;
                    if de_novo {
                        t.de_novo_candidates += 1;
                    } else {
                        t.other_errors += 1;
                    }
                    if t.events.len() < MAX_TRIO_EVENTS {
                        let ci = cols[t.child];
                        let fmt = |key: &str| -> Option<u32> {
                            let fi = rec.format.iter().position(|k| k == key)?;
                            rec.samples.get(ci)?.values.get(fi)?.parse().ok()
                        };
                        t.events.push(TrioEvent {
                            chrom: rec.chrom.clone(),
                            pos: rec.pos,
                            reference: rec.reference.clone(),
                            alt: rec.alts[0].clone(),
                            kind: if de_novo { "de_novo" } else { "mendelian_error" }.into(),
                            child: gt_text(Some(c)),
                            father: gt_text(Some(f)),
                            mother: gt_text(Some(m)),
                            child_qual: rec.qual,
                            child_dp: fmt("DP"),
                            child_gq: fmt("GQ"),
                        });
                    } else {
                        t.events_truncated = true;
                    }
                }
            }
        }
    }
    for st in &mut roh {
        st.close(&roh_chrom, p);
    }

    let mut warnings = Vec::new();
    if counts.used < 1000 {
        warnings.push(format!("só {} SNVs utilizáveis: o parentesco fica instável com menos de ~1000", counts.used));
    }
    if !sorted {
        warnings.push("o VCF não está ordenado por posição: runs of homozygosity não foram calculados".into());
    }
    if counts.skipped_not_autosomal > 0 {
        warnings.push(format!(
            "{} registros fora dos autossomos (X, Y, mitocôndria...) ficaram de fora: o sexo das amostras não é conhecido",
            counts.skipped_not_autosomal
        ));
    }
    let use_pi0 = n >= MIN_SAMPLES_FOR_PI0;
    let mut idx = 0;
    let mut out_pairs = Vec::with_capacity(pairs.len());
    for a in 0..n {
        for b in a + 1..n {
            let acc = &pairs[idx];
            idx += 1;
            let hets = acc.het_a + acc.het_b;
            let kinship = (acc.sites >= MIN_SITES && hets > 0)
                .then(|| (acc.het_het as f64 - 2.0 * acc.ibs0 as f64) / hets as f64);
            let pi0 = (use_pi0 && acc.expected_ibs0 > 0.0).then(|| acc.ibs0 as f64 / acc.expected_ibs0);
            out_pairs.push(PairStats {
                a,
                b,
                sites: acc.sites,
                het_a: acc.het_a,
                het_b: acc.het_b,
                het_het: acc.het_het,
                ibs0: acc.ibs0,
                identical: acc.identical,
                concordance: (acc.sites > 0).then(|| acc.identical as f64 / acc.sites as f64),
                kinship,
                pi0,
                relation: kinship.map_or(Relation::Insufficient, |k| classify(k, pi0)),
            });
        }
    }
    let mut intersections: Vec<Intersection> = masks
        .into_iter()
        .map(|(m, count)| Intersection { samples: (0..n).filter(|k| m & (1 << k) != 0).collect(), count })
        .collect();
    intersections.sort_by(|x, y| y.count.cmp(&x.count).then_with(|| x.samples.cmp(&y.samples)));
    intersections.truncate(20);

    let span_total: u64 = span.values().map(|(a, b)| b - a).sum();
    let roh_out = roh
        .into_iter()
        .enumerate()
        .map(|(k, st)| {
            let runs = if sorted { st.runs } else { Vec::new() };
            let total: u64 = runs.iter().map(|r| r.end.saturating_sub(r.start) + 1).sum();
            SampleRoh {
                sample: k,
                genotyped: st.genotyped,
                heterozygous: st.heterozygous,
                total_kb: total / 1000,
                froh: (sorted && span_total > 0).then(|| total as f64 / span_total as f64),
                runs,
            }
        })
        .collect();
    if let Some(t) = trio.as_mut() {
        t.error_rate = (t.sites > 0).then(|| (t.de_novo_candidates + t.other_errors) as f64 / t.sites as f64);
    }
    Ok(FamilyResult {
        core_version: crate::CORE_VERSION.into(),
        samples: names,
        options: opts.clone(),
        sites: counts,
        pairs: out_pairs,
        carriers,
        intersections,
        roh: roh_out,
        roh_available: sorted,
        trio,
        warnings,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn vcf(samples: &[&str], rows: &[(&str, u64, &[&str])]) -> String {
        let mut s = String::from("##fileformat=VCFv4.3\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"g\">\n");
        s.push_str("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT");
        for x in samples {
            s.push('\t');
            s.push_str(x);
        }
        s.push('\n');
        for (chrom, pos, gts) in rows {
            s.push_str(&format!("{chrom}\t{pos}\t.\tA\tG\t50\tPASS\t.\tGT\t{}\n", gts.join("\t")));
        }
        s
    }

    #[test]
    fn king_counts_by_hand() {
        // 4 SNPs: het/het, AA/aa (IBS0), het/AA, aa/aa.
        let rows: Vec<(&str, u64, &[&str])> = vec![
            ("1", 10, &["0/1", "0/1"]),
            ("1", 20, &["0/0", "1/1"]),
            ("1", 30, &["0/1", "0/0"]),
            ("1", 40, &["1/1", "1/1"]),
        ];
        let mut text = vcf(&["I", "J"], &rows);
        // Repete o bloco para passar do mínimo de SNPs (mesmas proporções).
        let body: String = text.lines().skip(3).map(|l| format!("{l}\n")).collect();
        for k in 1..30u64 {
            text.push_str(
                &body
                    .replace("\t10\t", &format!("\t{}\t", 10 + k * 100))
                    .replace("\t20\t", &format!("\t{}\t", 20 + k * 100))
                    .replace("\t30\t", &format!("\t{}\t", 30 + k * 100))
                    .replace("\t40\t", &format!("\t{}\t", 40 + k * 100)),
            );
        }
        let r = analyze_family(text.as_bytes(), &FamilyOptions::default()).unwrap();
        let p = &r.pairs[0];
        assert_eq!((p.sites, p.het_a, p.het_b, p.het_het, p.ibs0, p.identical), (120, 60, 30, 30, 30, 60));
        // φ = (N_Aa,Aa − 2 N_AA,aa) / (N_Aa(i) + N_Aa(j)) = (30 − 60) / 90
        assert!((p.kinship.unwrap() - (-30.0 / 90.0)).abs() < 1e-12);
        assert_eq!(p.relation, Relation::Unrelated);
        assert_eq!(p.concordance, Some(0.5));
        assert_eq!(p.pi0, None, "π0 só com ≥ 3 amostras");
    }

    #[test]
    fn classes_follow_table_1() {
        assert_eq!(classify(0.49, None), Relation::Duplicate);
        assert_eq!(classify(0.25, None), Relation::FirstDegree);
        assert_eq!(classify(0.25, Some(0.01)), Relation::ParentOffspring);
        assert_eq!(classify(0.25, Some(0.25)), Relation::FullSiblings);
        assert_eq!(classify(0.125, None), Relation::SecondDegree);
        assert_eq!(classify(0.0625, None), Relation::ThirdDegree);
        assert_eq!(classify(0.01, None), Relation::Unrelated);
        assert_eq!(classify(0.17677, None), Relation::SecondDegree); // logo abaixo de 2^-2,5
        assert_eq!(classify(0.17680, None), Relation::FirstDegree);
    }

    #[test]
    fn quality_gate_missing_and_skips() {
        let mut text = String::from(
            "##fileformat=VCFv4.3\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"g\">\n\
             ##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"q\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tI\tJ\n",
        );
        text.push_str("1\t10\t.\tA\tG\t50\tPASS\t.\tGT:GQ\t0/1:5\t0/1:60\n"); // I reprovada no GQ
        text.push_str("1\t20\t.\tA\tG,T\t50\tPASS\t.\tGT:GQ\t0/1:60\t0/1:60\n"); // multialélico
        text.push_str("1\t30\t.\tA\tGT\t50\tPASS\t.\tGT:GQ\t0/1:60\t0/1:60\n"); // indel
        text.push_str("X\t40\t.\tA\tG\t50\tPASS\t.\tGT:GQ\t0/1:60\t0/1:60\n"); // X
        text.push_str("1\t50\t.\tA\tG\t50\tPASS\t.\tGT:GQ\t./.:60\t0/1:60\n"); // ausente
        let opts =
            FamilyOptions { call_filter: CallFilter { min_gq: Some(20), ..Default::default() }, ..Default::default() };
        let r = analyze_family(text.as_bytes(), &opts).unwrap();
        assert_eq!(r.sites.used, 2);
        assert_eq!((r.sites.skipped_multiallelic, r.sites.skipped_not_snv, r.sites.skipped_not_autosomal), (1, 1, 1));
        assert_eq!(r.pairs[0].sites, 0);
        assert_eq!(r.pairs[0].relation, Relation::Insufficient);
        assert_eq!(r.carriers, vec![0, 2]);
        assert!(r.warnings.iter().any(|w| w.contains("autossomos")));
    }

    #[test]
    fn trio_classification() {
        let rows: Vec<(&str, u64, &[&str])> = vec![
            ("1", 10, &["0/1", "0/1", "0/0"]), // filho het, pai het, mãe 0/0 → paterno
            ("1", 20, &["0/1", "0/0", "1/1"]), // materno
            ("1", 30, &["0/1", "0/1", "0/1"]), // ambíguo
            ("1", 40, &["0/1", "0/0", "0/0"]), // de novo
            ("1", 50, &["1/1", "0/0", "0/1"]), // erro mendeliano
            ("1", 60, &["1/1", "0/1", "1/1"]), // consistente (homozigoto)
            ("1", 70, &["./.", "0/0", "0/0"]), // ausente: fora
        ];
        let text = vcf(&["FILHO", "PAI", "MAE"], &rows);
        let opts = FamilyOptions {
            trio: Some(TrioRoles { child: "FILHO".into(), father: "PAI".into(), mother: "MAE".into() }),
            ..Default::default()
        };
        let t = analyze_family(text.as_bytes(), &opts).unwrap().trio.unwrap();
        assert_eq!((t.sites, t.consistent, t.de_novo_candidates, t.other_errors), (6, 4, 1, 1));
        assert_eq!((t.paternal, t.maternal, t.ambiguous), (1, 1, 1));
        assert_eq!(
            t.events.iter().map(|e| (e.pos, e.kind.as_str())).collect::<Vec<_>>(),
            [(40, "de_novo"), (50, "mendelian_error")]
        );
        assert_eq!(t.events[1].child, "1/1");

        let bad = FamilyOptions {
            trio: Some(TrioRoles { child: "FILHO".into(), father: "FILHO".into(), mother: "MAE".into() }),
            ..Default::default()
        };
        assert!(analyze_family(text.as_bytes(), &bad).is_err());
    }

    #[test]
    fn roh_boundaries() {
        let p = RohParams { min_kb: 10, min_snps: 5, max_het: 1, max_missing: 1, max_gap_kb: 5, max_kb_per_snp: 5 };
        let mut st = RohState::default();
        // 6 homozigotos a cada 2 kb (10 kb), 1 het tolerado, depois 2º het fecha.
        for (k, d) in [0u8, 2, 0, 1, 0, 0, 2, 1].iter().enumerate() {
            st.observe("1", 1000 + k as u64 * 2000, Some(*d), &p);
        }
        assert_eq!(st.runs.len(), 1);
        assert_eq!((st.runs[0].start, st.runs[0].end, st.runs[0].snps, st.runs[0].hets), (1000, 13000, 6, 1));
        // Curto demais: descartado.
        let mut st = RohState::default();
        for k in 0..4u64 {
            st.observe("1", k * 2000, Some(0), &p);
        }
        st.close("1", &p);
        assert!(st.runs.is_empty());
        // Ausentes acima do limite fecham o trecho.
        let mut st = RohState::default();
        for k in 0..6u64 {
            st.observe("1", k * 3000, Some(0), &p);
        }
        st.observe("1", 30_000, None, &p);
        st.observe("1", 31_000, None, &p);
        assert_eq!(st.runs.len(), 1);
    }

    #[test]
    fn synthetic_family_recovers_planted_truth() {
        use crate::build::GenomeBuild;
        use crate::synth::{write_family_vcf, FAMILY_SAMPLES};
        let mut buf = Vec::new();
        let truth = write_family_vcf(2026, GenomeBuild::Grch38, 4000, &mut buf).unwrap();
        assert_eq!(truth.de_novo.len(), 3);
        let opts = FamilyOptions {
            trio: Some(TrioRoles { child: "FILHO".into(), father: "PAI".into(), mother: "MAE".into() }),
            ..Default::default()
        };
        let r = analyze_family(&buf[..], &opts).unwrap();
        assert_eq!(r.samples, FAMILY_SAMPLES);
        assert!(r.warnings.is_empty(), "{:?}", r.warnings);
        let rel = |x: &str, y: &str| {
            let (i, j) =
                (r.samples.iter().position(|s| s == x).unwrap(), r.samples.iter().position(|s| s == y).unwrap());
            r.pairs.iter().find(|p| (p.a, p.b) == (i.min(j), i.max(j))).unwrap().clone()
        };
        use Relation::*;
        for (x, y, want, phi) in [
            ("FILHO", "FILHO_REPETIDO", Duplicate, 0.5),
            ("PAI", "FILHO", ParentOffspring, 0.25),
            ("MAE", "FILHA", ParentOffspring, 0.25),
            ("AVO", "PAI", ParentOffspring, 0.25),
            ("FILHO", "FILHA", FullSiblings, 0.25),
            ("AVO", "FILHO", SecondDegree, 0.125),
            ("AVO", "FILHA", SecondDegree, 0.125),
            ("PAI", "MAE", Unrelated, 0.0),
            ("VIZINHO", "FILHO", Unrelated, 0.0),
            ("AVO", "MAE", Unrelated, 0.0),
        ] {
            let p = rel(x, y);
            let k = p.kinship.unwrap();
            assert_eq!(p.relation, want, "{x}×{y}: φ = {k:.4}");
            // O VIZINHO tem um trecho longo de homozigose: menos heterozigotos puxam o φ para baixo.
            let tol = if x == "VIZINHO" { 0.06 } else { 0.04 };
            assert!((k - phi).abs() < tol, "{x}×{y}: φ = {k:.4}, esperado ≈ {phi}");
        }
        // Pai/mãe–filho: quase nenhum IBS0 (só o erro plantado); irmãos têm IBS0.
        assert!(rel("PAI", "FILHO").ibs0 <= 1);
        assert!(rel("FILHO", "FILHA").ibs0 > 20);

        let t = r.trio.as_ref().unwrap();
        assert_eq!(t.de_novo_candidates, 3);
        assert_eq!(t.other_errors, 1);
        let found: Vec<(String, u64)> =
            t.events.iter().filter(|e| e.kind == "de_novo").map(|e| (format!("chr{}", e.chrom), e.pos)).collect();
        assert_eq!(found, truth.de_novo);
        assert!(t.paternal > 1000 && t.maternal > 1000);

        let vizinho = &r.roh[5];
        assert_eq!(vizinho.runs.len(), 1, "{:?}", vizinho.runs);
        let run = &vizinho.runs[0];
        assert_eq!(format!("chr{}", run.chrom), truth.roh.0);
        assert!(run.start <= truth.roh.1 + 50_000 && run.end + 50_000 >= truth.roh.2, "{run:?} × {:?}", truth.roh);
        assert!(vizinho.froh.unwrap() > 0.05);
        for (k, s) in r.roh.iter().enumerate() {
            if k != 5 {
                assert!(s.runs.is_empty(), "{}: {:?}", r.samples[k], s.runs);
            }
        }
        // Determinismo.
        assert_eq!(r, analyze_family(&buf[..], &opts).unwrap());

        // Só o trio (3 amostras): frequências grosseiras, mas pai/mãe–filho continua claro.
        let only = FamilyOptions { samples: vec!["FILHO".into(), "PAI".into(), "MAE".into()], ..opts.clone() };
        let t3 = analyze_family(&buf[..], &only).unwrap();
        let classes: Vec<Relation> = t3.pairs.iter().map(|p| p.relation).collect();
        assert_eq!(classes, [ParentOffspring, ParentOffspring, Unrelated]);
    }

    #[test]
    fn errors_and_limits() {
        let one = vcf(&["S"], &[("1", 10, &["0/1"])]);
        assert!(analyze_family(one.as_bytes(), &FamilyOptions::default()).is_err());
        let two = vcf(&["S", "T"], &[("1", 10, &["0/1", "0/1"])]);
        let unknown = FamilyOptions { samples: vec!["S".into(), "Z".into()], ..Default::default() };
        assert!(analyze_family(two.as_bytes(), &unknown).is_err());
        let r = analyze_family(two.as_bytes(), &FamilyOptions::default()).unwrap();
        assert!(r.warnings.iter().any(|w| w.contains("instável")));
    }

    #[test]
    fn unsorted_vcf_disables_roh() {
        let rows: Vec<(&str, u64, &[&str])> = vec![("1", 50, &["0/0", "0/0"]), ("1", 10, &["0/0", "0/0"])];
        let r = analyze_family(vcf(&["S", "T"], &rows).as_bytes(), &FamilyOptions::default()).unwrap();
        assert!(!r.roh_available);
        assert!(r.roh.iter().all(|s| s.runs.is_empty() && s.froh.is_none()));
    }
}

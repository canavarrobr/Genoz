//! Estatísticas de controle de qualidade (QC) de uma amostra.
//!
//! Calculadas sobre as chamadas normalizadas (após divisão de multialélicos).
//! Contagens de tipo, Ti/Tv e histogramas consideram apenas variantes que a
//! amostra carrega; `missing_rate` considera todas as chamadas.

use std::collections::BTreeMap;

use serde::Serialize;

use crate::build::GenomeBuild;
use crate::call::{Call, FilterState};
use crate::chrom::chrom_sort_key;
use crate::record::VariantKind;

/// Tamanho da janela do mapa de densidade.
pub const DENSITY_WINDOW: u64 = 1_000_000;

#[derive(Debug, Clone, Serialize)]
pub struct Bin {
    pub lo: f64,
    /// `None` = sem limite superior.
    pub hi: Option<f64>,
    pub count: u64,
}

fn bins(edges: &[f64]) -> Vec<Bin> {
    let mut v: Vec<Bin> = edges.windows(2).map(|w| Bin { lo: w[0], hi: Some(w[1]), count: 0 }).collect();
    v.push(Bin { lo: *edges.last().expect("limites"), hi: None, count: 0 });
    v
}

fn add(bins: &mut [Bin], value: f64) {
    if let Some(b) = bins.iter_mut().find(|b| value >= b.lo && b.hi.is_none_or(|hi| value < hi)) {
        b.count += 1;
    }
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct ChromStats {
    pub chrom: String,
    pub carriers: u64,
    pub het: u64,
    pub hom_alt: u64,
    /// Contagem por janela de [`DENSITY_WINDOW`] bases.
    pub density: Vec<u32>,
}

#[derive(Debug, Clone, Serialize)]
pub struct XHeterozygosity {
    pub het: u64,
    pub hom_alt: u64,
    /// het / (het + hom-alt) no X fora das regiões pseudoautossômicas.
    pub het_fraction: Option<f64>,
    /// `false` quando o build é desconhecido e as PAR não puderam ser excluídas.
    pub par_excluded: bool,
}

#[derive(Debug, Clone, Serialize)]
pub struct SampleStats {
    pub label: String,
    /// Chamadas vistas (inclui 0/0 explícito e ausentes).
    pub calls_total: u64,
    pub carriers: u64,
    pub hom_ref: u64,
    pub het: u64,
    /// Inclui hemizigotos (ex.: GT `1` no X masculino).
    pub hom_alt: u64,
    pub missing: u64,
    /// Chamadas reprovadas no portão de qualidade.
    pub low_quality: u64,
    /// Blocos de referência (gVCF).
    pub ref_blocks: u64,
    pub by_kind: BTreeMap<VariantKind, u64>,
    pub transitions: u64,
    pub transversions: u64,
    pub ti_tv: Option<f64>,
    pub het_hom_ratio: Option<f64>,
    pub missing_rate: Option<f64>,
    pub filter: BTreeMap<FilterState, u64>,
    pub qual_hist: Vec<Bin>,
    pub dp_hist: Vec<Bin>,
    pub gq_hist: Vec<Bin>,
    /// Comprimento de indels (ALT − REF); limitado a ±50.
    pub indel_lengths: BTreeMap<i64, u64>,
    pub by_chrom: Vec<ChromStats>,
    pub x_heterozygosity: XHeterozygosity,
    #[serde(skip)]
    chroms: BTreeMap<String, ChromStats>,
    #[serde(skip)]
    build: GenomeBuild,
}

/// Regiões pseudoautossômicas do X (1-based, inclusivas).
fn in_x_par(build: GenomeBuild, pos: u64) -> Option<bool> {
    let pars: [(u64, u64); 2] = match build {
        GenomeBuild::Grch37 => [(60_001, 2_699_520), (154_931_044, 155_260_560)],
        GenomeBuild::Grch38 => [(10_001, 2_781_479), (155_701_383, 156_030_895)],
        GenomeBuild::Unknown => return None,
    };
    Some(pars.iter().any(|(s, e)| (*s..=*e).contains(&pos)))
}

impl SampleStats {
    pub fn new(label: impl Into<String>, build: GenomeBuild) -> Self {
        Self {
            label: label.into(),
            calls_total: 0,
            carriers: 0,
            hom_ref: 0,
            het: 0,
            hom_alt: 0,
            missing: 0,
            low_quality: 0,
            ref_blocks: 0,
            by_kind: BTreeMap::new(),
            transitions: 0,
            transversions: 0,
            ti_tv: None,
            het_hom_ratio: None,
            missing_rate: None,
            filter: BTreeMap::new(),
            qual_hist: bins(&[0.0, 10.0, 20.0, 30.0, 50.0, 100.0, 200.0, 500.0, 1000.0]),
            dp_hist: bins(&[0.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0, 60.0, 100.0]),
            gq_hist: bins(&[0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 99.0]),
            indel_lengths: BTreeMap::new(),
            by_chrom: Vec::new(),
            x_heterozygosity: XHeterozygosity {
                het: 0,
                hom_alt: 0,
                het_fraction: None,
                par_excluded: build != GenomeBuild::Unknown,
            },
            chroms: BTreeMap::new(),
            build,
        }
    }

    pub fn observe_ref_block(&mut self) {
        self.ref_blocks += 1;
    }

    pub fn observe(&mut self, call: &Call) {
        self.calls_total += 1;
        *self.filter.entry(call.filter).or_default() += 1;
        if !call.quality_ok {
            self.low_quality += 1;
        }
        if call.is_missing() {
            self.missing += 1;
            return;
        }
        if call.is_explicit_ref() {
            self.hom_ref += 1;
            return;
        }
        if !call.is_carrier() {
            return;
        }
        self.carriers += 1;
        let ploidy = call.genotype.as_ref().map(|g| g.ploidy() as u32);
        let hom = match (call.dosage(), ploidy) {
            (Some(d), Some(p)) => Some(d == p),
            _ => None,
        };
        match hom {
            Some(true) => self.hom_alt += 1,
            Some(false) => self.het += 1,
            None => {}
        }
        *self.by_kind.entry(call.kind).or_default() += 1;
        if call.kind == VariantKind::Snv {
            if call.is_transition() {
                self.transitions += 1;
            } else {
                self.transversions += 1;
            }
        }
        if call.kind.is_indel() {
            let len = (call.alt.len() as i64 - call.reference.len() as i64).clamp(-50, 50);
            *self.indel_lengths.entry(len).or_default() += 1;
        }
        if let Some(q) = call.qual {
            add(&mut self.qual_hist, q);
        }
        if let Some(d) = call.dp {
            add(&mut self.dp_hist, f64::from(d));
        }
        if let Some(g) = call.gq {
            add(&mut self.gq_hist, f64::from(g));
        }

        let cs = self
            .chroms
            .entry(call.chrom.clone())
            .or_insert_with(|| ChromStats { chrom: call.chrom.clone(), ..Default::default() });
        cs.carriers += 1;
        match hom {
            Some(true) => cs.hom_alt += 1,
            Some(false) => cs.het += 1,
            None => {}
        }
        let w = (call.pos.saturating_sub(1) / DENSITY_WINDOW) as usize;
        if cs.density.len() <= w {
            cs.density.resize(w + 1, 0);
        }
        cs.density[w] += 1;

        if call.chrom == "X" && ploidy == Some(2) && in_x_par(self.build, call.pos) != Some(true) {
            match hom {
                Some(true) => self.x_heterozygosity.hom_alt += 1,
                Some(false) => self.x_heterozygosity.het += 1,
                None => {}
            }
        }
    }

    /// Calcula razões e ordena cromossomos. Chame uma vez, no fim.
    pub fn finish(&mut self) {
        let ratio = |a: u64, b: u64| (b > 0).then(|| a as f64 / b as f64);
        self.ti_tv = ratio(self.transitions, self.transversions);
        self.het_hom_ratio = ratio(self.het, self.hom_alt);
        self.missing_rate = ratio(self.missing, self.calls_total);
        let x = &mut self.x_heterozygosity;
        x.het_fraction = ratio(x.het, x.het + x.hom_alt);
        let mut v: Vec<ChromStats> = std::mem::take(&mut self.chroms).into_values().collect();
        v.sort_by_key(|c| chrom_sort_key(&c.chrom));
        self.by_chrom = v;
    }
}

/// Estatísticas de QC de uma amostra, lendo o VCF uma vez.
pub fn sample_stats<R: std::io::Read>(
    source: R,
    sample: &crate::call::SampleSelector,
    filter: crate::filter::CallFilter,
    label: &str,
) -> crate::Result<SampleStats> {
    let mut stream = crate::call::CallStream::new(source, sample, filter)?;
    let h = stream.header();
    let build = crate::build::guess_build(&h.contigs, h.reference.as_deref()).build;
    let mut stats = SampleStats::new(label, build);
    while let Some(item) = stream.next_item()? {
        match item {
            crate::call::StreamItem::Call(c) => stats.observe(&c),
            crate::call::StreamItem::RefBlock { .. } => stats.observe_ref_block(),
        }
    }
    stats.finish();
    Ok(stats)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::record::Genotype;

    fn call(chrom: &str, pos: u64, r: &str, a: &str, gt: &str) -> Call {
        Call {
            chrom: chrom.into(),
            pos,
            reference: r.into(),
            alt: a.into(),
            kind: VariantKind::classify(r, a),
            genotype: Genotype::parse(gt),
            qual: Some(50.0),
            filter: FilterState::Pass,
            dp: Some(12),
            gq: Some(99),
            ids: vec![],
            line: 1,
            split: None,
            quality_ok: true,
        }
    }

    #[test]
    fn hand_computed_example() {
        let mut s = SampleStats::new("A", GenomeBuild::Grch38);
        for c in [
            call("1", 10, "A", "G", "0/1"),         // transição, het
            call("1", 20, "C", "T", "1/1"),         // transição, hom
            call("1", 1_500_000, "A", "C", "0/1"),  // transversão, het, janela 1
            call("2", 5, "A", "ATT", "0/1"),        // inserção +2
            call("2", 9, "GCC", "G", "1/1"),        // deleção -2
            call("2", 30, "A", "G", "0/0"),         // ref explícita
            call("2", 40, "A", "G", "./."),         // ausente
            call("X", 50_000, "A", "G", "0/1"),     // dentro da PAR1 (GRCh38): ignorado no X-het
            call("X", 10_000_000, "A", "G", "0/1"), // fora da PAR
            call("X", 20_000_000, "C", "A", "1"),   // hemizigoto: não conta no X-het
        ] {
            s.observe(&c);
        }
        s.finish();
        assert_eq!((s.calls_total, s.carriers, s.hom_ref, s.missing), (10, 8, 1, 1));
        assert_eq!((s.het, s.hom_alt), (5, 3));
        assert_eq!((s.transitions, s.transversions), (4, 2));
        assert_eq!(s.ti_tv, Some(2.0));
        assert_eq!(s.indel_lengths[&2], 1);
        assert_eq!(s.indel_lengths[&-2], 1);
        assert_eq!(s.by_chrom[0].density, [2, 1]);
        assert_eq!((s.x_heterozygosity.het, s.x_heterozygosity.hom_alt), (1, 0));
        assert_eq!(s.missing_rate, Some(0.1));
        assert_eq!(s.dp_hist.iter().find(|b| b.lo == 10.0).unwrap().count, 8);
    }
}

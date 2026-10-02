//! Gerador de VCF sintético determinístico.
//!
//! Usado em testes, benchmarks e no modo estudante. A mesma semente produz
//! exatamente os mesmos bytes em qualquer plataforma: o gerador de números
//! (SplitMix64) é implementado aqui para não depender de bibliotecas externas
//! cujo algoritmo possa mudar entre versões.
//!
//! Os dados são **fictícios**: posições e alelos aleatórios, sem relação com
//! nenhuma pessoa real. IDs usam o prefixo `syn` para não colidir com rsIDs.

use std::io::Write;

use crate::build::{contig_length, GenomeBuild};
use crate::{GenozError, Result};

/// Gerador SplitMix64 (Steele, Lea & Flood, 2014).
#[derive(Debug, Clone)]
pub struct SplitMix64(u64);

impl SplitMix64 {
    pub fn new(seed: u64) -> Self {
        Self(seed)
    }

    pub fn next_u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9e37_79b9_7f4a_7c15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
        z ^ (z >> 31)
    }

    /// Número em [0, 1) com 53 bits de precisão.
    pub fn next_f64(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 / (1u64 << 53) as f64
    }

    /// Inteiro em [lo, hi] (inclusivo).
    pub fn range(&mut self, lo: u64, hi: u64) -> u64 {
        lo + self.next_u64() % (hi - lo + 1)
    }

    pub fn chance(&mut self, p: f64) -> bool {
        self.next_f64() < p
    }
}

#[derive(Debug, Clone)]
pub struct SynthParams {
    pub seed: u64,
    pub samples: Vec<String>,
    /// Cromossomos canônicos (ex.: `["20","21","22"]`), todos devem ter
    /// comprimento conhecido em [`crate::build::CONTIG_LENGTHS`].
    pub chroms: Vec<String>,
    pub variants_per_chrom: u32,
    pub build: GenomeBuild,
    pub chr_prefix: bool,
    pub indel_rate: f64,
    pub multiallelic_rate: f64,
    pub missing_rate: f64,
    pub phased: bool,
}

impl Default for SynthParams {
    fn default() -> Self {
        Self {
            seed: 42,
            samples: vec!["SINT_A".into(), "SINT_B".into()],
            chroms: vec!["20".into(), "21".into(), "22".into()],
            variants_per_chrom: 1000,
            build: GenomeBuild::Grch38,
            chr_prefix: true,
            indel_rate: 0.12,
            multiallelic_rate: 0.03,
            missing_rate: 0.02,
            phased: false,
        }
    }
}

const BASES: [u8; 4] = *b"ACGT";

fn random_bases(rng: &mut SplitMix64, n: u64) -> String {
    (0..n).map(|_| BASES[rng.range(0, 3) as usize] as char).collect()
}

fn other_base(rng: &mut SplitMix64, not: u8) -> u8 {
    let choices: Vec<u8> = BASES.iter().copied().filter(|b| *b != not).collect();
    choices[rng.range(0, 2) as usize]
}

pub fn write_synthetic_vcf<W: Write>(p: &SynthParams, mut w: W) -> Result<()> {
    if p.build == GenomeBuild::Unknown {
        return Err(GenozError::InvalidParam("escolha GRCh37 ou GRCh38".into()));
    }
    if p.samples.is_empty() {
        return Err(GenozError::InvalidParam("é preciso ao menos uma amostra".into()));
    }
    let mut lengths = Vec::new();
    for c in &p.chroms {
        let len = contig_length(c, p.build)
            .ok_or_else(|| GenozError::InvalidParam(format!("cromossomo sem comprimento conhecido: {c}")))?;
        lengths.push(len);
    }
    let name = |c: &str| if p.chr_prefix { format!("chr{c}") } else { c.to_string() };
    let build_name = match p.build {
        GenomeBuild::Grch37 => "GRCh37",
        _ => "GRCh38",
    };

    writeln!(w, "##fileformat=VCFv4.3")?;
    writeln!(w, "##source=genoz-synth seed={} (dados fictícios)", p.seed)?;
    writeln!(w, "##reference={build_name}")?;
    for (c, len) in p.chroms.iter().zip(&lengths) {
        writeln!(w, "##contig=<ID={},length={len},assembly={build_name}>", name(c))?;
    }
    writeln!(w, "##FILTER=<ID=PASS,Description=\"All filters passed\">")?;
    writeln!(w, "##FILTER=<ID=LowQual,Description=\"QUAL abaixo de 30\">")?;
    writeln!(w, "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Profundidade total\">")?;
    writeln!(w, "##INFO=<ID=AF,Number=A,Type=Float,Description=\"Frequência alélica sintética\">")?;
    writeln!(w, "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genótipo\">")?;
    writeln!(w, "##FORMAT=<ID=AD,Number=R,Type=Integer,Description=\"Profundidade por alelo\">")?;
    writeln!(w, "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Profundidade\">")?;
    writeln!(w, "##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Qualidade do genótipo\">")?;
    write!(w, "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT")?;
    for s in &p.samples {
        write!(w, "\t{s}")?;
    }
    writeln!(w)?;

    let mut rng = SplitMix64::new(p.seed);
    let mut id_counter = 0u64;
    let sep = if p.phased { '|' } else { '/' };
    for (c, len) in p.chroms.iter().zip(&lengths) {
        let usable = len.saturating_sub(20_000);
        let step = (usable / u64::from(p.variants_per_chrom.max(1))).max(10);
        let mut pos = 10_000u64;
        for _ in 0..p.variants_per_chrom {
            pos += rng.range(step / 2, step * 3 / 2).max(10);
            if pos >= usable {
                break;
            }
            let anchor = BASES[rng.range(0, 3) as usize];
            let (reference, alts): (String, Vec<String>) = if rng.chance(p.multiallelic_rate) {
                let a1 = other_base(&mut rng, anchor);
                let mut a2 = other_base(&mut rng, anchor);
                while a2 == a1 {
                    a2 = other_base(&mut rng, anchor);
                }
                ((anchor as char).to_string(), vec![(a1 as char).to_string(), (a2 as char).to_string()])
            } else if rng.chance(p.indel_rate) {
                let extra_len = rng.range(1, 6);
                let extra = random_bases(&mut rng, extra_len);
                let a = (anchor as char).to_string();
                if rng.chance(0.5) {
                    (a.clone(), vec![format!("{a}{extra}")])
                } else {
                    (format!("{a}{extra}"), vec![a])
                }
            } else {
                ((anchor as char).to_string(), vec![(other_base(&mut rng, anchor) as char).to_string()])
            };
            let n_alleles = alts.len() as u64 + 1;
            // Frequência de cada ALT; o restante é da referência.
            let afs: Vec<f64> = alts.iter().map(|_| 0.02 + rng.next_f64() * 0.9 / alts.len() as f64).collect();

            let mut sample_cols = Vec::with_capacity(p.samples.len());
            let mut total_dp = 0u64;
            for _ in &p.samples {
                let dp = rng.range(4, 60);
                if rng.chance(p.missing_rate) {
                    sample_cols.push(format!(".{sep}.:.:{dp}:."));
                    total_dp += dp;
                    continue;
                }
                let draw = |rng: &mut SplitMix64| {
                    let u = rng.next_f64();
                    let mut acc = 0.0;
                    for (i, af) in afs.iter().enumerate() {
                        acc += af;
                        if u < acc {
                            return i as u64 + 1;
                        }
                    }
                    0
                };
                let (a1, a2) = (draw(&mut rng), draw(&mut rng));
                let mut ad = vec![0u64; n_alleles as usize];
                for _ in 0..dp {
                    let pick = if rng.chance(0.5) { a1 } else { a2 };
                    ad[pick as usize] += 1;
                }
                let gq = rng.range(5, 99);
                let ad_s = ad.iter().map(u64::to_string).collect::<Vec<_>>().join(",");
                sample_cols.push(format!("{a1}{sep}{a2}:{ad_s}:{dp}:{gq}"));
                total_dp += dp;
            }

            let qual = rng.range(50, 10_000) as f64 / 10.0;
            let filter = if qual < 30.0 { "LowQual" } else { "PASS" };
            let id = if rng.chance(0.3) {
                id_counter += 1;
                format!("syn{id_counter}")
            } else {
                ".".into()
            };
            let af_s = afs.iter().map(|a| format!("{a:.3}")).collect::<Vec<_>>().join(",");
            write!(
                w,
                "{}\t{pos}\t{id}\t{reference}\t{}\t{qual:.1}\t{filter}\tDP={total_dp};AF={af_s}\tGT:AD:DP:GQ",
                name(c),
                alts.join(",")
            )?;
            for col in &sample_cols {
                write!(w, "\t{col}")?;
            }
            writeln!(w)?;
        }
    }
    w.flush()?;
    Ok(())
}

/// Amostras da família fictícia: avô paterno, pai (filho do avô), mãe, dois filhos,
/// uma pessoa sem parentesco (com um trecho longo de homozigose) e uma duplicata do filho.
pub const FAMILY_SAMPLES: [&str; 7] = ["AVO", "PAI", "MAE", "FILHO", "FILHA", "VIZINHO", "FILHO_REPETIDO"];

/// O que foi plantado na família fictícia (para testes e aulas).
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FamilyTruth {
    /// Variantes novas no FILHO (pai e mãe 0/0).
    pub de_novo: Vec<(String, u64)>,
    /// FILHO 1/1 com o PAI 0/0.
    pub mendelian_error: Option<(String, u64)>,
    /// Trecho homozigoto do VIZINHO: cromossomo, início, fim.
    pub roh: (String, u64, u64),
}

/// VCF multiamostra (chamada conjunta) de uma família FICTÍCIA, determinístico.
/// SNVs bialélicos com frequência entre 5% e 50%; transmissão mendeliana sítio a sítio.
pub fn write_family_vcf<W: Write>(
    seed: u64,
    build: GenomeBuild,
    sites_per_chrom: u32,
    mut w: W,
) -> Result<FamilyTruth> {
    if build == GenomeBuild::Unknown {
        return Err(GenozError::InvalidParam("escolha GRCh37 ou GRCh38".into()));
    }
    let build_name = if build == GenomeBuild::Grch37 { "GRCh37" } else { "GRCh38" };
    let chroms = ["20", "21", "22"];
    writeln!(w, "##fileformat=VCFv4.3")?;
    writeln!(w, "##source=genoz-synth family seed={seed} (dados fictícios)")?;
    writeln!(w, "##reference={build_name}")?;
    for c in chroms {
        let len = contig_length(c, build).expect("comprimento conhecido");
        writeln!(w, "##contig=<ID=chr{c},length={len},assembly={build_name}>")?;
    }
    writeln!(w, "##FILTER=<ID=PASS,Description=\"All filters passed\">")?;
    writeln!(w, "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genótipo\">")?;
    writeln!(w, "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Profundidade\">")?;
    writeln!(w, "##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Qualidade do genótipo\">")?;
    write!(w, "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT")?;
    for s in FAMILY_SAMPLES {
        write!(w, "\t{s}")?;
    }
    writeln!(w)?;

    let mut rng = SplitMix64::new(seed);
    let mut truth = FamilyTruth::default();
    let roh_chrom = "21";
    let (roh_start, roh_end) = (20_000_000u64, 32_000_000u64);
    let mut first_roh = None;
    let mut last_roh = 0;
    for c in chroms {
        let len = contig_length(c, build).expect("comprimento conhecido");
        let usable = len.saturating_sub(20_000);
        let step = (usable / u64::from(sites_per_chrom.max(1))).max(10);
        let mut pos = 10_000u64;
        let mut k = 0u32;
        while k < sites_per_chrom {
            k += 1;
            pos += rng.range(step / 2, step * 3 / 2).max(10);
            if pos >= usable {
                break;
            }
            let q = 0.05 + rng.next_f64() * 0.45;
            let allele = |rng: &mut SplitMix64| u8::from(rng.chance(q));
            let pick = |rng: &mut SplitMix64, g: [u8; 2]| g[usize::from(rng.chance(0.5))];
            let avo = [allele(&mut rng), allele(&mut rng)];
            let avo_parceira = [allele(&mut rng), allele(&mut rng)];
            let pai = [pick(&mut rng, avo), pick(&mut rng, avo_parceira)];
            let mae = [allele(&mut rng), allele(&mut rng)];
            let mut filho = [pick(&mut rng, pai), pick(&mut rng, mae)];
            let filha = [pick(&mut rng, pai), pick(&mut rng, mae)];
            let mut vizinho = [allele(&mut rng), allele(&mut rng)];
            let in_roh = c == roh_chrom && (roh_start..=roh_end).contains(&pos);
            if in_roh {
                vizinho[1] = vizinho[0];
            }
            // Plantados no cromossomo 22: três de novo e um erro mendeliano.
            let mut planted = false;
            if c == "22" && pai == [0, 0] && mae == [0, 0] && truth.de_novo.len() < 3 && k % 97 == 0 {
                filho = [0, 1];
                truth.de_novo.push((format!("chr{c}"), pos));
                planted = true;
            } else if c == "22" && truth.mendelian_error.is_none() && pai == [0, 0] && k > 1500 {
                filho = [1, 1];
                truth.mendelian_error = Some((format!("chr{c}"), pos));
                planted = true;
            }
            let mut repetido = filho;
            if !planted && rng.chance(0.001) {
                repetido[0] ^= 1;
            }
            let genos = [avo, pai, mae, filho, filha, vizinho, repetido];
            if genos.iter().all(|g| g == &[0, 0]) {
                continue; // sítio sem variante: não entra num VCF conjunto
            }
            if in_roh {
                first_roh.get_or_insert(pos);
                last_roh = pos;
            }
            let anchor = BASES[rng.range(0, 3) as usize];
            let alt = other_base(&mut rng, anchor);
            let qual = rng.range(300, 9_999) as f64 / 10.0;
            write!(w, "chr{c}\t{pos}\t.\t{}\t{}\t{qual:.1}\tPASS\t.\tGT:DP:GQ", anchor as char, alt as char)?;
            for g in genos {
                let dp = rng.range(15, 60);
                let gq = rng.range(30, 99);
                if !planted && rng.chance(0.003) {
                    write!(w, "\t./.:{dp}:.")?;
                } else {
                    let (a, b) = (g[0].min(g[1]), g[0].max(g[1]));
                    write!(w, "\t{a}/{b}:{dp}:{gq}")?;
                }
            }
            writeln!(w)?;
        }
    }
    truth.roh = (format!("chr{roh_chrom}"), first_roh.unwrap_or(roh_start), last_roh);
    w.flush()?;
    Ok(truth)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn splitmix_reference_values() {
        // Valores de referência do SplitMix64 com semente 1234567.
        let mut r = SplitMix64::new(1234567);
        assert_eq!(r.next_u64(), 6457827717110365317);
        assert_eq!(r.next_u64(), 3203168211198807973);
    }

    #[test]
    fn deterministic() {
        let p = SynthParams { variants_per_chrom: 200, ..Default::default() };
        let (mut a, mut b) = (Vec::new(), Vec::new());
        write_synthetic_vcf(&p, &mut a).unwrap();
        write_synthetic_vcf(&p, &mut b).unwrap();
        assert_eq!(a, b);
        let other = SynthParams { seed: 7, ..p };
        let mut c = Vec::new();
        write_synthetic_vcf(&other, &mut c).unwrap();
        assert_ne!(a, c);
    }

    #[test]
    fn rejects_unknown_chrom() {
        let p = SynthParams { chroms: vec!["99".into()], ..Default::default() };
        assert!(write_synthetic_vcf(&p, Vec::new()).is_err());
    }
}

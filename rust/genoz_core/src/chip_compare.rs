//! Comparação chip × sequenciamento, restrita aos sítios avaliados pelo chip.
//!
//! A = chip (23andMe, AncestryDNA…), B = uma amostra de um VCF. Para cada sítio
//! do chip:
//! - os genótipos são comparados como **conjunto de letras** (ordem e fase não
//!   importam; multialélicos divididos são recombinados; haploide `A` = `A/A`);
//! - VCF sem registro só conta como referência se houver bloco de referência
//!   (gVCF) ou região avaliada (BED) — ausência não é referência (ADR-010);
//! - sem FASTA, a base de referência de um sítio sem registro no VCF é
//!   desconhecida: homozigotos do chip nesses sítios não são julgados (contados à
//!   parte). Com FASTA, são;
//! - alelos complementares (não palindrômicos) sinalizam possível troca de fita.
//!
//! Variantes do VCF fora do chip não viram linhas (só contagem). O resultado usa
//! o mesmo formato da comparação VCF × VCF (linhas, resumo, estatísticas).

use std::collections::{BTreeMap, HashMap};

use serde::Serialize;

use crate::build::{guess_build, Confidence, GenomeBuild};
use crate::call::{Call, CallStream, StreamItem};
use crate::chrom::chrom_sort_key;
use crate::compare::{
    Category, ChromCategoryCounts, CompareInput, CompareMode, CompareOptions, CompareOutcome, CompareSummary,
    ComparisonRow, SideInfo, SideState, SideView,
};
use crate::consumer::{ChipCall, ChipHeader, ChipVendor};
use crate::fasta::SequenceSource;
use crate::reader::VcfReader;
use crate::record::VariantKind;
use crate::stats::SampleStats;
use crate::{GenozError, Result};

/// Informações próprias da comparação com chip (vão no resumo, em `chip`).
#[derive(Debug, Clone, Default, Serialize)]
pub struct ChipCompareInfo {
    pub vendor: Option<ChipVendor>,
    /// Sítios do chip com genótipo de uma base (sem indels, sem duplicatas).
    pub sites: u64,
    pub no_calls: u64,
    pub indels_skipped: u64,
    pub duplicate_positions: u64,
    /// Variantes da amostra do VCF em posições que o chip não avalia.
    pub vcf_variants_off_chip: u64,
    /// Homozigotos do chip sem registro no VCF e sem como saber a referência.
    pub unknown_reference: u64,
    /// Homozigotos de referência do chip (pelo FASTA) sem registro no VCF e sem região avaliada.
    pub reference_not_assessed: u64,
    pub possible_strand_flips: u64,
    /// Registros do VCF cujo REF difere do FASTA (build errado?).
    pub reference_mismatches: u64,
    pub reference_used: bool,
    /// Concordância só nos sítios em que pelo menos um lado tem alelo alternativo.
    pub nonref_concordance: Option<f64>,
}

/// Arquivo de chip já lido.
pub struct ChipInput {
    pub label: String,
    pub header: ChipHeader,
    pub calls: Vec<ChipCall>,
    pub rejected_lines: u64,
}

struct Site {
    call: ChipCall,
    vcf: Vec<Call>,
    ref_confirmed: bool,
}

fn complement(b: u8) -> u8 {
    match b {
        b'A' => b'T',
        b'T' => b'A',
        b'C' => b'G',
        b'G' => b'C',
        x => x,
    }
}

/// Letras diploides ordenadas (haploide `A` vira `AA`).
fn diploid(mut v: Vec<u8>) -> Vec<u8> {
    if v.len() == 1 {
        v.push(v[0]);
    }
    v.sort_unstable();
    v
}

fn sorted(v: &[u8]) -> Vec<u8> {
    let mut v = v.to_vec();
    v.sort_unstable();
    v
}

fn letters_text(v: &[u8]) -> String {
    v.iter().map(|&b| (b as char).to_string()).collect::<Vec<_>>().join("/")
}

/// Letras do genótipo do VCF na posição, recombinando registros divididos.
/// `None` = sem genótipo utilizável (ausente, inconsistente).
fn vcf_letters(calls: &[&Call]) -> Option<Vec<u8>> {
    let first = calls.first()?;
    let g = first.genotype.as_ref()?;
    if g.is_missing() {
        return None;
    }
    let ploidy = g.alleles.len();
    let reference = *first.reference.as_bytes().first()?;
    let mut out = vec![reference; ploidy];
    let mut used = 0usize;
    for c in calls {
        let d = c.dosage()? as usize;
        let alt = *c.alt.as_bytes().first()?;
        for slot in out.iter_mut().skip(used).take(d) {
            *slot = alt;
        }
        used += d;
        if used > ploidy {
            return None;
        }
    }
    Some(out)
}

pub fn compare_chip(
    chip: ChipInput,
    vcf: &mut CompareInput,
    opts: &CompareOptions,
    mut reference: Option<&mut dyn SequenceSource>,
    sink: &mut dyn FnMut(&ComparisonRow) -> Result<()>,
) -> Result<CompareOutcome> {
    let mut warnings = Vec::new();
    let mut info =
        ChipCompareInfo { vendor: Some(chip.header.vendor), reference_used: reference.is_some(), ..Default::default() };

    // Builds: chips de consumidor são GRCh37; sem liftover local.
    if chip.header.grch36 {
        return Err(GenozError::InvalidParam(
            "comparação recusada: o arquivo do chip está em GRCh36/hg18 (posições incompatíveis)".into(),
        ));
    }
    let header_b = VcfReader::new((vcf.open)()?)?.header().clone();
    let build_a = chip.header.build.clone();
    let build_b = guess_build(&header_b.contigs, header_b.reference.as_deref());
    if build_b.build != GenomeBuild::Unknown && build_b.build != build_a.build {
        let msg = format!("o chip usa {} e o VCF usa {}", build_a.build.label(), build_b.build.label());
        if build_b.confidence == Confidence::High && !opts.allow_build_mismatch {
            return Err(GenozError::InvalidParam(format!(
                "comparação recusada: {msg}; as coordenadas não correspondem (não há conversão local entre builds)"
            )));
        }
        warnings.push(format!("atenção: {msg}"));
    }
    if build_a.confidence == Confidence::Low {
        warnings.push("o arquivo do chip não declara o build; presumido GRCh37".into());
    }
    let build = if build_b.build != GenomeBuild::Unknown { build_b.build } else { build_a.build };

    // Sítios do chip (primeira ocorrência de cada posição; indels fora).
    let mut sites: Vec<Site> = Vec::new();
    let mut index: HashMap<(String, u64), usize> = HashMap::new();
    for call in chip.calls {
        if call.indel {
            info.indels_skipped += 1;
            continue;
        }
        let key = (call.chrom.clone(), call.pos);
        if index.contains_key(&key) {
            info.duplicate_positions += 1;
            continue;
        }
        index.insert(key, sites.len());
        sites.push(Site { call, vcf: Vec::new(), ref_confirmed: false });
    }
    // Posições ordenadas por cromossomo, para marcar blocos de referência.
    let mut by_chrom: HashMap<String, Vec<(u64, usize)>> = HashMap::new();
    for (i, s) in sites.iter().enumerate() {
        by_chrom.entry(s.call.chrom.clone()).or_default().push((s.call.pos, i));
    }
    for v in by_chrom.values_mut() {
        v.sort_unstable();
    }

    // Uma passada pelo VCF.
    let mut stream = CallStream::new((vcf.open)()?, &vcf.sample, opts.call_filter.clone())?;
    let sample_b = stream.sample_name().map(str::to_string);
    let mut stats_b = SampleStats::new(vcf.label.clone(), build);
    let mut stats_a = SampleStats::new(chip.label.clone(), build);
    while let Some(item) = stream.next_item()? {
        match item {
            StreamItem::RefBlock { chrom, start, end } => {
                stats_b.observe_ref_block();
                if let Some(v) = by_chrom.get(&chrom) {
                    let from = v.partition_point(|(p, _)| *p < start);
                    for &(p, i) in &v[from..] {
                        if p > end {
                            break;
                        }
                        sites[i].ref_confirmed = true;
                    }
                }
            }
            StreamItem::Call(c) => {
                stats_b.observe(&c);
                let snv = c.reference.len() == 1 && c.alt.len() == 1 && c.kind == VariantKind::Snv;
                match index.get(&(c.chrom.clone(), c.pos)) {
                    Some(&i) if snv => sites[i].vcf.push(c),
                    _ => {
                        if c.is_carrier() && !c.is_missing() {
                            info.vcf_variants_off_chip += 1;
                        }
                    }
                }
            }
        }
    }
    stats_b.finish();
    let callable = vcf.callable.take();

    sites.sort_by(|x, y| {
        chrom_sort_key(&x.call.chrom).cmp(&chrom_sort_key(&y.call.chrom)).then(x.call.pos.cmp(&y.call.pos))
    });

    let mut counts: BTreeMap<Category, u64> = Category::ALL.iter().map(|c| (*c, 0)).collect();
    let mut by_kind: BTreeMap<Category, BTreeMap<VariantKind, u64>> = BTreeMap::new();
    let mut by_chrom_counts: Vec<ChromCategoryCounts> = Vec::new();
    let (mut rows, mut nonref_same, mut nonref_total) = (0u64, 0u64, 0u64);

    for site in sites {
        let chip_call = &site.call;
        info.sites += 1;
        if chip_call.is_no_call() {
            info.no_calls += 1;
        }
        // Base de referência: do VCF (se houver registro) ou do FASTA.
        let fasta_ref = match reference.as_deref_mut() {
            Some(seq) => seq.base(&chip_call.chrom, chip_call.pos)?,
            None => None,
        };
        let usable: Vec<&Call> = site.vcf.iter().collect();
        if let (Some(first), Some(r)) = (usable.first(), fasta_ref) {
            if first.reference.as_bytes().first() != Some(&r) {
                info.reference_mismatches += 1;
            }
        }
        let ref_base = usable.first().and_then(|c| c.reference.as_bytes().first().copied()).or(fasta_ref);

        // Sem chamada: letras vazias (nunca comparadas).
        let chip_letters = if chip_call.is_no_call() { Vec::new() } else { diploid(chip_call.alleles.clone()) };
        let chip_state = match ref_base {
            _ if chip_call.is_no_call() => SideState::Missing,
            Some(r) if chip_letters.iter().all(|&b| b == r) => SideState::ExplicitRef,
            // Heterozigoto, homozigoto alternativo, ou referência desconhecida.
            _ => SideState::Carrier,
        };
        let chip_view = SideView {
            state: chip_state,
            // Letras em ordem alfabética nos dois lados: fácil de comparar de olho.
            gt: Some(if chip_call.is_no_call() { "--".into() } else { letters_text(&sorted(&chip_call.alleles)) }),
            qual: None,
            dp: None,
            gq: None,
            filter: None,
        };

        let vcf_absent_state = || {
            if let Some(bed) = &callable {
                if bed.contains(&chip_call.chrom, chip_call.pos) {
                    return SideState::AbsentCallable;
                }
                return if site.ref_confirmed { SideState::AbsentRefBlock } else { SideState::NotAssessed };
            }
            if site.ref_confirmed {
                SideState::AbsentRefBlock
            } else {
                SideState::AbsentUnknown
            }
        };

        let (category, b_view, row_ref, row_alt): (Category, SideView, String, String) = if !usable.is_empty() {
            let first = usable[0];
            let quality_ok = usable.iter().all(|c| c.quality_ok);
            let letters = vcf_letters(&usable);
            let state = if letters.is_none() {
                SideState::Missing
            } else if !quality_ok {
                SideState::LowQuality
            } else if usable.iter().any(|c| c.is_carrier()) {
                SideState::Carrier
            } else {
                SideState::ExplicitRef
            };
            let view = SideView {
                state,
                gt: letters.as_ref().map(|l| letters_text(&sorted(l))),
                qual: first.qual,
                dp: first.dp,
                gq: first.gq,
                filter: Some(first.filter),
            };
            let alts: Vec<String> = usable.iter().map(|c| c.alt.clone()).collect();
            let category = if chip_call.is_no_call() || state == SideState::Missing || state == SideState::LowQuality {
                Category::MissingUncertain
            } else {
                let v = diploid(letters.clone().expect("checado acima"));
                if v == chip_letters {
                    Category::Shared
                } else {
                    let flipped = diploid(chip_letters.iter().map(|&b| complement(b)).collect());
                    // A/T e C/G são iguais à própria fita complementar: não dá para saber.
                    let palindromic =
                        chip_letters[0] != chip_letters[1] && complement(chip_letters[0]) == chip_letters[1];
                    if flipped == v && !palindromic {
                        info.possible_strand_flips += 1;
                    }
                    Category::GenotypeDifference
                }
            };
            (category, view, first.reference.clone(), alts.join(","))
        } else {
            let state = vcf_absent_state();
            let confirmed = matches!(state, SideState::AbsentRefBlock | SideState::AbsentCallable);
            let view = SideView {
                state,
                gt: if confirmed { ref_base.map(|r| letters_text(&[r, r])) } else { None },
                qual: None,
                dp: None,
                gq: None,
                filter: None,
            };
            let het = !chip_letters.is_empty() && chip_letters[0] != chip_letters[1];
            let shown_ref = ref_base.map_or_else(|| "?".to_string(), |r| (r as char).to_string());
            let alt_letters: Vec<String> = {
                let mut v: Vec<u8> = chip_letters.iter().copied().filter(|&b| Some(b) != ref_base).collect();
                v.dedup();
                v.iter().map(|&b| (b as char).to_string()).collect()
            };
            let row_alt = if alt_letters.is_empty() { ".".to_string() } else { alt_letters.join(",") };
            let category = if chip_call.is_no_call() {
                // Sem chamada no chip e sem registro no VCF: só vira linha se o VCF garante a referência.
                confirmed.then_some(Category::MissingUncertain)
            } else if confirmed {
                match ref_base {
                    _ if het => Some(Category::GenotypeDifference),
                    Some(r) if chip_letters[0] == r => Some(Category::Shared),
                    Some(_) => Some(Category::GenotypeDifference),
                    None => {
                        info.unknown_reference += 1;
                        None
                    }
                }
            } else {
                match ref_base {
                    _ if het => Some(Category::OnlyA),
                    Some(r) if chip_letters[0] == r => {
                        info.reference_not_assessed += 1;
                        None
                    }
                    Some(_) => Some(Category::OnlyA),
                    None => {
                        info.unknown_reference += 1;
                        None
                    }
                }
            };
            let Some(category) = category else { continue };
            (category, view, shown_ref, row_alt)
        };
        // Concordância sem os sítios em que os dois lados são referência.
        if matches!(category, Category::Shared | Category::GenotypeDifference) {
            let both_ref = chip_state == SideState::ExplicitRef
                && matches!(
                    b_view.state,
                    SideState::ExplicitRef | SideState::AbsentRefBlock | SideState::AbsentCallable
                );
            if !both_ref {
                nonref_total += 1;
                if category == Category::Shared {
                    nonref_same += 1;
                }
            }
        }

        let row = ComparisonRow {
            chrom: chip_call.chrom.clone(),
            pos: chip_call.pos,
            reference: row_ref,
            alt: row_alt,
            kind: VariantKind::Snv,
            category,
            ids: if chip_call.rsid.is_empty() { vec![] } else { vec![chip_call.rsid.clone()] },
            a: chip_view,
            b: b_view,
        };
        rows += 1;
        *counts.entry(category).or_default() += 1;
        *by_kind.entry(category).or_default().entry(VariantKind::Snv).or_default() += 1;
        match by_chrom_counts.last_mut() {
            Some(last) if last.chrom == row.chrom => *last.counts.entry(category).or_default() += 1,
            _ => by_chrom_counts
                .push(ChromCategoryCounts { chrom: row.chrom.clone(), counts: BTreeMap::from([(category, 1)]) }),
        }
        sink(&row)?;
    }
    stats_a.finish();

    if info.unknown_reference > 0 {
        warnings.push(format!(
            "{} sítios homozigotos do chip não têm registro no VCF e a base de referência é desconhecida; \
             com um FASTA de referência eles podem ser avaliados",
            info.unknown_reference
        ));
    }
    if info.possible_strand_flips > 0 {
        warnings.push(format!(
            "{} diferenças são exatamente a fita complementar: provável troca de fita no chip, não diferença real",
            info.possible_strand_flips
        ));
    }
    if info.reference_mismatches > 0 {
        warnings.push(format!(
            "{} registros do VCF têm REF diferente do FASTA: confira se o FASTA é do mesmo build",
            info.reference_mismatches
        ));
    }
    let n = |c: Category| counts.get(&c).copied().unwrap_or(0);
    let both = n(Category::Shared) + n(Category::GenotypeDifference);
    info.nonref_concordance = (nonref_total > 0).then(|| nonref_same as f64 / nonref_total as f64);
    let summary = CompareSummary {
        core_version: crate::CORE_VERSION,
        mode: CompareMode::InMemory,
        a: SideInfo {
            label: chip.label.clone(),
            sample: Some(chip.header.vendor.label().to_string()),
            build: build_a,
            records: info.sites,
            rejected_lines: chip.rejected_lines,
            duplicate_keys: info.duplicate_positions,
            callable_regions: false,
        },
        b: SideInfo {
            label: vcf.label.clone(),
            sample: sample_b,
            build: build_b,
            records: stream.records,
            rejected_lines: stream.rejected_lines,
            duplicate_keys: 0,
            callable_regions: callable.is_some(),
        },
        rows,
        by_kind,
        by_chrom: by_chrom_counts,
        sites_in_both: both,
        genotype_concordance: (both > 0).then(|| n(Category::Shared) as f64 / both as f64),
        // Interseção/união não faz sentido quando um lado define o universo de sítios.
        jaccard: None,
        counts,
        benchmark: None,
        options: opts.clone(),
        warnings,
        chip: Some(info),
    };
    Ok(CompareOutcome { summary, stats_a, stats_b })
}

/// Compara e grava as linhas no formato paginável (`rows.bgz`).
pub fn compare_chip_to_store<W: std::io::Write>(
    chip: ChipInput,
    vcf: &mut CompareInput,
    opts: &CompareOptions,
    reference: Option<&mut dyn SequenceSource>,
    rows_out: W,
) -> Result<crate::compare::StoredComparison<W>> {
    let mut writer = crate::results::ResultWriter::new(rows_out)?;
    let outcome = compare_chip(chip, vcf, opts, reference, &mut |row| writer.push(row))?;
    let (rows_out, index) = writer.finish()?;
    Ok(crate::compare::StoredComparison { rows_out, index, outcome })
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;
    use crate::call::SampleSelector;
    use crate::consumer::read_chip;
    use crate::fasta::MemorySequence;

    const CHIP: &str = "# This data file generated by 23andMe\n\
# We are using reference human assembly build 37\n\
# rsid\tchromosome\tposition\tgenotype\n\
rs1\t1\t1000\tAG\n\
rs2\t1\t2000\tAA\n\
rs3\t1\t3000\tTG\n\
rs4\t1\t4000\tTC\n\
rs5\t1\t5000\tGG\n\
rs6\t1\t6000\t--\n\
rs7\t1\t7000\tAG\n\
rs8\t1\t8000\tGG\n\
rs9\t1\t9000\tAG\n\
rs10\t1\t10000\tCC\n\
i13\t1\t13000\tDI\n\
rs14\t1\t14000\tA\n";

    const VCF: &str = "##fileformat=VCFv4.3\n\
##contig=<ID=chr1,length=249250621>\n\
##INFO=<ID=END,Number=1,Type=Integer,Description=\"Fim\">\n\
##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genótipo\">\n\
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSEQ\n\
chr1\t1000\t.\tA\tG\t50\tPASS\t.\tGT\t0/1\n\
chr1\t2000\t.\tA\tG\t50\tPASS\t.\tGT\t0/1\n\
chr1\t3000\t.\tC\tT,G\t50\tPASS\t.\tGT\t1/2\n\
chr1\t4000\t.\tT\tC\t50\tPASS\t.\tGT\t1|0\n\
chr1\t5000\t.\tA\tC\t50\tPASS\t.\tGT\t1/1\n\
chr1\t6000\t.\tG\tT\t50\tPASS\t.\tGT\t0/1\n\
chr1\t9000\t.\tA\tG\t50\tPASS\t.\tGT\t./.\n\
chr1\t9500\t.\tA\t<NON_REF>\t.\t.\tEND=10500\tGT\t0/0\n\
chr1\t12000\t.\tG\tA\t50\tPASS\t.\tGT\t0/1\n\
chr1\t14000\t.\tA\tG\t50\tPASS\t.\tGT\t0/0\n";

    fn run(reference: Option<&mut dyn SequenceSource>) -> (Vec<ComparisonRow>, CompareSummary) {
        let (header, calls, rejected) = read_chip(CHIP.as_bytes()).unwrap().unwrap();
        let chip = ChipInput { label: "chip".into(), header, calls, rejected_lines: rejected };
        let mut vcf = CompareInput {
            label: "seq".into(),
            open: Box::new(|| Ok(Box::new(VCF.as_bytes()) as Box<dyn std::io::Read>)),
            sample: SampleSelector::First,
            callable: None,
        };
        let mut rows = Vec::new();
        let out = compare_chip(chip, &mut vcf, &CompareOptions::default(), reference, &mut |r| {
            rows.push(r.clone());
            Ok(())
        })
        .unwrap();
        (rows, out.summary)
    }

    fn cat(rows: &[ComparisonRow], pos: u64) -> Option<Category> {
        rows.iter().find(|r| r.pos == pos).map(|r| r.category)
    }

    #[test]
    fn cada_caso_sem_fasta() {
        let (rows, s) = run(None);
        use Category::*;
        assert_eq!(cat(&rows, 1000), Some(Shared));
        assert_eq!(cat(&rows, 2000), Some(GenotypeDifference));
        assert_eq!(cat(&rows, 3000), Some(Shared), "multialélico recombinado: T/G");
        assert_eq!(cat(&rows, 4000), Some(Shared), "ordem e fase não importam");
        assert_eq!(cat(&rows, 5000), Some(GenotypeDifference), "GG × CC");
        assert_eq!(cat(&rows, 6000), Some(MissingUncertain), "sem chamada no chip");
        assert_eq!(cat(&rows, 7000), Some(OnlyA), "chip heterozigoto, VCF sem registro");
        assert_eq!(cat(&rows, 8000), None, "homozigoto sem registro e sem referência: não julgado");
        assert_eq!(cat(&rows, 9000), Some(MissingUncertain), "VCF ./.");
        assert_eq!(cat(&rows, 10000), None, "bloco gVCF, mas base de referência desconhecida");
        assert_eq!(cat(&rows, 14000), Some(Shared), "haploide A = A/A explícito");
        let c = s.chip.as_ref().unwrap();
        assert_eq!((c.sites, c.no_calls, c.indels_skipped), (11, 1, 1));
        assert_eq!((c.unknown_reference, c.possible_strand_flips, c.vcf_variants_off_chip), (2, 1, 1));
        assert_eq!(s.rows, 9);
        assert_eq!(s.counts[&Shared], 4);
        assert_eq!(s.genotype_concordance, Some(4.0 / 6.0));
        assert!(s.jaccard.is_none());
        let r3000 = rows.iter().find(|r| r.pos == 3000).unwrap();
        assert_eq!((r3000.a.gt.as_deref(), r3000.b.gt.as_deref()), (Some("G/T"), Some("G/T")));
        assert_eq!(rows.iter().find(|r| r.pos == 7000).unwrap().reference, "?");
    }

    #[test]
    fn com_fasta_os_homozigotos_sao_julgados() {
        let mut seq = vec![b'A'; 20000];
        for (pos, b) in [(3000, b'C'), (4000, b'T'), (6000, b'G'), (8000, b'G'), (10000, b'C'), (12000, b'G')] {
            seq[pos - 1] = b;
        }
        let mut fasta = MemorySequence(HashMap::from([("1".to_string(), seq)]));
        let (rows, s) = run(Some(&mut fasta));
        let c = s.chip.as_ref().unwrap();
        assert_eq!(cat(&rows, 8000), None, "GG = referência, sem registro e sem região avaliada");
        assert_eq!(c.reference_not_assessed, 1);
        assert_eq!(cat(&rows, 10000), Some(Category::Shared), "bloco gVCF + FASTA: C/C = C/C");
        assert_eq!(c.unknown_reference, 0);
        assert_eq!(c.reference_mismatches, 0);
        assert_eq!(rows.iter().find(|r| r.pos == 7000).unwrap().reference, "A");
        // Concordância sem referência × referência: 10000 (ambos referência) e 14000 ficam fora.
        assert_eq!(c.nonref_concordance, Some(3.0 / 5.0));
    }

    #[test]
    fn os_quatro_formatos_dao_o_mesmo_resultado() {
        let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/consumidor");
        let vcf_text = std::fs::read_to_string(dir.join("pessoa_ficticia_grch37.vcf")).unwrap();
        let mut results = Vec::new();
        for name in ["chip_23andme.txt", "chip_ancestrydna.txt", "chip_myheritage.csv", "chip_ftdna.csv"] {
            let bytes = std::fs::read(dir.join(name)).unwrap();
            let (header, calls, rejected) = read_chip(&bytes[..]).unwrap().unwrap();
            let chip = ChipInput { label: "chip".into(), header, calls, rejected_lines: rejected };
            let text = vcf_text.clone();
            let mut vcf = CompareInput {
                label: "seq".into(),
                open: Box::new(move || {
                    Ok(Box::new(std::io::Cursor::new(text.clone().into_bytes())) as Box<dyn std::io::Read>)
                }),
                sample: SampleSelector::First,
                callable: None,
            };
            let mut rows = Vec::new();
            let out = compare_chip(chip, &mut vcf, &CompareOptions::default(), None, &mut |r| {
                rows.push(r.clone());
                Ok(())
            })
            .unwrap();
            assert_eq!(out.summary.rows, 11, "{name}");
            results.push(rows);
        }
        assert!(results.windows(2).all(|w| w[0] == w[1]), "mesmas linhas em todos os formatos");
    }

    #[test]
    fn build_diferente_e_recusado() {
        let (header, calls, rejected) = read_chip(CHIP.as_bytes()).unwrap().unwrap();
        let chip = ChipInput { label: "chip".into(), header, calls, rejected_lines: rejected };
        let vcf38 = VCF.replace("length=249250621", "length=248956422");
        let mut vcf = CompareInput {
            label: "seq".into(),
            open: Box::new(move || {
                Ok(Box::new(std::io::Cursor::new(vcf38.clone().into_bytes())) as Box<dyn std::io::Read>)
            }),
            sample: SampleSelector::First,
            callable: None,
        };
        let err = compare_chip(chip, &mut vcf, &CompareOptions::default(), None, &mut |_| Ok(())).err().unwrap();
        assert!(err.user_message().contains("GRCh38"), "{}", err.user_message());
    }
}

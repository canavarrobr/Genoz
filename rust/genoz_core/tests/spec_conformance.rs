//! Conformidade com os exemplos das especificações oficiais VCF 4.1–4.5
//! (fixtures em `test_fixtures/spec`, origem documentada no README de lá).

use std::path::PathBuf;

use genoz_core::build::GenomeBuild;
use genoz_core::call::{CallStream, SampleSelector, StreamItem};
use genoz_core::filter::CallFilter;
use genoz_core::inspect::{inspect_path, InspectOptions, InspectReport, Verdict};
use genoz_core::reader::{IssueCode, VcfReader};
use genoz_core::record::VariantKind;

fn path(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/spec").join(name)
}

fn inspect(name: &str) -> InspectReport {
    inspect_path(&path(name), &InspectOptions::default()).unwrap()
}

fn kinds(r: &InspectReport) -> Vec<(VariantKind, u64)> {
    r.by_kind.iter().map(|(k, v)| (*k, *v)).collect()
}

/// Chaves normalizadas `pos:REF>ALT` (ou `pos-fim` para blocos) de uma amostra.
fn stream_keys(name: &str) -> Vec<String> {
    let mut s =
        CallStream::new(std::fs::File::open(path(name)).unwrap(), &SampleSelector::First, CallFilter::default())
            .unwrap();
    let mut out = Vec::new();
    while let Some(item) = s.next_item().unwrap() {
        out.push(match item {
            StreamItem::Call(c) => format!("{}:{}>{}", c.pos, c.reference, c.alt),
            StreamItem::RefBlock { start, end, .. } => format!("bloco {start}-{end}"),
        });
    }
    out
}

#[test]
fn main_example_is_read_identically_in_every_version() {
    let reports: Vec<InspectReport> =
        ["4.1", "4.2", "4.3", "4.4", "4.5"].iter().map(|v| inspect(&format!("exemplo_principal_v{v}.vcf"))).collect();
    for (r, v) in reports.iter().zip(["4.1", "4.2", "4.3", "4.4", "4.5"]) {
        assert_eq!(r.verdict, Verdict::Valid, "v{v}: {:#?}", r.issues);
        assert_eq!(r.file_format.as_deref(), Some(format!("VCFv{v}").as_str()));
        assert_eq!((r.records_ok, r.multiallelic, r.biallelic_after_split), (5, 2, 7));
        assert_eq!(
            kinds(r),
            [(VariantKind::Snv, 4), (VariantKind::Insertion, 1), (VariantKind::Deletion, 1), (VariantKind::Other, 1)]
        );
        // NCBI36 (B36) não é GRCh37 nem GRCh38: o Genoz não deve chutar.
        assert_eq!(r.build.build, GenomeBuild::Unknown);
        let counts: Vec<(u64, u64, u64)> = r.samples.iter().map(|s| (s.hom_ref, s.het, s.hom_alt)).collect();
        assert_eq!(counts, [(3, 2, 0), (1, 4, 0), (2, 0, 3)]);
        assert_eq!((r.filter_pass, r.filter_failed), (4, 1));
    }
}

#[test]
fn main_example_microsatellite_is_normalized() {
    // GTC>G,GTCT vira deleção GTC>G e inserção C>CT duas bases adiante.
    let keys = stream_keys("exemplo_principal_v4.5.vcf");
    assert!(keys.contains(&"1234567:GTC>G".to_string()), "{keys:?}");
    assert!(keys.contains(&"1234569:C>CT".to_string()), "{keys:?}");
    // Sítio monomórfico (ALT '.') não é variante.
    assert!(!keys.iter().any(|k| k.starts_with("1230237")));
}

#[test]
fn per_allele_phasing_prefix_v45() {
    let literal = inspect("v45_fase_psl_literal.vcf");
    assert_eq!(literal.issue_counts.get(&IssueCode::GenotypeAlleleOutOfRange), Some(&2));

    let fixed = inspect("v45_fase_psl_corrigido.vcf");
    assert_eq!(fixed.verdict, Verdict::Valid, "{:#?}", fixed.issues);
    let mut reader = VcfReader::new(std::fs::File::open(path("v45_fase_psl_corrigido.vcf")).unwrap()).unwrap();
    let gts: Vec<(Vec<Option<u32>>, bool)> = std::iter::from_fn(|| reader.next_parsed().unwrap())
        .map(|p| {
            let g = p.record.unwrap().samples[0].gt.clone().unwrap();
            (g.alleles, g.phased)
        })
        .collect();
    assert_eq!(gts[0], (vec![Some(0), Some(1)], false), "|0/1: fase mista");
    assert_eq!(gts[1], (vec![Some(1), Some(2), Some(3)], false), "|1/2|3: triploide, fase mista");
    assert_eq!(gts[2], (vec![Some(1), Some(2)], true), "1|2: primeiro alelo implicitamente em fase");
}

#[test]
fn structural_variant_notations_v45() {
    let r = inspect("v45_estruturais.vcf");
    assert_eq!(r.verdict, Verdict::Valid, "{:#?}", r.issues);
    assert_eq!(kinds(&r), [(VariantKind::Insertion, 1), (VariantKind::Deletion, 1), (VariantKind::Structural, 7)]);
}

#[test]
fn breakends_and_telomere_v45() {
    let r = inspect("v45_breakends.vcf");
    assert_eq!(r.verdict, Verdict::ValidWithWarnings);
    assert_eq!(r.records_ok, 8);
    assert_eq!(kinds(&r), [(VariantKind::Structural, 8)]);
    assert_eq!(r.issue_counts.get(&IssueCode::InvalidPos), Some(&1), "aviso de POS 0 (telômero)");
}

#[test]
fn reference_blocks_with_format_len_v45() {
    // O exemplo oficial traz END e LEN inconsistentes em 3 linhas; na 4.5
    // FORMAT/LEN é o valor válido (END é campo calculado, depreciado).
    let r = inspect("v45_blocos_referencia.vcf");
    assert_eq!(r.verdict, Verdict::ValidWithWarnings, "{:#?}", r.issues);
    assert_eq!(r.issue_counts.get(&IssueCode::EndLenMismatch), Some(&1), "avisado uma vez por arquivo");
    assert_eq!(
        stream_keys("v45_blocos_referencia.vcf"),
        [
            "bloco 4370-4383",
            "bloco 4384-4387",
            "4389:T>TC",
            "bloco 4390-4390",
            "bloco 4391-4394",
            "4396:G>C",
            "bloco 4397-4415",
        ]
    );
}

#[test]
fn overlapping_alleles_decompose_like_the_spec_v45() {
    // TC>TG,T e TCG>TG,T,TCAG em POS 2 viram as formas mínimas do exemplo
    // da especificação: 2:TC>T, 3:C>G, 2:TCG>T e 3:C>CA.
    let keys = stream_keys("v45_normalizacao.vcf");
    assert_eq!(keys, ["2:TC>T", "2:TC>T", "2:TCG>T", "3:C>CA", "3:C>G"]);
}

#[test]
fn tandem_repeats_v44() {
    let r = inspect("v44_repeticoes_tandem.vcf");
    assert_eq!(r.verdict, Verdict::Valid, "{:#?}", r.issues);
    assert_eq!(kinds(&r), [(VariantKind::Insertion, 1), (VariantKind::Deletion, 1), (VariantKind::Structural, 2)]);
}

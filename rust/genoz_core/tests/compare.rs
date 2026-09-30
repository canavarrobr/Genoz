//! Testes de integração da comparação A × B (fixtures em `test_fixtures/compare`).

use std::collections::BTreeMap;
use std::io::Read;
use std::path::PathBuf;

use genoz_core::call::SampleSelector;
use genoz_core::compare::{
    compare, Category, CompareInput, CompareMode, CompareOptions, ComparisonRow, SideState, Truth,
};
use genoz_core::filter::CallFilter;
use genoz_core::regions::read_bed;
use genoz_core::results::{ResultReader, ResultWriter};
use genoz_core::synth::{write_synthetic_vcf, SynthParams};
use genoz_core::GenozError;

fn fixture(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/compare").join(name)
}

fn from_file(label: &str, name: &str) -> CompareInput<'static> {
    let path = fixture(name);
    CompareInput {
        label: label.into(),
        open: Box::new(move || Ok(Box::new(std::fs::File::open(&path)?) as Box<dyn Read>)),
        sample: SampleSelector::First,
        callable: None,
    }
}

fn from_bytes(label: &str, data: Vec<u8>) -> CompareInput<'static> {
    CompareInput {
        label: label.into(),
        open: Box::new(move || Ok(Box::new(std::io::Cursor::new(data.clone())) as Box<dyn Read>)),
        sample: SampleSelector::First,
        callable: None,
    }
}

fn run(
    mut a: CompareInput,
    mut b: CompareInput,
    opts: &CompareOptions,
) -> Result<(Vec<ComparisonRow>, genoz_core::compare::CompareOutcome), GenozError> {
    let mut rows = Vec::new();
    let out = compare(&mut a, &mut b, opts, &mut |r| {
        rows.push(r.clone());
        Ok(())
    })?;
    Ok((rows, out))
}

fn by_pos(rows: &[ComparisonRow]) -> BTreeMap<String, (Category, SideState, SideState)> {
    rows.iter().map(|r| (format!("{}:{}>{}", r.pos, r.reference, r.alt), (r.category, r.a.state, r.b.state))).collect()
}

#[test]
fn every_category_on_hand_made_pair() {
    let (rows, out) =
        run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b.vcf"), &CompareOptions::default()).unwrap();
    let m = by_pos(&rows);
    use Category::*;
    use SideState::*;
    assert_eq!(m["1000:A>G"], (Shared, Carrier, Carrier));
    assert_eq!(m["2000:C>T"], (GenotypeDifference, Carrier, Carrier));
    assert_eq!(m["3000:G>A"], (OnlyA, Carrier, AbsentUnknown));
    assert_eq!(m["4000:T>C"], (OnlyB, AbsentUnknown, Carrier));
    assert_eq!(m["5000:A>C"], (OnlyA, Carrier, ExplicitRef));
    assert_eq!(m["6000:G>T"], (MissingUncertain, Carrier, Missing));
    assert_eq!(m["7000:A>G"], (Shared, Carrier, Carrier));
    assert_eq!(m["7000:A>T"], (OnlyA, Carrier, AbsentUnknown));
    assert_eq!(m["8001:A>G"], (Shared, Carrier, Carrier), "MNV aparado deve casar com o SNV");
    assert_eq!(m["9000:A>G"], (OnlyA, Carrier, AbsentUnknown));
    assert_eq!(m["10000:T>TA"], (Shared, Carrier, Carrier));
    assert_eq!(m["11000:C>G"], (Shared, Carrier, Carrier), "fase não muda o genótipo");
    assert_eq!(rows.len(), 12);

    let s = &out.summary;
    assert_eq!(s.mode, CompareMode::Streaming);
    assert_eq!(s.counts[&Shared], 5);
    assert_eq!(s.counts[&GenotypeDifference], 1);
    assert_eq!(s.counts[&OnlyA], 4);
    assert_eq!(s.counts[&OnlyB], 1);
    assert_eq!(s.counts[&MissingUncertain], 1);
    assert_eq!(s.genotype_concordance, Some(5.0 / 6.0));
    assert_eq!(s.jaccard, Some(6.0 / 11.0));
    assert_eq!(s.a.sample.as_deref(), Some("PESSOA_A"));
    // IDs dos dois lados são reunidos.
    assert_eq!(rows.iter().find(|r| r.pos == 4000).unwrap().ids, ["syn4"]);

    // Estatísticas de cada lado vêm na mesma passada.
    assert_eq!(out.stats_a.carriers, 11);
    assert_eq!(out.stats_b.hom_ref, 1);
    assert_eq!(out.stats_b.missing, 1);
}

#[test]
fn quality_gate_makes_low_quality_uncertain_not_absent() {
    let opts =
        CompareOptions { call_filter: CallFilter { min_gq: Some(20), ..Default::default() }, ..Default::default() };
    let (rows, out) = run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b.vcf"), &opts).unwrap();
    let m = by_pos(&rows);
    assert_eq!(m["9000:A>G"], (Category::MissingUncertain, SideState::LowQuality, SideState::AbsentUnknown));
    assert_eq!(out.summary.counts[&Category::OnlyA], 3);
    assert_eq!(out.stats_a.low_quality, 1);
}

#[test]
fn callable_bed_marks_not_assessed() {
    let (bed, issues) = read_bed(std::fs::File::open(fixture("pessoa_b_chamavel.bed")).unwrap()).unwrap();
    assert!(issues.is_empty());
    let mut b = from_file("B", "pessoa_b.vcf");
    b.callable = Some(bed);
    let (rows, out) = run(from_file("A", "pessoa_a.vcf"), b, &CompareOptions::default()).unwrap();
    let m = by_pos(&rows);
    assert_eq!(m["3000:G>A"], (Category::NotAssessed, SideState::Carrier, SideState::NotAssessed));
    assert_eq!(m["9000:A>G"], (Category::OnlyA, SideState::Carrier, SideState::AbsentCallable));
    assert_eq!(out.summary.counts[&Category::NotAssessed], 1);
    assert!(out.summary.b.callable_regions);
}

#[test]
fn benchmark_metrics() {
    let opts = CompareOptions { truth: Some(Truth::B), ..Default::default() };
    let (_, out) = run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b.vcf"), &opts).unwrap();
    let bm = out.summary.benchmark.unwrap();
    assert_eq!((bm.all.true_positives, bm.all.false_positives, bm.all.false_negatives), (6, 4, 1));
    assert_eq!(bm.all.precision, Some(0.6));
    assert!((bm.all.recall.unwrap() - 6.0 / 7.0).abs() < 1e-12);
    assert_eq!((bm.indel.true_positives, bm.indel.false_positives), (1, 0));
}

#[test]
fn unsorted_input_falls_back_to_memory_with_same_rows() {
    let (sorted, _) =
        run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b.vcf"), &CompareOptions::default()).unwrap();
    let (rows, out) =
        run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b_desordenado.vcf"), &CompareOptions::default())
            .unwrap();
    assert_eq!(out.summary.mode, CompareMode::InMemory);
    assert!(out.summary.warnings.iter().any(|w| w.contains("em memória")));
    assert_eq!(rows, sorted);
}

#[test]
fn streaming_equals_in_memory_on_synthetic_data() {
    let mk = |seed, samples: &[&str]| {
        let mut v = Vec::new();
        let p = SynthParams {
            seed,
            variants_per_chrom: 1500,
            samples: samples.iter().map(|s| s.to_string()).collect(),
            ..Default::default()
        };
        write_synthetic_vcf(&p, &mut v).unwrap();
        v
    };
    // Mesmo arquivo multiamostra; comparamos a amostra 1 com a 2.
    let data = mk(11, &["S1", "S2"]);
    let input = |label: &str, idx| {
        let mut i = from_bytes(label, data.clone());
        i.sample = SampleSelector::Index(idx);
        i
    };
    let (stream_rows, s1) = run(input("A", 0), input("B", 1), &CompareOptions::default()).unwrap();
    let opts = CompareOptions { force_in_memory: true, ..Default::default() };
    let (mem_rows, s2) = run(input("A", 0), input("B", 1), &opts).unwrap();
    assert_eq!(s1.summary.mode, CompareMode::Streaming);
    assert_eq!(s2.summary.mode, CompareMode::InMemory);
    assert_eq!(stream_rows, mem_rows);
    assert!(s1.summary.counts[&Category::Shared] > 0);
    assert!(s1.summary.counts[&Category::GenotypeDifference] > 0);
    assert!(s1.summary.counts[&Category::OnlyA] > 0);
    assert!(s1.summary.counts[&Category::MissingUncertain] > 0);
}

#[test]
fn identity_is_all_shared() {
    let (rows, out) =
        run(from_file("A", "pessoa_a.vcf"), from_file("A2", "pessoa_a.vcf"), &CompareOptions::default()).unwrap();
    assert!(rows.iter().all(|r| r.category == Category::Shared));
    assert_eq!(out.summary.genotype_concordance, Some(1.0));
    assert_eq!(out.summary.jaccard, Some(1.0));
}

#[test]
fn build_mismatch_is_refused() {
    let vcf = |contig_len: u64| {
        format!(
            "##fileformat=VCFv4.3\n##contig=<ID=1,length={contig_len}>\n\
             #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n1\t10\t.\tA\tG\t.\t.\t.\tGT\t0/1\n"
        )
        .into_bytes()
    };
    let err = run(from_bytes("A", vcf(249_250_621)), from_bytes("B", vcf(248_956_422)), &CompareOptions::default())
        .err()
        .unwrap();
    assert!(err.to_string().contains("recusada"), "{err}");
    let opts = CompareOptions { allow_build_mismatch: true, ..Default::default() };
    let (_, out) = run(from_bytes("A", vcf(249_250_621)), from_bytes("B", vcf(248_956_422)), &opts).unwrap();
    assert!(out.summary.warnings.iter().any(|w| w.contains("GRCh37")));
}

#[test]
fn gvcf_reference_blocks_confirm_absence() {
    let a = "##fileformat=VCFv4.3\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\n\
             1\t150\t.\tA\tG\t50\tPASS\t.\tGT\t0/1\n1\t500\t.\tC\tT\t50\tPASS\t.\tGT\t0/1\n";
    let b = "##fileformat=VCFv4.3\n##INFO=<ID=END,Number=1,Type=Integer,Description=\"\">\n\
             #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tB\n\
             1\t100\t.\tT\t<NON_REF>\t.\t.\tEND=200\tGT\t0/0\n\
             1\t201\t.\tG\tA,<NON_REF>\t50\tPASS\t.\tGT\t0/1\n";
    let (rows, out) = run(from_bytes("A", a.into()), from_bytes("B", b.into()), &CompareOptions::default()).unwrap();
    let m = by_pos(&rows);
    assert_eq!(m["150:A>G"], (Category::OnlyA, SideState::Carrier, SideState::AbsentRefBlock));
    assert_eq!(m["500:C>T"], (Category::OnlyA, SideState::Carrier, SideState::AbsentUnknown));
    assert_eq!(m["201:G>A"], (Category::OnlyB, SideState::AbsentUnknown, SideState::Carrier));
    assert_eq!(out.stats_b.ref_blocks, 1);
}

#[test]
fn result_store_round_trip() {
    let (rows, _) =
        run(from_file("A", "pessoa_a.vcf"), from_file("B", "pessoa_b.vcf"), &CompareOptions::default()).unwrap();
    let mut w = ResultWriter::new(Vec::new()).unwrap();
    for r in &rows {
        w.push(r).unwrap();
    }
    let (bytes, index) = w.finish().unwrap();
    let mut reader = ResultReader::new(std::io::Cursor::new(bytes), index);
    assert_eq!(reader.page(0, 100).unwrap(), rows);
}

#[test]
fn unknown_sample_name_is_explained() {
    let mut a = from_file("A", "pessoa_a.vcf");
    a.sample = SampleSelector::Name("FULANO".into());
    let err = run(a, from_file("B", "pessoa_b.vcf"), &CompareOptions::default()).err().unwrap();
    assert!(err.to_string().contains("PESSOA_A"), "{err}");
}

/// Mesmos bytes de resultado em qualquer plataforma (verificado no CI em
/// Linux, Windows e macOS). Se mudar de propósito o formato ou a versão do
/// núcleo (que vai no resumo), atualize o hash.
#[test]
fn stored_result_is_byte_identical_across_platforms() {
    let mut a = from_file("A", "pessoa_a.vcf");
    let mut b = from_file("B", "pessoa_b.vcf");
    let stored = genoz_core::compare::compare_to_store(&mut a, &mut b, &CompareOptions::default(), Vec::new()).unwrap();
    let summary = genoz_core::compare::to_json_bytes(&stored.outcome.summary);
    let digest = genoz_core::digest::sha256_bytes(&[stored.rows_out, stored.index.to_bytes(), summary].concat());
    assert_eq!(digest, COMPARE_FIXTURE_SHA256);
}

const COMPARE_FIXTURE_SHA256: &str = "b4d285566563faf250abef42a9e869abfcc7d2f380a81df2337d0f9a8cb75435";

//! Testes de integração sobre os arquivos de `test_fixtures/vcf`.

use std::io::Write;
use std::path::PathBuf;

use genoz_core::build::{Confidence, GenomeBuild};
use genoz_core::chrom::ChromStyle;
use genoz_core::digest::sha256_bytes;
use genoz_core::inspect::{inspect, inspect_path, InspectOptions, Verdict};
use genoz_core::io::{BgzfWriter, Compression};
use genoz_core::normalize::split_multiallelic;
use genoz_core::reader::{IssueCode, VcfReader};
use genoz_core::record::VariantKind;
use genoz_core::synth::{write_synthetic_vcf, SynthParams};
use genoz_core::GenozError;

fn fixture(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/vcf").join(name)
}

fn opts() -> InspectOptions {
    InspectOptions::default()
}

fn bgzf(data: &[u8]) -> Vec<u8> {
    let mut w = BgzfWriter::new(Vec::new());
    w.write_all(data).unwrap();
    w.finish().unwrap()
}

#[test]
fn valid_small_file_summary() {
    let r = inspect_path(&fixture("valid_small_grch38_chr.vcf"), &opts()).unwrap();
    assert_eq!(r.verdict, Verdict::Valid, "{:#?}", r.issues);
    assert_eq!(r.compression, Compression::None);
    assert_eq!((r.build.build, r.build.confidence), (GenomeBuild::Grch38, Confidence::High));
    assert_eq!(r.chrom_style, ChromStyle::Ucsc);
    assert_eq!((r.records_read, r.records_ok, r.multiallelic, r.biallelic_after_split), (9, 9, 1, 10));
    assert_eq!(r.by_kind[&VariantKind::Snv], 6);
    assert_eq!(r.by_kind[&VariantKind::Insertion], 1);
    assert_eq!(r.by_kind[&VariantKind::Deletion], 1);
    assert_eq!(r.by_kind[&VariantKind::Mnv], 1);
    assert_eq!(r.by_kind[&VariantKind::Structural], 1);
    assert_eq!((r.filter_pass, r.filter_failed, r.filter_missing), (7, 1, 1));
    let a = &r.samples[0];
    assert_eq!((a.hom_ref, a.het, a.hom_alt, a.missing), (0, 6, 3, 0));
    let b = &r.samples[1];
    assert_eq!((b.hom_ref, b.het, b.hom_alt, b.missing), (3, 2, 3, 1));
    let chroms: Vec<&str> = r.by_chrom.iter().map(|c| c.chrom.as_str()).collect();
    assert_eq!(chroms, ["1", "2", "X", "MT"]);
    assert!(r.sorted);
    let digest = r.digest.unwrap();
    let bytes = std::fs::read(fixture("valid_small_grch38_chr.vcf")).unwrap();
    assert_eq!(digest.sha256, sha256_bytes(&bytes));
}

#[test]
fn sites_only_grch37() {
    let r = inspect_path(&fixture("valid_sites_only_grch37.vcf"), &opts()).unwrap();
    assert_eq!(r.verdict, Verdict::Valid, "{:#?}", r.issues);
    assert_eq!(r.build.build, GenomeBuild::Grch37);
    assert_eq!(r.chrom_style, ChromStyle::Ensembl);
    assert!(r.samples.is_empty());
    assert_eq!(r.records_ok, 3);
}

#[test]
fn invalid_records_are_reported_with_lines() {
    let r = inspect_path(&fixture("invalid_records.vcf"), &opts()).unwrap();
    assert_eq!(r.verdict, Verdict::PartiallyValid);
    assert_eq!((r.records_read, r.records_ok, r.records_rejected), (9, 4, 5));
    assert_eq!((r.errors, r.warnings), (5, 3));
    for code in [
        IssueCode::InvalidPos,
        IssueCode::InvalidRef,
        IssueCode::InvalidAlt,
        IssueCode::GenotypeAlleleOutOfRange,
        IssueCode::SampleCountMismatch,
        IssueCode::InvalidQual,
        IssueCode::UnsortedPositions,
        IssueCode::ContigNotInHeader,
    ] {
        assert_eq!(r.issue_counts.get(&code), Some(&1), "{code:?}");
    }
    // Cabeçalho tem 4 linhas; o POS inválido é a 2ª linha de dados.
    let bad_pos = r.issues.iter().find(|i| i.code == IssueCode::InvalidPos).unwrap();
    assert_eq!(bad_pos.line, 6);
    assert!(!r.sorted);
}

#[test]
fn non_vcf_files_are_rejected_clearly() {
    for name in ["invalid_no_chrom_line.vcf", "not_vcf_23andme_like.txt"] {
        let err = inspect_path(&fixture(name), &opts()).unwrap_err();
        assert!(matches!(err, GenozError::InvalidHeader(_)), "{name}: {err}");
    }
}

#[test]
fn missing_file_message() {
    let err = inspect_path(&fixture("nao_existe.vcf"), &opts()).unwrap_err();
    assert_eq!(err.user_message(), "arquivo não encontrado");
}

#[test]
fn bgzf_and_plain_give_same_summary() {
    let plain = std::fs::read(fixture("valid_small_grch38_chr.vcf")).unwrap();
    let packed = bgzf(&plain);
    let a = inspect(&plain[..], &opts()).unwrap();
    let b = inspect(&packed[..], &opts()).unwrap();
    assert_eq!(b.compression, Compression::Bgzf);
    assert_eq!(a.records_ok, b.records_ok);
    assert_eq!(a.by_kind, b.by_kind);
}

#[test]
fn truncated_gzip_is_reported_not_panicking() {
    let mut vcf = Vec::new();
    write_synthetic_vcf(&SynthParams { variants_per_chrom: 3000, ..Default::default() }, &mut vcf).unwrap();
    let packed = bgzf(&vcf);
    let cut = &packed[..packed.len() / 2];
    let r = inspect(cut, &opts()).unwrap();
    assert_eq!(r.verdict, Verdict::Invalid);
    assert!(r.fatal.is_some());
    assert!(r.records_ok > 0, "o que foi lido antes do corte continua disponível");
}

#[test]
fn synthetic_file_is_valid_and_splits_consistently() {
    let params = SynthParams {
        variants_per_chrom: 2000,
        samples: vec!["A".into(), "B".into(), "C".into()],
        ..Default::default()
    };
    let mut vcf = Vec::new();
    write_synthetic_vcf(&params, &mut vcf).unwrap();
    let r = inspect(&vcf[..], &opts()).unwrap();
    assert_eq!(r.verdict, Verdict::Valid, "{:#?}", r.issues);
    assert_eq!(r.build.build, GenomeBuild::Grch38);
    assert!(r.multiallelic > 0);
    assert_eq!(r.biallelic_after_split, r.records_ok + r.multiallelic);
    assert!(r.by_kind.get(&VariantKind::Insertion).copied().unwrap_or(0) > 0);
    assert!(r.by_kind.get(&VariantKind::Deletion).copied().unwrap_or(0) > 0);

    // Depois de dividir, nenhum registro é multialélico e todo GT usa só 0/1.
    let mut reader = VcfReader::new(&vcf[..]).unwrap();
    let header = reader.header().clone();
    while let Some(p) = reader.next_parsed().unwrap() {
        for part in split_multiallelic(&p.record.unwrap(), &header) {
            assert_eq!(part.alts.len(), 1);
            for s in &part.samples {
                if let Some(g) = &s.gt {
                    assert!(g.alleles.iter().flatten().all(|a| *a <= 1));
                }
            }
        }
    }
}

/// Garante que o gerador produz os mesmos bytes em qualquer plataforma
/// (Windows, Linux, Android, WASM). Se este teste falhar após uma mudança
/// intencional no gerador, atualize o hash e registre no CHANGELOG.
#[test]
fn synthetic_output_is_stable_across_platforms() {
    let params = SynthParams { variants_per_chrom: 500, ..Default::default() };
    let mut vcf = Vec::new();
    write_synthetic_vcf(&params, &mut vcf).unwrap();
    assert_eq!(sha256_bytes(&vcf), SYNTH_SEED42_V500_SHA256);
}

const SYNTH_SEED42_V500_SHA256: &str = "dd8e7d9c6224dea031fc4cd56205d5655ca4780c3853fd2526325300ccf72a7f";

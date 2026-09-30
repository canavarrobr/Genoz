//! Testes de propriedade: linhas válidas geradas ao acaso devem ser lidas e
//! reescritas sem alteração, e nunca causar pânico.

use genoz_core::header::VcfHeader;
use genoz_core::record::parse_record;
use proptest::prelude::*;

fn header() -> VcfHeader {
    VcfHeader { samples: vec!["S1".into(), "S2".into()], ..Default::default() }
}

fn bases(max: usize) -> impl Strategy<Value = String> {
    proptest::string::string_regex(&format!("[ACGT]{{1,{max}}}")).unwrap()
}

fn gt(n_alts: usize) -> impl Strategy<Value = String> {
    let allele = prop_oneof![
        4 => (0..=n_alts as u32).prop_map(|a| a.to_string()),
        1 => Just(".".to_string()),
    ];
    (allele.clone(), allele, any::<bool>())
        .prop_map(|(a, b, phased)| format!("{a}{}{b}", if phased { '|' } else { '/' }))
}

fn line() -> impl Strategy<Value = String> {
    (
        prop_oneof![Just("chr1"), Just("2"), Just("chrX"), Just("MT")],
        1u64..300_000_000,
        bases(8),
        proptest::collection::vec(bases(8), 1..4),
        prop_oneof![Just(".".to_string()), (0u32..100_000).prop_map(|q| format!("{}", q))],
        prop_oneof![Just("PASS"), Just("."), Just("LowQual;q10")],
    )
        .prop_flat_map(|(chrom, pos, reference, alts, qual, filter)| {
            let n = alts.len();
            (Just((chrom, pos, reference, alts, qual, filter)), gt(n), gt(n))
        })
        .prop_map(|((chrom, pos, reference, alts, qual, filter), g1, g2)| {
            format!(
                "{chrom}\t{pos}\t.\t{reference}\t{}\t{qual}\t{filter}\tDP=5;FLAG\tGT:DP\t{g1}:3\t{g2}:.",
                alts.join(",")
            )
        })
}

proptest! {
    #[test]
    fn parse_then_serialize_is_identity(l in line()) {
        let p = parse_record(&l, 1, &header());
        let rec = p.record.expect("linha válida");
        prop_assert_eq!(rec.to_vcf_line(), l);
    }

    #[test]
    fn arbitrary_text_never_panics(s in "\\PC{0,200}") {
        let _ = parse_record(&s, 1, &header());
    }

    #[test]
    fn arbitrary_tabbed_text_never_panics(cols in proptest::collection::vec("[^\t\n]{0,12}", 0..14)) {
        let _ = parse_record(&cols.join("\t"), 1, &header());
    }
}

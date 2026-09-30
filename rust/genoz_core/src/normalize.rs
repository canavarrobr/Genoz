//! Normalização que não exige o genoma de referência:
//! divisão de multialélicos e aparo de bases redundantes.
//!
//! O alinhamento à esquerda (left-align) exige FASTA e fica para o Módulo 8.

use crate::header::{Number, VcfHeader};
use crate::record::{Genotype, Record, SplitOrigin, VariantKind};

/// Divide um registro com N ALTs em N registros bialélicos.
///
/// Convenção (a mesma do `bcftools norm -m-`): no registro do ALT `i`,
/// o alelo `i` vira `1`, a referência continua `0` e **os demais ALTs viram `0`**.
/// Ex.: GT `1/2` gera `1/0` no registro do ALT 1 e `0/1` no do ALT 2.
///
/// Campos `Number=A`, `R` e `G` (INFO e FORMAT) são recortados para o alelo;
/// campos `G` só são recortados para ploidia 1 e 2, caso contrário viram `.`.
pub fn split_multiallelic(rec: &Record, header: &VcfHeader) -> Vec<Record> {
    if rec.alts.len() <= 1 {
        return vec![rec.clone()];
    }
    let n = rec.alts.len() as u32;
    (1..=n)
        .map(|i| {
            let info = rec
                .info
                .iter()
                .map(|(k, v)| {
                    let number = header.info_def(k).map(|d| d.number).unwrap_or(Number::Unknown);
                    let v = v.as_ref().map(|v| subset_value(v, number, i, n, None));
                    (k.clone(), v)
                })
                .collect();
            let samples = rec
                .samples
                .iter()
                .map(|s| {
                    let gt = s.gt.as_ref().map(|g| remap_gt(g, i));
                    let ploidy = s.gt.as_ref().map(Genotype::ploidy);
                    let values = s
                        .values
                        .iter()
                        .enumerate()
                        .map(|(fi, v)| {
                            let key = &rec.format[fi];
                            if key == "GT" {
                                return gt.as_ref().map(|g| g.to_string()).unwrap_or_else(|| v.clone());
                            }
                            let number = header.format_def(key).map(|d| d.number).unwrap_or(Number::Unknown);
                            subset_value(v, number, i, n, ploidy)
                        })
                        .collect();
                    crate::record::SampleData { gt, values }
                })
                .collect();
            let mut out = Record {
                alts: vec![rec.alts[(i - 1) as usize].clone()],
                info,
                samples,
                split: Some(SplitOrigin { alt_index: i, n_alts: n }),
                ..rec.clone()
            };
            trim_alleles(&mut out);
            out
        })
        .collect()
}

fn remap_gt(g: &Genotype, target: u32) -> Genotype {
    Genotype {
        alleles: g.alleles.iter().map(|a| a.map(|x| if x == target { 1 } else { 0 })).collect(),
        phased: g.phased,
    }
}

fn subset_value(v: &str, number: Number, alt: u32, n_alts: u32, ploidy: Option<usize>) -> String {
    if v == "." {
        return v.to_string();
    }
    let parts: Vec<&str> = v.split(',').collect();
    let pick = |idx: &[usize]| -> String {
        idx.iter().map(|&i| parts.get(i).copied().unwrap_or(".")).collect::<Vec<_>>().join(",")
    };
    let a = alt as usize;
    let n = n_alts as usize;
    match number {
        Number::A if parts.len() == n => pick(&[a - 1]),
        Number::R if parts.len() == n + 1 => pick(&[0, a]),
        Number::G => {
            let diploid_len = (n + 1) * (n + 2) / 2;
            match ploidy {
                Some(1) if parts.len() == n + 1 => pick(&[0, a]),
                Some(2) | None if parts.len() == diploid_len => {
                    // Ordem VCF: índice de (j,k), j<=k, é k*(k+1)/2 + j.
                    let het = a * (a + 1) / 2;
                    pick(&[0, het, het + a])
                }
                _ => ".".to_string(),
            }
        }
        _ => v.to_string(),
    }
}

/// Remove bases repetidas no fim e no início dos alelos, mantendo uma base
/// âncora. Ex.: `REF=TCA ALT=TA` → `REF=TC ALT=T`; `REF=CAT ALT=CGT` → SNV `A>G` em pos+1.
/// Só atua em registros bialélicos não simbólicos.
pub fn trim_alleles(rec: &mut Record) {
    if rec.alts.len() != 1 {
        return;
    }
    let kind = VariantKind::classify(&rec.reference, &rec.alts[0]);
    if matches!(kind, VariantKind::Structural | VariantKind::Other) {
        return;
    }
    let mut r = rec.reference.as_bytes().to_vec();
    let mut a = rec.alts[0].as_bytes().to_vec();
    while r.len() > 1 && a.len() > 1 && r.last() == a.last() {
        r.pop();
        a.pop();
    }
    let mut shift = 0;
    while r.len() > 1 && a.len() > 1 && r[0] == a[0] {
        r.remove(0);
        a.remove(0);
        shift += 1;
    }
    rec.pos += shift;
    rec.reference = String::from_utf8(r).expect("bases ASCII");
    rec.alts[0] = String::from_utf8(a).expect("bases ASCII");
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::record::parse_record;

    fn header() -> VcfHeader {
        let mut h = VcfHeader::default();
        for l in [
            "##INFO=<ID=AF,Number=A,Type=Float,Description=\"\">",
            "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"\">",
            "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"\">",
            "##FORMAT=<ID=AD,Number=R,Type=Integer,Description=\"\">",
            "##FORMAT=<ID=PL,Number=G,Type=Integer,Description=\"\">",
        ] {
            h.push_meta_line(l);
        }
        h.samples = vec!["S1".into(), "S2".into()];
        h
    }

    #[test]
    fn split_rewrites_everything() {
        let h = header();
        // PL diploide com 3 alelos: 00,01,11,02,12,22
        let line = "1\t100\t.\tA\tG,T\t60\tPASS\tDP=20;AF=0.25,0.75\tGT:AD:PL\t1/2:0,5,6:90,50,40,30,0,20\t0|2:7,0,3:0,10,99,5,60,70";
        let rec = parse_record(line, 1, &h).record.unwrap();
        let out = split_multiallelic(&rec, &h);
        assert_eq!(out.len(), 2);
        assert_eq!(
            out[0].to_vcf_line(),
            "1\t100\t.\tA\tG\t60\tPASS\tDP=20;AF=0.25\tGT:AD:PL\t1/0:0,5:90,50,40\t0|0:7,0:0,10,99"
        );
        assert_eq!(
            out[1].to_vcf_line(),
            "1\t100\t.\tA\tT\t60\tPASS\tDP=20;AF=0.75\tGT:AD:PL\t0/1:0,6:90,30,20\t0|1:7,3:0,5,70"
        );
        assert_eq!(out[1].split, Some(SplitOrigin { alt_index: 2, n_alts: 2 }));
    }

    #[test]
    fn split_trims_redundant_bases() {
        let h = header();
        let rec = parse_record("1\t100\t.\tTCA\tT,TCACA\t.\t.\t.\tGT\t1/2\t0/0", 1, &h).record.unwrap();
        let out = split_multiallelic(&rec, &h);
        assert_eq!((out[0].pos, out[0].reference.as_str(), out[0].alts[0].as_str()), (100, "TCA", "T"));
        assert_eq!((out[1].pos, out[1].reference.as_str(), out[1].alts[0].as_str()), (100, "T", "TCA"));
    }

    #[test]
    fn trim_mnv_to_snv() {
        let h = header();
        let mut rec = parse_record("1\t100\t.\tCAT\tCGT\t.\t.\t.\tGT\t0/1\t0/0", 1, &h).record.unwrap();
        trim_alleles(&mut rec);
        assert_eq!((rec.pos, rec.reference.as_str(), rec.alts[0].as_str()), (101, "A", "G"));
    }

    #[test]
    fn biallelic_is_untouched() {
        let h = header();
        let rec = parse_record("1\t100\t.\tA\tG\t.\t.\t.\tGT\t0/1\t./.", 1, &h).record.unwrap();
        assert_eq!(split_multiallelic(&rec, &h), vec![rec]);
    }

    #[test]
    fn haploid_pl() {
        let h = header();
        let rec = parse_record("X\t100\t.\tA\tG,T\t.\t.\t.\tGT:PL\t2:50,40,0\t0:0,30,40", 1, &h).record.unwrap();
        let out = split_multiallelic(&rec, &h);
        assert_eq!(out[1].samples[0].values, ["1", "50,0"]);
        assert_eq!(out[0].samples[0].values, ["0", "50,40"]);
    }
}

//! Validação dos campos INFO, FORMAT e FILTER contra as definições do cabeçalho
//! (VCFv4.5.pdf, seções 1.4.2–1.4.4 e 1.6.2).
//!
//! Tudo aqui gera **avisos**, não erros: arquivos reais frequentemente usam
//! campos não declarados, e o dado continua utilizável. Cada combinação
//! (problema, campo) é avisada uma única vez por arquivo.

use std::collections::HashSet;

use crate::header::{FieldDef, Number, VcfHeader};
use crate::reader::{Issue, IssueCode};
use crate::record::Record;

/// Filtros reservados que não precisam de declaração.
const RESERVED_FILTERS: &[&str] = &["PASS"];

#[derive(Debug, Default)]
pub struct FieldValidator {
    warned: HashSet<(IssueCode, String)>,
}

impl FieldValidator {
    fn warn(&mut self, out: &mut Vec<Issue>, line: u64, code: IssueCode, key: &str, msg: String) {
        if self.warned.insert((code, key.to_string())) {
            out.push(Issue::warning(line, code, format!("{msg} (avisado só na primeira ocorrência)")));
        }
    }

    pub fn check(&mut self, rec: &Record, header: &VcfHeader) -> Vec<Issue> {
        let mut out = Vec::new();
        let n_alts = rec.alts.len();

        if let crate::record::Filter::Failed(names) = &rec.filter {
            for f in names {
                if !RESERVED_FILTERS.contains(&f.as_str()) && !header.filters.iter().any(|h| h == f) {
                    self.warn(
                        &mut out,
                        rec.line,
                        IssueCode::UndefinedFilter,
                        f,
                        format!("FILTER '{f}' não declarado no cabeçalho"),
                    );
                }
            }
        }

        for (key, value) in &rec.info {
            let Some(def) = header.info_def(key) else {
                self.warn(
                    &mut out,
                    rec.line,
                    IssueCode::UndefinedInfo,
                    key,
                    format!("INFO '{key}' não declarado no cabeçalho"),
                );
                continue;
            };
            match (def.ty.as_str(), value) {
                ("Flag", Some(_)) => self.warn(
                    &mut out,
                    rec.line,
                    IssueCode::FieldTypeMismatch,
                    key,
                    format!("INFO '{key}' é Flag e não deveria ter valor"),
                ),
                ("Flag", None) => {}
                (_, None) => self.warn(
                    &mut out,
                    rec.line,
                    IssueCode::FieldTypeMismatch,
                    key,
                    format!("INFO '{key}' aparece sem valor, mas não é Flag"),
                ),
                (_, Some(v)) => self.check_value(&mut out, rec.line, "INFO", def, v, n_alts, None),
            }
        }

        self.check_end_len(&mut out, rec);

        for (fi, key) in rec.format.iter().enumerate() {
            let Some(def) = header.format_def(key) else {
                self.warn(
                    &mut out,
                    rec.line,
                    IssueCode::UndefinedFormat,
                    key,
                    format!("FORMAT '{key}' não declarado no cabeçalho"),
                );
                continue;
            };
            if key == "GT" {
                continue;
            }
            for sample in &rec.samples {
                if let Some(v) = sample.values.get(fi) {
                    let ploidy = sample.gt.as_ref().map(|g| g.ploidy());
                    self.check_value(&mut out, rec.line, "FORMAT", def, v, n_alts, ploidy);
                }
            }
        }
        out
    }

    /// VCF 4.5: INFO/END é calculado como o maior fim entre as amostras
    /// (`POS + FORMAT/LEN - 1` nos blocos `<*>`). Avisa quando discordam.
    fn check_end_len(&mut self, out: &mut Vec<Issue>, rec: &Record) {
        let is_block = rec.alts.iter().any(|a| a == "<*>" || a == "<NON_REF>");
        let Some(li) = rec.format.iter().position(|k| k == "LEN") else { return };
        let Some(Some(end)) = rec.info_value("END") else { return };
        let Ok(end) = end.parse::<u64>() else { return };
        let max_end = rec
            .samples
            .iter()
            .filter_map(|s| s.values.get(li)?.parse::<u64>().ok())
            .map(|len| rec.pos + len.saturating_sub(1))
            .max();
        if let Some(m) = max_end.filter(|m| is_block && *m != end) {
            self.warn(
                out,
                rec.line,
                IssueCode::EndLenMismatch,
                "END/LEN",
                format!("INFO/END={end} não corresponde a POS+LEN-1={m}; o Genoz usa FORMAT/LEN (VCF 4.5)"),
            );
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn check_value(
        &mut self,
        out: &mut Vec<Issue>,
        line: u64,
        scope: &str,
        def: &FieldDef,
        value: &str,
        n_alts: usize,
        ploidy: Option<usize>,
    ) {
        if value == "." {
            return;
        }
        let parts: Vec<&str> = value.split(',').collect();
        let expected = match def.number {
            Number::Fixed(n) => Some(n as usize),
            Number::A => Some(n_alts),
            Number::R => Some(n_alts + 1),
            Number::G => match ploidy {
                Some(1) => Some(n_alts + 1),
                Some(2) | None => Some((n_alts + 1) * (n_alts + 2) / 2),
                _ => None,
            },
            Number::P => ploidy,
            Number::Unknown => None,
        };
        if let Some(n) = expected {
            if n > 0 && parts.len() != n {
                self.warn(
                    out,
                    line,
                    IssueCode::FieldCountMismatch,
                    &format!("{scope}/{}", def.id),
                    format!("{scope} '{}' deveria ter {n} valor(es), tem {}", def.id, parts.len()),
                );
            }
        }
        let bad = parts.iter().filter(|p| **p != ".").find(|p| match def.ty.as_str() {
            "Integer" => p.parse::<i64>().is_err(),
            "Float" => p.parse::<f64>().is_err(),
            "Character" => p.chars().count() != 1,
            _ => false,
        });
        if let Some(b) = bad {
            self.warn(
                out,
                line,
                IssueCode::FieldTypeMismatch,
                &format!("{scope}/{}", def.id),
                format!("{scope} '{}' é {} mas contém '{b}'", def.id, def.ty),
            );
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::record::parse_record;

    fn header() -> VcfHeader {
        let mut h = VcfHeader::default();
        for l in [
            "##FILTER=<ID=q10,Description=\"\">",
            "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"\">",
            "##INFO=<ID=AF,Number=A,Type=Float,Description=\"\">",
            "##INFO=<ID=DB,Number=0,Type=Flag,Description=\"\">",
            "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"\">",
            "##FORMAT=<ID=AD,Number=R,Type=Integer,Description=\"\">",
            "##FORMAT=<ID=PL,Number=G,Type=Integer,Description=\"\">",
            "##FORMAT=<ID=PSL,Number=P,Type=String,Description=\"\">",
        ] {
            h.push_meta_line(l);
        }
        h.samples = vec!["S".into()];
        h
    }

    fn codes(line: &str) -> Vec<IssueCode> {
        let h = header();
        let rec = parse_record(line, 1, &h).record.unwrap();
        FieldValidator::default().check(&rec, &h).into_iter().map(|i| i.code).collect()
    }

    #[test]
    fn clean_record_has_no_warnings() {
        assert!(
            codes("1\t1\t.\tA\tG,T\t.\tq10\tDP=5;AF=0.1,0.2;DB\tGT:AD:PL:PSL\t1/2:1,2,3:0,1,2,3,4,5:.,.").is_empty()
        );
    }

    #[test]
    fn each_problem_is_reported() {
        assert_eq!(
            codes("1\t1\t.\tA\tG\t.\tlow\tXX=1\tGT:ZZ\t0/1:3"),
            [IssueCode::UndefinedFilter, IssueCode::UndefinedInfo, IssueCode::UndefinedFormat]
        );
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\tDP=abc\tGT\t0/1"), [IssueCode::FieldTypeMismatch]);
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\tDB=1\tGT\t0/1"), [IssueCode::FieldTypeMismatch]);
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\tAF=0.1,0.2\tGT\t0/1"), [IssueCode::FieldCountMismatch]);
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\t.\tGT:PL\t0/1:1,2"), [IssueCode::FieldCountMismatch]);
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\t.\tGT:PL\t1:1,2"), Vec::<IssueCode>::new(), "haploide: 2 valores");
        assert_eq!(codes("1\t1\t.\tA\tG\t.\t.\t.\tGT:PSL\t0/1/1:.,."), [IssueCode::FieldCountMismatch]);
    }

    #[test]
    fn warned_once_per_field() {
        let h = header();
        let mut v = FieldValidator::default();
        let rec = parse_record("1\t1\t.\tA\tG\t.\t.\tXX=1\tGT\t0/1", 1, &h).record.unwrap();
        assert_eq!(v.check(&rec, &h).len(), 1);
        assert_eq!(v.check(&rec, &h).len(), 0);
    }
}

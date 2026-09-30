//! Filtros serializáveis (JSON), para salvar e reaplicar.
//!
//! Dois níveis, com semânticas diferentes:
//! - [`CallFilter`] é um **portão de qualidade** aplicado às chamadas antes da
//!   comparação. Uma chamada reprovada não some: vira "baixa qualidade" e a
//!   comparação a classifica como incerta, nunca como ausência.
//! - [`RowFilter`] seleciona linhas de um resultado já calculado (tabela).

use serde::{Deserialize, Serialize};

use crate::chrom::canonical_chrom;
use crate::compare::{Category, ComparisonRow, SideView};
use crate::record::{Filter, Record, VariantKind};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FieldScope {
    Info,
    Format,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Op {
    Eq,
    Ne,
    Gt,
    Ge,
    Lt,
    Le,
    Exists,
    Missing,
    Contains,
}

/// Condição sobre um campo INFO ou FORMAT (da amostra escolhida).
/// Em campos com vários valores (`1,2`), vale o primeiro — após a divisão de
/// multialélicos, campos `Number=A` já têm um único valor.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FieldCondition {
    pub scope: FieldScope,
    pub key: String,
    pub op: Op,
    #[serde(default)]
    pub value: Option<String>,
}

impl FieldCondition {
    fn eval(&self, raw: Option<Option<&str>>) -> bool {
        // raw: None = campo ausente; Some(None) = flag presente; Some(Some(v)) = valor.
        let value = match raw {
            None => return self.op == Op::Missing,
            Some(v) => v.map(|s| s.split(',').next().unwrap_or(s)),
        };
        if matches!(value, Some(".")) {
            return self.op == Op::Missing;
        }
        let want = self.value.as_deref().unwrap_or("");
        match self.op {
            Op::Exists => true,
            Op::Missing => false,
            Op::Contains => value.is_some_and(|v| v.contains(want)),
            Op::Eq => value.unwrap_or("") == want,
            Op::Ne => value.unwrap_or("") != want,
            Op::Gt | Op::Ge | Op::Lt | Op::Le => {
                let (Some(a), Ok(b)) = (value.and_then(|v| v.parse::<f64>().ok()), want.parse::<f64>()) else {
                    return false;
                };
                match self.op {
                    Op::Gt => a > b,
                    Op::Ge => a >= b,
                    Op::Lt => a < b,
                    _ => a <= b,
                }
            }
        }
    }
}

/// Portão de qualidade. Valor ausente com limite definido = reprovado
/// (se você pediu DP ≥ 10, uma chamada sem DP não comprova isso).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct CallFilter {
    /// Exigir FILTER = PASS (`.` também é aceito, pois indica filtros não aplicados).
    pub pass_only: bool,
    pub min_qual: Option<f64>,
    pub min_dp: Option<u32>,
    pub min_gq: Option<u32>,
    pub conditions: Vec<FieldCondition>,
}

impl CallFilter {
    pub fn is_empty(&self) -> bool {
        *self == CallFilter::default()
    }

    pub fn accepts(&self, rec: &Record, sample: Option<usize>) -> bool {
        if self.pass_only && matches!(rec.filter, Filter::Failed(_)) {
            return false;
        }
        if let Some(min) = self.min_qual {
            if !rec.qual.is_some_and(|q| q >= min) {
                return false;
            }
        }
        let format_raw = |key: &str| -> Option<Option<&str>> {
            let fi = rec.format.iter().position(|k| k == key)?;
            let v = rec.samples.get(sample?)?.values.get(fi)?;
            Some(Some(v.as_str()))
        };
        let number = |raw: Option<Option<&str>>| raw.flatten().and_then(|v| v.parse::<f64>().ok());
        if let Some(min) = self.min_dp {
            let dp = number(format_raw("DP")).or_else(|| number(rec.info_value("DP")));
            if !dp.is_some_and(|d| d >= f64::from(min)) {
                return false;
            }
        }
        if let Some(min) = self.min_gq {
            if !number(format_raw("GQ")).is_some_and(|g| g >= f64::from(min)) {
                return false;
            }
        }
        self.conditions.iter().all(|c| match c.scope {
            FieldScope::Info => c.eval(rec.info_value(&c.key)),
            FieldScope::Format => c.eval(format_raw(&c.key)),
        })
    }
}

/// Região 1-based inclusiva.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Region {
    pub chrom: String,
    pub start: u64,
    pub end: u64,
}

/// Interpreta `chr7:117559590`, `7:117,559,000-117,560,000`, `chrX:1.5M-2M` ou `chr7`.
pub fn parse_region(text: &str) -> Option<Region> {
    let text = text.trim();
    let (chrom, range) = match text.split_once(':') {
        Some((c, r)) => (c, Some(r)),
        None => (text, None),
    };
    if chrom.is_empty() {
        return None;
    }
    let parse = |s: &str| -> Option<u64> {
        let s = s.trim().replace(',', "");
        let lower = s.to_ascii_lowercase();
        let (digits, mult) = if let Some(d) = lower.strip_suffix('m') {
            (d.to_string(), 1_000_000.0)
        } else if let Some(d) = lower.strip_suffix('k') {
            (d.to_string(), 1_000.0)
        } else {
            (lower, 1.0)
        };
        let v: f64 = digits.parse().ok()?;
        (v >= 0.0).then(|| (v * mult).round() as u64)
    };
    let (start, end) = match range {
        // i64::MAX e não u64::MAX: o valor precisa caber em inteiros de JSON/Dart.
        None => (1, i64::MAX as u64),
        Some(r) => match r.split_once('-') {
            Some((a, b)) => (parse(a)?, parse(b)?),
            None => {
                let p = parse(r)?;
                (p, p)
            }
        },
    };
    (start <= end).then(|| Region { chrom: canonical_chrom(chrom), start: start.max(1), end })
}

/// Seleção de linhas de um resultado de comparação. Campos vazios = sem restrição.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct RowFilter {
    pub categories: Vec<Category>,
    pub kinds: Vec<VariantKind>,
    /// Nomes canônicos (`1`, `X`, `MT`).
    pub chroms: Vec<String>,
    pub region: Option<Region>,
    /// Trecho de ID (ex.: `rs123`).
    pub id_contains: Option<String>,
    /// Limites aplicados a cada lado que carrega a variante.
    pub min_qual: Option<f64>,
    pub min_dp: Option<u32>,
    pub min_gq: Option<u32>,
}

impl RowFilter {
    pub fn matches(&self, row: &ComparisonRow) -> bool {
        if !self.categories.is_empty() && !self.categories.contains(&row.category) {
            return false;
        }
        if !self.kinds.is_empty() && !self.kinds.contains(&row.kind) {
            return false;
        }
        if !self.chroms.is_empty() && !self.chroms.iter().any(|c| canonical_chrom(c) == row.chrom) {
            return false;
        }
        if let Some(r) = &self.region {
            if r.chrom != row.chrom || row.pos < r.start || row.pos > r.end {
                return false;
            }
        }
        if let Some(q) = &self.id_contains {
            let q = q.to_ascii_lowercase();
            if !row.ids.iter().any(|id| id.to_ascii_lowercase().contains(&q)) {
                return false;
            }
        }
        let carriers: Vec<&SideView> = [&row.a, &row.b].into_iter().filter(|s| s.state.is_carrier()).collect();
        let check = |get: &dyn Fn(&SideView) -> Option<f64>, min: f64| {
            carriers.iter().all(|s| get(s).is_some_and(|v| v >= min))
        };
        if let Some(min) = self.min_qual {
            if !check(&|s| s.qual, min) {
                return false;
            }
        }
        if let Some(min) = self.min_dp {
            if !check(&|s| s.dp.map(f64::from), f64::from(min)) {
                return false;
            }
        }
        if let Some(min) = self.min_gq {
            if !check(&|s| s.gq.map(f64::from), f64::from(min)) {
                return false;
            }
        }
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::header::VcfHeader;
    use crate::record::parse_record;

    fn rec(line: &str) -> Record {
        let h = VcfHeader { samples: vec!["S".into()], ..Default::default() };
        parse_record(line, 1, &h).record.unwrap()
    }

    #[test]
    fn quality_gate() {
        let r = rec("1\t10\t.\tA\tG\t35\tq10\tDP=20;AF=0.5;DB\tGT:DP:GQ\t0/1:12:.");
        assert!(CallFilter::default().accepts(&r, Some(0)));
        assert!(!CallFilter { pass_only: true, ..Default::default() }.accepts(&r, Some(0)));
        assert!(CallFilter { min_qual: Some(30.0), ..Default::default() }.accepts(&r, Some(0)));
        assert!(!CallFilter { min_qual: Some(40.0), ..Default::default() }.accepts(&r, Some(0)));
        // DP da amostra (12) tem prioridade sobre INFO DP (20).
        assert!(!CallFilter { min_dp: Some(15), ..Default::default() }.accepts(&r, Some(0)));
        // GQ ausente com limite = reprovado.
        assert!(!CallFilter { min_gq: Some(1), ..Default::default() }.accepts(&r, Some(0)));
        let cond = |scope, key: &str, op, value: Option<&str>| CallFilter {
            conditions: vec![FieldCondition { scope, key: key.into(), op, value: value.map(Into::into) }],
            ..Default::default()
        };
        assert!(cond(FieldScope::Info, "AF", Op::Ge, Some("0.5")).accepts(&r, Some(0)));
        assert!(cond(FieldScope::Info, "DB", Op::Exists, None).accepts(&r, Some(0)));
        assert!(cond(FieldScope::Info, "XX", Op::Missing, None).accepts(&r, Some(0)));
        assert!(cond(FieldScope::Format, "GQ", Op::Missing, None).accepts(&r, Some(0)));
        assert!(!cond(FieldScope::Info, "AF", Op::Lt, Some("abc")).accepts(&r, Some(0)));
    }

    #[test]
    fn regions() {
        assert_eq!(
            parse_region("chr7:117559590"),
            Some(Region { chrom: "7".into(), start: 117_559_590, end: 117_559_590 })
        );
        assert_eq!(
            parse_region("7:117,559,000-117,560,000"),
            Some(Region { chrom: "7".into(), start: 117_559_000, end: 117_560_000 })
        );
        assert_eq!(parse_region("chrX:1.5M-2M"), Some(Region { chrom: "X".into(), start: 1_500_000, end: 2_000_000 }));
        assert_eq!(parse_region("chrM").unwrap().end, i64::MAX as u64);
        assert_eq!(parse_region("1:10-5"), None);
        assert_eq!(parse_region(":5"), None);
    }

    #[test]
    fn filters_round_trip_as_json() {
        let f = RowFilter { categories: vec![Category::OnlyA], min_dp: Some(10), ..Default::default() };
        let json = serde_json::to_string(&f).unwrap();
        assert_eq!(serde_json::from_str::<RowFilter>(&json).unwrap(), f);
        let partial: RowFilter = serde_json::from_str(r#"{"kinds":["snv"]}"#).unwrap();
        assert_eq!(partial.kinds, [VariantKind::Snv]);
    }
}

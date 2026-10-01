//! Densidade de variantes ao longo do genoma (ideograma e mapa de densidade).
//!
//! Conta as linhas de um resultado de comparação por cromossomo, faixa de
//! tamanho fixo (bin) e categoria, respeitando o mesmo [`RowFilter`] da tabela.
//! A saída é pequena (alguns milhares de números) mesmo para milhões de linhas.

use std::collections::BTreeMap;
use std::io::{Read, Seek};

use serde::Serialize;

use crate::compare::Category;
use crate::filter::RowFilter;
use crate::results::ResultReader;
use crate::{GenozError, Result};

/// Tamanho de faixa padrão: 1 Mb (≈250 faixas no maior cromossomo humano).
pub const DEFAULT_BIN_SIZE: u64 = 1_000_000;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ChromDensity {
    /// Nome canônico (`1`, `X`, `MT`).
    pub chrom: String,
    /// Maior posição vista (serve de comprimento quando o build é desconhecido).
    pub max_pos: u64,
    pub total: u64,
    /// Contagem por faixa, para cada categoria presente. Todas as listas têm
    /// o mesmo tamanho: `(max_pos - 1) / bin_size + 1`.
    pub counts: BTreeMap<Category, Vec<u32>>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DensityMap {
    pub bin_size: u64,
    pub total: u64,
    /// Na ordem em que aparecem no resultado (ordem do genoma).
    pub chroms: Vec<ChromDensity>,
}

pub fn density<R: Read + Seek>(reader: &mut ResultReader<R>, filter: &RowFilter, bin_size: u64) -> Result<DensityMap> {
    if bin_size == 0 {
        return Err(GenozError::InvalidParam("o tamanho da faixa precisa ser maior que zero".into()));
    }
    // (cromossomo, posição, categoria) — guardar só o necessário.
    let mut order: Vec<String> = Vec::new();
    let mut points: BTreeMap<String, Vec<(u64, Category)>> = BTreeMap::new();
    reader.for_each(filter, |_, row| {
        if !points.contains_key(&row.chrom) {
            order.push(row.chrom.clone());
        }
        points.entry(row.chrom.clone()).or_default().push((row.pos, row.category));
        Ok(())
    })?;

    let mut total = 0u64;
    let chroms = order
        .into_iter()
        .map(|chrom| {
            let pts = points.remove(&chrom).unwrap_or_default();
            let max_pos = pts.iter().map(|(p, _)| *p).max().unwrap_or(1).max(1);
            let bins = ((max_pos - 1) / bin_size + 1) as usize;
            let mut counts: BTreeMap<Category, Vec<u32>> = BTreeMap::new();
            for (pos, cat) in &pts {
                let bin = (pos.max(&1) - 1) / bin_size;
                counts.entry(*cat).or_insert_with(|| vec![0; bins])[bin as usize] += 1;
            }
            total += pts.len() as u64;
            ChromDensity { chrom, max_pos, total: pts.len() as u64, counts }
        })
        .collect();
    Ok(DensityMap { bin_size, total, chroms })
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use super::*;
    use crate::compare::{ComparisonRow, SideState, SideView};
    use crate::record::VariantKind;
    use crate::results::ResultWriter;

    fn row(chrom: &str, pos: u64, category: Category) -> ComparisonRow {
        ComparisonRow {
            chrom: chrom.into(),
            pos,
            reference: "A".into(),
            alt: "G".into(),
            kind: VariantKind::Snv,
            category,
            ids: vec![],
            a: side(),
            b: side(),
        }
    }

    fn side() -> SideView {
        SideView { state: SideState::Carrier, gt: Some("0/1".into()), qual: None, dp: None, gq: None, filter: None }
    }

    fn store(rows: &[ComparisonRow]) -> ResultReader<Cursor<Vec<u8>>> {
        let mut w = ResultWriter::new(Vec::new()).unwrap();
        for r in rows {
            w.push(r).unwrap();
        }
        let (bytes, index) = w.finish().unwrap();
        ResultReader::new(Cursor::new(bytes), index)
    }

    #[test]
    fn conta_por_cromossomo_faixa_e_categoria() {
        let rows = [
            row("1", 1, Category::Shared),
            row("1", 1_000_000, Category::Shared),
            row("1", 1_000_001, Category::OnlyA),
            row("1", 2_500_000, Category::Shared),
            row("2", 10, Category::OnlyB),
        ];
        let d = density(&mut store(&rows), &RowFilter::default(), 1_000_000).unwrap();
        assert_eq!(d.total, 5);
        assert_eq!(d.chroms.iter().map(|c| c.chrom.as_str()).collect::<Vec<_>>(), ["1", "2"]);
        let c1 = &d.chroms[0];
        assert_eq!((c1.max_pos, c1.total), (2_500_000, 4));
        assert_eq!(c1.counts[&Category::Shared], vec![2, 0, 1], "1 e 1.000.000 caem na primeira faixa");
        assert_eq!(c1.counts[&Category::OnlyA], vec![0, 1, 0]);
        assert_eq!(d.chroms[1].counts[&Category::OnlyB], vec![1]);
        // A soma de todas as faixas é o total.
        let soma: u32 = d.chroms.iter().flat_map(|c| c.counts.values()).flatten().sum();
        assert_eq!(soma as u64, d.total);
    }

    #[test]
    fn respeita_o_filtro() {
        let rows = [row("1", 5, Category::Shared), row("1", 6, Category::OnlyA), row("3", 7, Category::OnlyA)];
        let filter = RowFilter { categories: vec![Category::OnlyA], ..Default::default() };
        let d = density(&mut store(&rows), &filter, 100).unwrap();
        assert_eq!(d.total, 2);
        assert!(!d.chroms[0].counts.contains_key(&Category::Shared));
    }

    #[test]
    fn faixa_zero_e_erro() {
        assert!(density(&mut store(&[]), &RowFilter::default(), 0).is_err());
        let vazio = density(&mut store(&[]), &RowFilter::default(), 10).unwrap();
        assert_eq!((vazio.total, vazio.chroms.len()), (0, 0));
    }
}

//! Harmonização de nomes de cromossomos.
//!
//! Arquivos do UCSC usam `chr1`/`chrM`; Ensembl/1000 Genomes usam `1`/`MT`.
//! O Genoz compara sempre pelo nome canônico: sem prefixo `chr`, com `MT`
//! para o mitocondrial e `X`/`Y` em maiúsculas.

use serde::Serialize;

pub fn canonical_chrom(raw: &str) -> String {
    let stripped =
        ["chr", "Chr", "CHR"].iter().find_map(|p| raw.strip_prefix(p)).filter(|s| !s.is_empty()).unwrap_or(raw);
    match stripped {
        "M" | "m" | "MT" | "mt" | "Mt" => "MT".to_string(),
        "x" => "X".to_string(),
        "y" => "Y".to_string(),
        other => other.to_string(),
    }
}

/// Chave de ordenação natural: 1..22, X, Y, MT e depois os demais em ordem alfabética.
pub fn chrom_sort_key(canonical: &str) -> (u32, String) {
    if let Ok(n) = canonical.parse::<u32>() {
        return (n, String::new());
    }
    let rank = match canonical {
        "X" => 1_000,
        "Y" => 1_001,
        "MT" => 1_002,
        _ => 2_000,
    };
    (rank, canonical.to_string())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ChromStyle {
    /// `chr1`, `chrX`… (UCSC)
    Ucsc,
    /// `1`, `X`… (Ensembl / NCBI)
    Ensembl,
    /// Os dois estilos no mesmo arquivo.
    Mixed,
    Unknown,
}

impl ChromStyle {
    pub fn label(self) -> &'static str {
        match self {
            ChromStyle::Ucsc => "UCSC (chr1, chrX)",
            ChromStyle::Ensembl => "Ensembl/NCBI (1, X)",
            ChromStyle::Mixed => "misto (chr1 e 1 no mesmo arquivo)",
            ChromStyle::Unknown => "indeterminado",
        }
    }
}

/// Acumula nomes observados e diz qual estilo o arquivo usa.
#[derive(Debug, Default, Clone)]
pub struct ChromStyleDetector {
    ucsc: u64,
    ensembl: u64,
}

impl ChromStyleDetector {
    pub fn observe(&mut self, raw: &str) {
        let lower = raw.to_ascii_lowercase();
        if lower.starts_with("chr") {
            self.ucsc += 1;
        } else if is_primary_canonical(raw) {
            self.ensembl += 1;
        }
    }

    pub fn style(&self) -> ChromStyle {
        match (self.ucsc > 0, self.ensembl > 0) {
            (true, true) => ChromStyle::Mixed,
            (true, false) => ChromStyle::Ucsc,
            (false, true) => ChromStyle::Ensembl,
            (false, false) => ChromStyle::Unknown,
        }
    }
}

fn is_primary_canonical(name: &str) -> bool {
    matches!(name, "X" | "Y" | "MT" | "M") || name.parse::<u32>().is_ok_and(|n| (1..=22).contains(&n))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_names() {
        for (raw, want) in [
            ("chr1", "1"),
            ("1", "1"),
            ("CHR22", "22"),
            ("chrX", "X"),
            ("x", "X"),
            ("chrM", "MT"),
            ("MT", "MT"),
            ("M", "MT"),
            ("chr1_KI270706v1_random", "1_KI270706v1_random"),
            ("GL000192.1", "GL000192.1"),
            ("chr", "chr"),
        ] {
            assert_eq!(canonical_chrom(raw), want, "{raw}");
        }
    }

    #[test]
    fn natural_order() {
        let mut v = vec!["X", "10", "2", "MT", "1", "Y", "GL1", "22"];
        v.sort_by_key(|c| chrom_sort_key(c));
        assert_eq!(v, ["1", "2", "10", "22", "X", "Y", "MT", "GL1"]);
    }

    #[test]
    fn style_detection() {
        let mut d = ChromStyleDetector::default();
        assert_eq!(d.style(), ChromStyle::Unknown);
        d.observe("chr1");
        assert_eq!(d.style(), ChromStyle::Ucsc);
        d.observe("2");
        assert_eq!(d.style(), ChromStyle::Mixed);
    }
}

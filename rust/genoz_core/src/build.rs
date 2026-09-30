//! Detecção do build de referência (GRCh37/hg19 × GRCh38/hg38).
//!
//! Evidência forte: comprimentos dos contigs no cabeçalho, que diferem entre
//! os builds. Evidência fraca: textos em `##reference` ou `assembly=`.
//! Comparar amostras de builds diferentes produz resultados errados, por isso
//! o comparador (Módulo 2) usa esta detecção para bloquear a comparação.

use serde::Serialize;

use crate::header::Contig;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum GenomeBuild {
    #[serde(rename = "GRCh37")]
    Grch37,
    #[serde(rename = "GRCh38")]
    Grch38,
    #[serde(rename = "unknown")]
    Unknown,
}

impl GenomeBuild {
    pub fn label(self) -> &'static str {
        match self {
            GenomeBuild::Grch37 => "GRCh37 (hg19)",
            GenomeBuild::Grch38 => "GRCh38 (hg38)",
            GenomeBuild::Unknown => "desconhecido",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Confidence {
    High,
    Low,
    None,
}

impl Confidence {
    pub fn label(self) -> &'static str {
        match self {
            Confidence::High => "alta",
            Confidence::Low => "baixa",
            Confidence::None => "nenhuma",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct BuildGuess {
    pub build: GenomeBuild,
    pub confidence: Confidence,
    pub evidence: Vec<String>,
}

/// (cromossomo canônico, comprimento GRCh37, comprimento GRCh38)
pub const CONTIG_LENGTHS: &[(&str, u64, u64)] = &[
    ("1", 249_250_621, 248_956_422),
    ("2", 243_199_373, 242_193_529),
    ("3", 198_022_430, 198_295_559),
    ("20", 63_025_520, 64_444_167),
    ("21", 48_129_895, 46_709_983),
    ("22", 51_304_566, 50_818_468),
    ("X", 155_270_560, 156_040_895),
    ("Y", 59_373_566, 57_227_415),
];

pub fn contig_length(chrom: &str, build: GenomeBuild) -> Option<u64> {
    CONTIG_LENGTHS.iter().find(|(c, _, _)| *c == chrom).and_then(|(_, l37, l38)| match build {
        GenomeBuild::Grch37 => Some(*l37),
        GenomeBuild::Grch38 => Some(*l38),
        GenomeBuild::Unknown => None,
    })
}

pub fn guess_build(contigs: &[Contig], reference: Option<&str>) -> BuildGuess {
    let mut evidence = Vec::new();
    let (mut hits37, mut hits38) = (0u32, 0u32);
    for contig in contigs {
        let Some(len) = contig.length else { continue };
        let Some((_, l37, l38)) = CONTIG_LENGTHS.iter().find(|(c, _, _)| *c == contig.canonical) else {
            continue;
        };
        if len == *l37 {
            hits37 += 1;
            evidence.push(format!("contig {} com comprimento {} = GRCh37", contig.id, len));
        } else if len == *l38 {
            hits38 += 1;
            evidence.push(format!("contig {} com comprimento {} = GRCh38", contig.id, len));
        }
    }
    match (hits37, hits38) {
        (a, 0) if a > 0 => return BuildGuess { build: GenomeBuild::Grch37, confidence: Confidence::High, evidence },
        (0, b) if b > 0 => return BuildGuess { build: GenomeBuild::Grch38, confidence: Confidence::High, evidence },
        (a, b) if a > 0 && b > 0 => {
            evidence.push("comprimentos de contig contraditórios".into());
            return BuildGuess { build: GenomeBuild::Unknown, confidence: Confidence::None, evidence };
        }
        _ => {}
    }

    let texts = reference.into_iter().chain(contigs.iter().filter_map(|c| c.assembly.as_deref()));
    let (mut t37, mut t38) = (false, false);
    for text in texts {
        let t = text.to_ascii_lowercase();
        if ["grch38", "hg38", "hs38"].iter().any(|k| t.contains(k)) {
            t38 = true;
            evidence.push(format!("texto do cabeçalho menciona GRCh38: {text}"));
        } else if ["grch37", "hg19", "hs37", "b37", "human_g1k_v37"].iter().any(|k| t.contains(k)) {
            t37 = true;
            evidence.push(format!("texto do cabeçalho menciona GRCh37: {text}"));
        }
    }
    let build = match (t37, t38) {
        (true, false) => GenomeBuild::Grch37,
        (false, true) => GenomeBuild::Grch38,
        _ => GenomeBuild::Unknown,
    };
    let confidence = if build == GenomeBuild::Unknown { Confidence::None } else { Confidence::Low };
    if build == GenomeBuild::Unknown && evidence.is_empty() {
        evidence.push("o cabeçalho não traz comprimentos de contig nem nome da referência".into());
    }
    BuildGuess { build, confidence, evidence }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn contig(id: &str, len: u64) -> Contig {
        Contig { id: id.into(), canonical: crate::chrom::canonical_chrom(id), length: Some(len), assembly: None }
    }

    #[test]
    fn by_length() {
        let g = guess_build(&[contig("chr1", 248_956_422)], None);
        assert_eq!((g.build, g.confidence), (GenomeBuild::Grch38, Confidence::High));
        let g = guess_build(&[contig("22", 51_304_566)], None);
        assert_eq!((g.build, g.confidence), (GenomeBuild::Grch37, Confidence::High));
    }

    #[test]
    fn by_text_is_low_confidence() {
        let g = guess_build(&[], Some("file:///ref/hg19.fa"));
        assert_eq!((g.build, g.confidence), (GenomeBuild::Grch37, Confidence::Low));
    }

    #[test]
    fn contradictory_is_unknown() {
        let g = guess_build(&[contig("1", 249_250_621), contig("2", 242_193_529)], None);
        assert_eq!(g.build, GenomeBuild::Unknown);
    }

    #[test]
    fn nothing_is_unknown() {
        let g = guess_build(&[], None);
        assert_eq!((g.build, g.confidence), (GenomeBuild::Unknown, Confidence::None));
    }
}

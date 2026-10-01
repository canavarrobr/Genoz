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

/// (cromossomo canônico, comprimento GRCh37, comprimento GRCh38) — Genome
/// Reference Consortium (assembly reports de GRCh37.p13 e GRCh38.p14).
/// MT (rCRS) tem o mesmo comprimento nos dois e por isso não serve de evidência.
pub const CONTIG_LENGTHS: &[(&str, u64, u64)] = &[
    ("1", 249_250_621, 248_956_422),
    ("2", 243_199_373, 242_193_529),
    ("3", 198_022_430, 198_295_559),
    ("4", 191_154_276, 190_214_555),
    ("5", 180_915_260, 181_538_259),
    ("6", 171_115_067, 170_805_979),
    ("7", 159_138_663, 159_345_973),
    ("8", 146_364_022, 145_138_636),
    ("9", 141_213_431, 138_394_717),
    ("10", 135_534_747, 133_797_422),
    ("11", 135_006_516, 135_086_622),
    ("12", 133_851_895, 133_275_309),
    ("13", 115_169_878, 114_364_328),
    ("14", 107_349_540, 107_043_718),
    ("15", 102_531_392, 101_991_189),
    ("16", 90_354_753, 90_338_345),
    ("17", 81_195_210, 83_257_441),
    ("18", 78_077_248, 80_373_285),
    ("19", 59_128_983, 58_617_616),
    ("20", 63_025_520, 64_444_167),
    ("21", 48_129_895, 46_709_983),
    ("22", 51_304_566, 50_818_468),
    ("X", 155_270_560, 156_040_895),
    ("Y", 59_373_566, 57_227_415),
    ("MT", 16_569, 16_569),
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
        if l37 == l38 {
            continue; // mesmo comprimento nos dois builds (MT): não diz nada
        }
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
    fn todos_os_cromossomos_tem_comprimento_nos_dois_builds() {
        for c in (1..=22).map(|n| n.to_string()).chain(["X", "Y", "MT"].map(String::from)) {
            assert!(contig_length(&c, GenomeBuild::Grch37).is_some(), "{c}");
            assert!(contig_length(&c, GenomeBuild::Grch38).is_some(), "{c}");
        }
        let total38: u64 = CONTIG_LENGTHS.iter().map(|(_, _, l)| l).sum();
        assert_eq!(total38, 3_088_286_401, "soma de 1-22, X, Y e MT no GRCh38");
    }

    #[test]
    fn mt_nao_e_evidencia() {
        let g = guess_build(&[contig("MT", 16_569)], None);
        assert_eq!(g.build, GenomeBuild::Unknown);
        let g = guess_build(&[contig("chrM", 16_569), contig("chr7", 159_345_973)], None);
        assert_eq!((g.build, g.confidence), (GenomeBuild::Grch38, Confidence::High));
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

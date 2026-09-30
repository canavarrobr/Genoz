//! Manifesto de reprodutibilidade (especificação v4, seção 20).
//!
//! O ID da análise é derivado do conteúdo: SHA-256 dos hashes das entradas +
//! parâmetros, formatado como UUID versão 8. A mesma análise refeita em outro
//! aparelho recebe o mesmo ID — e deve produzir as mesmas saídas.
//! O horário (`created_at`) é fornecido por quem chama: o núcleo não lê relógio.

use serde::{Deserialize, Serialize};

use crate::digest::sha256_bytes;

pub const MANIFEST_SCHEMA: u32 = 1;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InputRef {
    /// Papel na análise: `a`, `b`, `callable_a`...
    pub role: String,
    pub name: String,
    pub sha256: String,
    pub bytes: u64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub build: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sample: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OutputRef {
    pub name: String,
    pub sha256: String,
    pub bytes: u64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AnnotationSource {
    pub name: String,
    pub version: String,
    pub sha256: String,
    pub license: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Manifest {
    pub schema: u32,
    pub analysis_id: String,
    pub analysis_type: String,
    #[serde(default)]
    pub app_version: Option<String>,
    pub core_version: String,
    pub platform: String,
    pub created_at: String,
    pub inputs: Vec<InputRef>,
    pub parameters: serde_json::Value,
    #[serde(default)]
    pub annotation_sources: Vec<AnnotationSource>,
    pub outputs: Vec<OutputRef>,
    pub status: String,
    pub disclaimer: String,
}

pub const DISCLAIMER: &str = "Uso educacional e de pesquisa. Não é diagnóstico.";

/// ID determinístico no formato UUID (versão 8, variante RFC 9562).
pub fn content_id(analysis_type: &str, inputs: &[InputRef], parameters: &serde_json::Value) -> String {
    let mut material = format!("genoz/{analysis_type}\n");
    for i in inputs {
        material.push_str(&format!("{}={}\n", i.role, i.sha256));
    }
    material.push_str(&serde_json::to_string(parameters).expect("JSON"));
    let h = sha256_bytes(material.as_bytes());
    let mut hex: Vec<char> = h[..32].chars().collect();
    hex[12] = '8';
    let variant = u8::from_str_radix(&hex[16].to_string(), 16).expect("hex");
    hex[16] = char::from_digit(u32::from(8 | (variant & 0x3)), 16).expect("dígito");
    let s: String = hex.into_iter().collect();
    format!("{}-{}-{}-{}-{}", &s[0..8], &s[8..12], &s[12..16], &s[16..20], &s[20..32])
}

impl Manifest {
    pub fn new(
        analysis_type: &str,
        inputs: Vec<InputRef>,
        parameters: serde_json::Value,
        outputs: Vec<OutputRef>,
        platform: &str,
        created_at: &str,
    ) -> Self {
        Self {
            schema: MANIFEST_SCHEMA,
            analysis_id: content_id(analysis_type, &inputs, &parameters),
            analysis_type: analysis_type.into(),
            app_version: None,
            core_version: crate::CORE_VERSION.into(),
            platform: platform.into(),
            created_at: created_at.into(),
            inputs,
            parameters,
            annotation_sources: Vec::new(),
            outputs,
            status: "completed".into(),
            disclaimer: DISCLAIMER.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn input(role: &str, sha: &str) -> InputRef {
        InputRef { role: role.into(), name: "x.vcf".into(), sha256: sha.into(), bytes: 1, build: None, sample: None }
    }

    #[test]
    fn id_depends_on_content_only() {
        let p = serde_json::json!({"truth": null});
        let a = content_id("compare", &[input("a", "11"), input("b", "22")], &p);
        let mut renamed = input("a", "11");
        renamed.name = "outro_nome.vcf".into();
        assert_eq!(a, content_id("compare", &[renamed, input("b", "22")], &p));
        assert_ne!(a, content_id("compare", &[input("a", "22"), input("b", "11")], &p));
        assert_ne!(a, content_id("compare", &[input("a", "11"), input("b", "22")], &serde_json::json!({"truth": "a"})));
        assert_eq!(a.len(), 36);
        assert_eq!(&a[14..15], "8");
        assert!(matches!(&a[19..20], "8" | "9" | "a" | "b"));
    }
}

//! Módulo 12: família e populações. Só adapta `genoz_core::family`.

use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use genoz_core::io::BgzfWriter;
use genoz_core::build::GenomeBuild;
use genoz_core::compare::to_json_bytes;
use genoz_core::family::{analyze_family, manifest_parameters, FamilyOptions};
use genoz_core::manifest::{InputRef, Manifest, OutputRef};

/// Resultado (`familia.json`) e manifesto, em JSON.
pub struct FamilyRun {
    pub result_json: String,
    pub manifest_json: String,
}

fn run(
    source: impl std::io::Read,
    input_name: String,
    input_sha256: String,
    input_bytes: u64,
    options_json: &str,
    created_at: &str,
) -> Result<(Vec<u8>, Vec<u8>), String> {
    let opts: FamilyOptions = serde_json::from_str(options_json).map_err(|e| format!("opções inválidas: {e}"))?;
    let result = analyze_family(source, &opts).map_err(|e| e.user_message())?;
    let bytes = to_json_bytes(&result);
    let input =
        InputRef { role: "a".into(), name: input_name, sha256: input_sha256, bytes: input_bytes, build: None, sample: None };
    let output = OutputRef {
        name: "familia.json".into(),
        sha256: genoz_core::digest::sha256_bytes(&bytes),
        bytes: bytes.len() as u64,
    };
    let platform = format!("app-{}-{}", std::env::consts::OS, std::env::consts::ARCH);
    let manifest =
        Manifest::new("family", vec![input], manifest_parameters(&opts), vec![output], &platform, created_at);
    Ok((bytes, to_json_bytes(&manifest)))
}

fn text(b: Vec<u8>) -> Result<String, String> {
    String::from_utf8(b).map_err(|e| e.to_string())
}

/// Analisa um VCF multiamostra do disco e grava `familia.json` e `manifest.json` em `out_dir`.
pub fn family_analyze_file(
    path: String,
    input_name: String,
    input_sha256: String,
    input_bytes: u64,
    options_json: String,
    out_dir: String,
    created_at: String,
) -> Result<FamilyRun, String> {
    let file = File::open(&path).map_err(|e| e.to_string())?;
    let (result, manifest) =
        run(BufReader::new(file), input_name, input_sha256, input_bytes, &options_json, &created_at)?;
    let out = Path::new(&out_dir);
    std::fs::create_dir_all(out).map_err(|e| e.to_string())?;
    std::fs::write(out.join("familia.json"), &result).map_err(|e| e.to_string())?;
    std::fs::write(out.join("manifest.json"), &manifest).map_err(|e| e.to_string())?;
    Ok(FamilyRun { result_json: text(result)?, manifest_json: text(manifest)? })
}

/// Web: o mesmo, na memória (o app grava os dois arquivos no OPFS).
pub fn family_analyze_bytes(
    data: Vec<u8>,
    input_name: String,
    input_sha256: String,
    options_json: String,
    created_at: String,
) -> Result<FamilyRun, String> {
    let len = data.len() as u64;
    let (result, manifest) = run(&data[..], input_name, input_sha256, len, &options_json, &created_at)?;
    Ok(FamilyRun { result_json: text(result)?, manifest_json: text(manifest)? })
}

/// Família FICTÍCIA (VCF multiamostra, BGZF) para experimentar o módulo.
pub fn synthetic_family_bytes(seed: u64) -> Result<Vec<u8>, String> {
    let mut w = BgzfWriter::new(Vec::new());
    genoz_core::synth::write_family_vcf(seed, GenomeBuild::Grch38, 4000, &mut w).map_err(|e| e.user_message())?;
    w.finish().map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disk_equals_memory() {
        let data = synthetic_family_bytes(2026).unwrap();
        let dir = std::env::temp_dir().join(format!("genoz_family_test_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("familia.vcf.gz");
        std::fs::write(&path, &data).unwrap();
        let opts = r#"{"trio":{"child":"FILHO","father":"PAI","mother":"MAE"}}"#;
        let disk = family_analyze_file(
            path.to_string_lossy().into(),
            "familia.vcf.gz".into(),
            "ab".repeat(32),
            data.len() as u64,
            opts.into(),
            dir.join("res").to_string_lossy().into(),
            "t".into(),
        )
        .unwrap();
        let mem = family_analyze_bytes(data, "familia.vcf.gz".into(), "ab".repeat(32), opts.into(), "t".into()).unwrap();
        assert_eq!(disk.result_json, mem.result_json);
        assert_eq!(disk.manifest_json, mem.manifest_json);
        assert!(disk.result_json.contains("\"de_novo_candidates\": 3"));
        assert_eq!(std::fs::read_to_string(dir.join("res/familia.json")).unwrap(), disk.result_json);
        assert!(family_analyze_bytes(b"lixo".to_vec(), "x".into(), "y".into(), "{}".into(), "t".into()).is_err());
        let _ = std::fs::remove_dir_all(&dir);
    }
}

//! Módulo 10: pacotes de anotação locais. Só adapta `genoz_core::annotation`.

use std::collections::HashMap;
use std::io::Read;
use std::path::Path;
use std::sync::{LazyLock, Mutex};

use genoz_core::annotation::{
    build_custom, build_genes_from_gtf, build_sites_from_vcf, clinvar_fields, open_package_bytes, open_package_dir,
    write_package_dir, BuiltPackage, PackageMeta,
};

use crate::annot_open::{Hit, MetaIn, Open, PackageOps, RecordOut, RowIn};

fn build_any<R: Read>(kind: &str, input: R, meta_json: &str, input_sha256: String) -> Result<BuiltPackage, String> {
    let m: MetaIn = serde_json::from_str(meta_json).map_err(|e| format!("metadados inválidos: {e}"))?;
    let meta = PackageMeta {
        id: m.id,
        name: m.name,
        build: m.build,
        source: m.source,
        source_url: m.source_url,
        version: m.version,
        date: m.date,
        license: m.license,
        license_url: m.license_url,
        citation: m.citation,
        disclaimer: m.disclaimer,
        input_sha256,
    };
    match kind {
        "gtf" => build_genes_from_gtf(input, meta),
        "clinvar" => build_sites_from_vcf(input, clinvar_fields(), meta),
        "custom" => build_custom(input, meta),
        other => return Err(format!("tipo de pacote desconhecido: {other}")),
    }
    .map_err(|e| e.user_message())
}

/// Resultado da construção: manifesto + problemas (linhas ignoradas).
pub struct BuildReport {
    pub manifest_json: String,
    pub issues_json: String,
    pub skipped: u64,
}

fn report(b: &BuiltPackage) -> BuildReport {
    BuildReport {
        manifest_json: serde_json::to_string(&b.manifest).expect("serializável"),
        issues_json: serde_json::to_string(&b.issues).expect("serializável"),
        skipped: b.skipped,
    }
}

/// Constrói um pacote a partir de um arquivo (`kind`: `gtf`, `clinvar` ou `custom`) e grava em `out_dir`.
pub fn annot_build(kind: String, input_path: String, out_dir: String, meta_json: String) -> Result<BuildReport, String> {
    let sha = genoz_core::digest::sha256_reader(std::fs::File::open(&input_path).map_err(|e| e.to_string())?)
        .map_err(|e| e.user_message())?
        .sha256;
    let file = std::fs::File::open(&input_path).map_err(|e| e.to_string())?;
    let built = build_any(&kind, file, &meta_json, sha)?;
    write_package_dir(Path::new(&out_dir), &built).map_err(|e| e.user_message())?;
    forget(&out_dir);
    Ok(report(&built))
}

/// Pacote construído em memória (Web): o app grava os três arquivos onde quiser.
pub struct BuiltBytes {
    pub report: BuildReport,
    pub records_bgz: Vec<u8>,
    pub index_json: Vec<u8>,
}

pub fn annot_build_bytes(kind: String, data: Vec<u8>, meta_json: String) -> Result<BuiltBytes, String> {
    let sha = genoz_core::digest::sha256_bytes(&data);
    let built = build_any(&kind, &data[..], &meta_json, sha)?;
    Ok(BuiltBytes {
        report: report(&built),
        index_json: serde_json::to_vec(&built.index).expect("serializável"),
        records_bgz: built.records_bgz,
    })
}

/// SHA-256 de um arquivo (conferir um download do catálogo).
pub fn sha256_file(path: String) -> Result<String, String> {
    Ok(genoz_core::digest::sha256_reader(std::fs::File::open(&path).map_err(|e| e.to_string())?)
        .map_err(|e| e.user_message())?
        .sha256)
}

pub fn sha256_of_bytes(data: Vec<u8>) -> String {
    genoz_core::digest::sha256_bytes(&data)
}

// ---------------------------------------------------------------------------
// Pacotes abertos (cache): por pasta (nativo) ou por chave (Web, carregados em memória)
// ---------------------------------------------------------------------------

static OPEN: LazyLock<Mutex<HashMap<String, Open>>> = LazyLock::new(|| Mutex::new(HashMap::new()));

fn forget(key: &str) {
    OPEN.lock().expect("lock").remove(key);
}

/// Esquece um pacote aberto (ao remover ou reinstalar).
#[flutter_rust_bridge::frb(sync)]
pub fn annot_forget(key: String) {
    forget(&key);
}

/// Carrega um pacote na memória (Web), identificado por `key`.
pub fn annot_load(key: String, manifest_json: Vec<u8>, index_json: Vec<u8>, records_bgz: Vec<u8>) -> Result<(), String> {
    let p = open_package_bytes(&manifest_json, &index_json, records_bgz).map_err(|e| e.user_message())?;
    OPEN.lock().expect("lock").insert(key, Open::Memory(p));
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn annot_is_loaded(key: String) -> bool {
    OPEN.lock().expect("lock").contains_key(&key)
}

fn with_package<T>(key: &str, f: impl FnOnce(&mut dyn PackageOps) -> T) -> Result<T, String> {
    let mut map = OPEN.lock().expect("lock");
    if !map.contains_key(key) {
        // Nativo: a chave é a pasta do pacote.
        let p = open_package_dir(Path::new(key)).map_err(|e| e.user_message())?;
        map.insert(key.to_string(), Open::Disk(p));
    }
    Ok(map.get_mut(key).expect("aberto").with(f))
}

/// Anota linhas (`[{"chrom","pos","ref","alt"}]`) com os pacotes indicados (pastas ou chaves).
/// Devolve, para cada linha, os pacotes com algum registro e os registros.
pub fn annot_annotate(packages: Vec<String>, rows_json: String) -> Result<String, String> {
    let rows: Vec<RowIn> = serde_json::from_str(&rows_json).map_err(|e| format!("linhas inválidas: {e}"))?;
    let mut out: Vec<Vec<Hit>> = (0..rows.len()).map(|_| Vec::new()).collect();
    for key in &packages {
        with_package(key, |p| -> Result<(), String> {
            let id = p.id();
            for (i, r) in rows.iter().enumerate() {
                let found = p.annotate(&r.chrom, r.pos, &r.reference, &r.alt).map_err(|e| e.user_message())?;
                if !found.is_empty() {
                    out[i].push(Hit { package: id.clone(), records: found.into_iter().map(RecordOut::from).collect() });
                }
            }
            Ok(())
        })??;
    }
    Ok(serde_json::to_string(&out).expect("serializável"))
}

/// Procura um nome (ex.: gene) num pacote. Devolve os registros em JSON.
pub fn annot_find_name(package: String, name: String) -> Result<String, String> {
    let found = with_package(&package, |p| p.find_name(&name))?.map_err(|e| e.user_message())?;
    let out: Vec<RecordOut> = found.into_iter().map(RecordOut::from).collect();
    Ok(serde_json::to_string(&out).expect("serializável"))
}

#[cfg(test)]
mod tests {
    use super::*;

    const GTF: &str = "chr13\tHAVANA\tgene\t32315508\t32400268\t.\t+\t.\tgene_id \"ENSG02\"; gene_type \"protein_coding\"; gene_name \"BRCA2\";\n";

    #[test]
    fn disco_e_memoria_dao_o_mesmo_resultado() {
        let meta = r#"{"id":"genes","name":"Genes","build":"GRCh38"}"#;
        let dir = std::env::temp_dir().join(format!("genoz_bridge_anot_{}", std::process::id()));
        let input = dir.with_extension("gtf");
        std::fs::write(&input, GTF).unwrap();
        let rep = annot_build("gtf".into(), input.to_string_lossy().into(), dir.to_string_lossy().into(), meta.into()).unwrap();
        assert!(rep.manifest_json.contains("\"GENCODE\"") || rep.manifest_json.contains("\"genes\""));

        let mem = annot_build_bytes("gtf".into(), GTF.as_bytes().to_vec(), meta.into()).unwrap();
        annot_load("mem".into(), mem.report.manifest_json.into_bytes(), mem.index_json, mem.records_bgz).unwrap();
        assert!(annot_is_loaded("mem".into()));

        let rows = r#"[{"chrom":"chr13","pos":32316000,"ref":"A","alt":"G"},{"chrom":"1","pos":5,"ref":"A","alt":"G"}]"#;
        let disk = annot_annotate(vec![dir.to_string_lossy().into()], rows.into()).unwrap();
        let memory = annot_annotate(vec!["mem".into()], rows.into()).unwrap();
        assert_eq!(disk, memory);
        assert!(disk.contains("BRCA2"));
        assert!(annot_find_name("mem".into(), "brca2".into()).unwrap().contains("32315508"));

        annot_forget("mem".into());
        annot_forget(dir.to_string_lossy().into());
        std::fs::remove_dir_all(&dir).ok();
        std::fs::remove_file(&input).ok();
    }
}

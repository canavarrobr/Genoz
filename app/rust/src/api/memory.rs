//! Funções por BYTES (Módulo 6): usadas no navegador, onde não existem
//! caminhos de arquivo. A lógica é a mesma das funções por caminho — só a
//! origem/destino dos dados muda —, então os resultados são idênticos byte a byte.

use std::collections::HashMap;
use std::io::{Cursor, Read};
use std::sync::{Arc, LazyLock, Mutex};

use genoz_core::build::GenomeBuild;
use genoz_core::call::SampleSelector;
use genoz_core::compare::{compare_to_store, to_json_bytes, CompareInput, CompareOptions};
use genoz_core::digest::{sha256_bytes, FileDigest};
use genoz_core::inspect::{inspect, InspectOptions};
use genoz_core::io::BgzfWriter;
use genoz_core::manifest::OutputRef;
use genoz_core::results::{export_rows, ExportFormat, ResultReader, RowIndex};
use genoz_core::synth::{write_synthetic_vcf, SynthParams};

use super::analysis::{forget_key, manifest_json, page_of, parse_filter, ResultPage};

/// Inspeciona um VCF já em memória e devolve o relatório em JSON (com SHA-256).
pub fn inspect_bytes(data: Vec<u8>) -> Result<String, String> {
    let digest = FileDigest { sha256: sha256_bytes(&data), bytes: data.len() as u64 };
    let mut report = inspect(&data[..], &InspectOptions { max_issues: 500 }).map_err(|e| e.user_message())?;
    report.digest = Some(digest);
    Ok(serde_json::to_string(&report).expect("relatório serializável"))
}

/// Um lado da comparação em memória.
pub struct MemorySide {
    pub display_name: String,
    pub sha256: String,
    pub sample: Option<String>,
    pub data: Vec<u8>,
}

/// Todos os arquivos de uma análise, para o app gravar onde quiser (OPFS na Web).
pub struct CompareOutputs {
    pub rows_bgz: Vec<u8>,
    pub rows_idx: Vec<u8>,
    pub summary_json: String,
    pub stats_a_json: String,
    pub stats_b_json: String,
    pub manifest_json: String,
}

fn output(name: &str, bytes: &[u8]) -> OutputRef {
    OutputRef { name: name.into(), sha256: sha256_bytes(bytes), bytes: bytes.len() as u64 }
}

/// Compara A × B em memória. Mesmo resultado (bytes) que `compare_files`.
pub fn compare_bytes(a: MemorySide, b: MemorySide, options_json: String, created_at: String) -> Result<CompareOutputs, String> {
    let opts: CompareOptions = serde_json::from_str(&options_json).map_err(|e| format!("opções inválidas: {e}"))?;
    let (data_a, data_b) = (Arc::new(a.data), Arc::new(b.data));
    let input = |label: &str, data: &Arc<Vec<u8>>, sample: &Option<String>| {
        let data = data.clone();
        CompareInput {
            label: label.into(),
            open: Box::new(move || Ok(Box::new(Cursor::new(SharedBytes(data.clone()))) as Box<dyn Read>)),
            sample: sample.clone().map_or(SampleSelector::First, SampleSelector::Name),
            callable: None,
        }
    };
    let (mut ia, mut ib) = (input("A", &data_a, &a.sample), input("B", &data_b, &b.sample));
    let stored = compare_to_store(&mut ia, &mut ib, &opts, Vec::new()).map_err(|e| e.user_message())?;
    let s = &stored.outcome.summary;
    let rows_bgz = stored.rows_out;
    let rows_idx = stored.index.to_bytes();
    let summary = to_json_bytes(s);
    let stats_a = to_json_bytes(&stored.outcome.stats_a);
    let stats_b = to_json_bytes(&stored.outcome.stats_b);
    let outputs = vec![
        output("rows.bgz", &rows_bgz),
        output("rows.idx", &rows_idx),
        output("summary.json", &summary),
        output("stats_a.json", &stats_a),
        output("stats_b.json", &stats_b),
    ];
    let manifest = manifest_json(
        (&a.display_name, &a.sha256, data_a.len() as u64, &a.sample),
        (&b.display_name, &b.sha256, data_b.len() as u64, &b.sample),
        s,
        &opts,
        outputs,
        &created_at,
    );
    let text = |v: Vec<u8>| String::from_utf8(v).expect("UTF-8");
    Ok(CompareOutputs {
        rows_bgz,
        rows_idx,
        summary_json: text(summary),
        stats_a_json: text(stats_a),
        stats_b_json: text(stats_b),
        manifest_json: text(manifest),
    })
}

/// Bytes compartilhados que o `Cursor` pode ler sem copiar.
#[derive(Clone)]
struct SharedBytes(Arc<Vec<u8>>);

impl AsRef<[u8]> for SharedBytes {
    fn as_ref(&self) -> &[u8] {
        &self.0
    }
}

type Loaded = (Arc<Vec<u8>>, RowIndex);

/// Resultados carregados na memória do núcleo (a tabela pagina sem reenviar bytes).
static LOADED: LazyLock<Mutex<HashMap<String, Loaded>>> = LazyLock::new(|| Mutex::new(HashMap::new()));

fn reader_for(key: &str) -> Result<ResultReader<Cursor<SharedBytes>>, String> {
    let guard = LOADED.lock().expect("lock");
    let (rows, index) = guard.get(key).ok_or_else(|| "resultado não carregado".to_string())?;
    Ok(ResultReader::new(Cursor::new(SharedBytes(rows.clone())), index.clone()))
}

fn mem_key(key: &str) -> String {
    format!("mem:{key}")
}

/// Carrega `rows.bgz` + `rows.idx` de uma análise para paginar e exportar.
pub fn result_load(key: String, rows_bgz: Vec<u8>, rows_idx: Vec<u8>) -> Result<(), String> {
    let index = RowIndex::from_bytes(&rows_idx).map_err(|e| e.user_message())?;
    LOADED.lock().expect("lock").insert(key, (Arc::new(rows_bgz), index));
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn result_is_loaded(key: String) -> bool {
    LOADED.lock().expect("lock").contains_key(&key)
}

/// Libera a memória de um resultado carregado.
#[flutter_rust_bridge::frb(sync)]
pub fn result_unload(key: String) {
    LOADED.lock().expect("lock").remove(&key);
    forget_key(&mem_key(&key));
}

/// Página de um resultado carregado (mesma lógica de `result_page`).
pub fn result_page_loaded(key: String, filter_json: String, start: u32, count: u32) -> Result<ResultPage, String> {
    let mut reader = reader_for(&key)?;
    page_of(&mem_key(&key), &mut reader, &filter_json, start, count)
}

pub struct ExportedBytes {
    pub data: Vec<u8>,
    pub rows: u64,
}

/// Exporta as linhas filtradas de um resultado carregado (`csv`, `tsv`, `json`, `vcf`).
pub fn export_loaded(
    key: String,
    filter_json: String,
    format: String,
    sample_a: String,
    sample_b: String,
) -> Result<ExportedBytes, String> {
    let filter = parse_filter(&filter_json)?;
    let format: ExportFormat =
        serde_json::from_value(serde_json::Value::String(format)).map_err(|_| "formato desconhecido".to_string())?;
    let mut reader = reader_for(&key)?;
    let mut data = Vec::new();
    let rows = export_rows(&mut reader, &filter, format, (&sample_a, &sample_b), &mut data).map_err(|e| e.user_message())?;
    Ok(ExportedBytes { data, rows })
}

/// VCF sintético (BGZF) em memória — o mesmo de `write_synthetic_example`.
pub fn synthetic_bytes(seed: u64, samples: u32, variants_per_chrom: u32) -> Result<Vec<u8>, String> {
    let params = SynthParams {
        seed,
        samples: (1..=samples.max(1)).map(|i| format!("EXEMPLO_{i}")).collect(),
        variants_per_chrom,
        build: GenomeBuild::Grch38,
        ..Default::default()
    };
    let mut w = BgzfWriter::new(Vec::new());
    write_synthetic_vcf(&params, &mut w).map_err(|e| e.user_message())?;
    w.finish().map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture(name: &str) -> Vec<u8> {
        let p = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/compare").join(name);
        std::fs::read(p).unwrap()
    }

    #[test]
    fn memory_compare_equals_cli_result() {
        let side = |name: &str| MemorySide {
            display_name: name.into(),
            sha256: sha256_bytes(&fixture(name)),
            sample: None,
            data: fixture(name),
        };
        let out = compare_bytes(side("pessoa_a.vcf"), side("pessoa_b.vcf"), "{}".into(), "t".into()).unwrap();
        // Mesmo hash fixo do teste do núcleo (rows + índice + resumo).
        let digest = sha256_bytes(&[out.rows_bgz.clone(), out.rows_idx.clone(), out.summary_json.clone().into_bytes()].concat());
        assert_eq!(digest, "b4d285566563faf250abef42a9e869abfcc7d2f380a81df2337d0f9a8cb75435");
        // Mesmo ID de análise da CLI e do Android.
        assert!(out.manifest_json.contains("\"analysis_id\": \"c7e0bc9d-f41f-8309-b678-5e20bea871b2\""));

        result_load("t1".into(), out.rows_bgz, out.rows_idx).unwrap();
        let page = result_page_loaded("t1".into(), r#"{"categories":["only_a"]}"#.into(), 0, 10).unwrap();
        assert_eq!(page.total, 4);
        let csv = export_loaded("t1".into(), "{}".into(), "csv".into(), "A".into(), "B".into()).unwrap();
        assert_eq!(csv.rows, 12);
        result_unload("t1".into());
        assert!(!result_is_loaded("t1".into()));
    }

    #[test]
    fn inspect_and_synthetic() {
        let data = synthetic_bytes(42, 2, 50).unwrap();
        let json = inspect_bytes(data.clone()).unwrap();
        assert!(json.contains(&sha256_bytes(&data)));
        assert!(json.contains("\"verdict\":\"valid\""));
    }
}

//! Funções por BYTES (Módulo 6): usadas no navegador, onde não existem
//! caminhos de arquivo. A lógica é a mesma das funções por caminho — só a
//! origem/destino dos dados muda —, então os resultados são idênticos byte a byte.

use std::collections::HashMap;
use std::io::{Cursor, Read};
use std::sync::{Arc, LazyLock, Mutex};

use genoz_core::build::GenomeBuild;
use genoz_core::call::SampleSelector;
use genoz_core::chip_compare::compare_chip_to_store;
use genoz_core::compare::{compare_to_store_with, to_json_bytes, CompareInput, CompareOptions};
use genoz_core::digest::{sha256_bytes, FileDigest};
use genoz_core::inspect::InspectOptions;
use genoz_core::io::BgzfWriter;
use genoz_core::manifest::OutputRef;
use genoz_core::results::{export_rows, ExportFormat, ResultReader, RowIndex};
use genoz_core::synth::{write_synthetic_vcf, SynthParams};

use super::analysis::{chip_input, density_of, forget_key, manifest_json, page_of, parse_filter, ResultPage};

/// Inspeciona um VCF já em memória e devolve o relatório em JSON (com SHA-256).
pub fn inspect_bytes(data: Vec<u8>) -> Result<String, String> {
    let digest = FileDigest { sha256: sha256_bytes(&data), bytes: data.len() as u64 };
    let (mut report, extra) = genoz_core::consumer::inspect_any(
        || Ok(Box::new(&data[..]) as Box<dyn Read>),
        &InspectOptions { max_issues: 500 },
    )
    .map_err(|e| e.user_message())?;
    report.digest = Some(digest);
    Ok(genoz_core::consumer::report_json(&report, &extra))
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
/// `reference`: FASTA opcional (normalização dos indels).
pub fn compare_bytes(
    a: MemorySide,
    b: MemorySide,
    reference: Option<MemorySide>,
    options_json: String,
    created_at: String,
) -> Result<CompareOutputs, String> {
    compare_memory(a, b, false, reference, options_json, created_at)
}

/// Chip × VCF em memória. Mesmo resultado (bytes) que `compare_chip_files`.
pub fn compare_chip_bytes(
    chip: MemorySide,
    vcf: MemorySide,
    reference: Option<MemorySide>,
    options_json: String,
    created_at: String,
) -> Result<CompareOutputs, String> {
    compare_memory(chip, vcf, true, reference, options_json, created_at)
}

fn compare_memory(
    a: MemorySide,
    b: MemorySide,
    chip_a: bool,
    reference: Option<MemorySide>,
    options_json: String,
    created_at: String,
) -> Result<CompareOutputs, String> {
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
    let mut ib = input("B", &data_b, &b.sample);
    let reference_len = reference.as_ref().map(|r| r.data.len() as u64);
    let mut fasta = match &reference {
        Some(r) => {
            let index = genoz_core::fasta::FastaIndex::build(&r.data[..]).map_err(|e| e.user_message())?;
            Some(genoz_core::fasta::IndexedFasta::new(Cursor::new(&r.data[..]), index))
        }
        None => None,
    };
    let seq = fasta.as_mut().map(|f| f as &mut dyn genoz_core::fasta::SequenceSource);
    let stored = if chip_a {
        let chip = chip_input(&data_a[..])?;
        compare_chip_to_store(chip, &mut ib, &opts, seq, Vec::new()).map_err(|e| e.user_message())?
    } else {
        let mut ia = input("A", &data_a, &a.sample);
        compare_to_store_with(&mut ia, &mut ib, &opts, seq, Vec::new()).map_err(|e| e.user_message())?
    };
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
        if chip_a { "compare_chip" } else { "compare" },
        (&a.display_name, &a.sha256, data_a.len() as u64, &a.sample),
        (&b.display_name, &b.sha256, data_b.len() as u64, &b.sample),
        reference.as_ref().map(|r| (r.display_name.as_str(), r.sha256.as_str(), reference_len.unwrap_or(0), &r.sample)),
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

/// Densidade de um resultado carregado (mesma lógica de `result_density`).
pub fn result_density_loaded(key: String, filter_json: String, bin_size: u64) -> Result<String, String> {
    let mut reader = reader_for(&key)?;
    density_of(&mut reader, &filter_json, bin_size)
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
        let out = compare_bytes(side("pessoa_a.vcf"), side("pessoa_b.vcf"), None, "{}".into(), "t".into()).unwrap();
        // Mesmo hash fixo do teste do núcleo (rows + índice + resumo).
        let digest = sha256_bytes(&[out.rows_bgz.clone(), out.rows_idx.clone(), out.summary_json.clone().into_bytes()].concat());
        assert_eq!(digest, "b4d285566563faf250abef42a9e869abfcc7d2f380a81df2337d0f9a8cb75435");
        // Mesmo ID de análise da CLI e do Android.
        assert!(out.manifest_json.contains("\"analysis_id\": \"c7e0bc9d-f41f-8309-b678-5e20bea871b2\""));

        let (rows_bgz, rows_idx) = (out.rows_bgz.clone(), out.rows_idx.clone());
        result_load("t1".into(), out.rows_bgz, out.rows_idx).unwrap();
        let page = result_page_loaded("t1".into(), r#"{"categories":["only_a"]}"#.into(), 0, 10).unwrap();
        assert_eq!(page.total, 4);
        let csv = export_loaded("t1".into(), "{}".into(), "csv".into(), "A".into(), "B".into()).unwrap();
        assert_eq!(csv.rows, 12);
        // Densidade: memória = arquivo, e soma = total de linhas.
        let mem = result_density_loaded("t1".into(), "{}".into(), 1_000_000).unwrap();
        let dir = std::env::temp_dir().join(format!("genoz_density_{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join("rows.bgz"), &rows_bgz).unwrap();
        std::fs::write(dir.join("rows.idx"), &rows_idx).unwrap();
        let disk = super::super::analysis::result_density(dir.to_string_lossy().into(), "{}".into(), 1_000_000).unwrap();
        std::fs::remove_dir_all(&dir).ok();
        assert_eq!(mem, disk);
        assert!(mem.contains("\"total\":12"), "{mem}");
        result_unload("t1".into());
        assert!(!result_is_loaded("t1".into()));
    }

    #[test]
    fn chip_em_memoria_tem_o_mesmo_id_da_cli() {
        let dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../test_fixtures/consumidor");
        let side = |name: &str| {
            let data = std::fs::read(dir.join(name)).unwrap();
            MemorySide { display_name: name.into(), sha256: sha256_bytes(&data), sample: None, data }
        };
        let id = |m: &str| -> String {
            let v: serde_json::Value = serde_json::from_str(m).unwrap();
            v["analysis_id"].as_str().unwrap().to_string()
        };
        let out = compare_chip_bytes(side("chip_23andme.txt"), side("pessoa_ficticia_grch37.vcf"), None, "{}".into(), "t".into())
            .unwrap();
        assert!(out.manifest_json.contains("\"compare_chip\""));
        assert!(out.summary_json.contains("\"chip\""));
        // Mesmo ID do `genoz-cli compare-chip` (sem e com FASTA).
        assert_eq!(id(&out.manifest_json), "b0cbdd59-a37a-8e74-8d73-24df662e9aed");
        let with_fasta = compare_chip_bytes(
            side("chip_23andme.txt"),
            side("pessoa_ficticia_grch37.vcf"),
            Some(side("referencia_chr1_trecho.fa")),
            "{}".into(),
            "t".into(),
        )
        .unwrap();
        assert!(with_fasta.manifest_json.contains("\"reference\""));
        assert_eq!(id(&with_fasta.manifest_json), "23828628-4d22-8479-ada1-9b0dbc3399d0");
        // O arquivo de chip também é reconhecido na inspeção.
        let report = inspect_bytes(side("chip_ancestrydna.txt").data).unwrap();
        assert!(report.contains("\"file_format\":\"chip:AncestryDNA\""));
        let report = inspect_bytes(side("referencia_chr1_trecho.fa").data).unwrap();
        assert!(report.contains("\"file_format\":\"fasta\""));
    }

    #[test]
    fn inspect_and_synthetic() {
        let data = synthetic_bytes(42, 2, 50).unwrap();
        let json = inspect_bytes(data.clone()).unwrap();
        assert!(json.contains(&sha256_bytes(&data)));
        assert!(json.contains("\"verdict\":\"valid\""));
    }
}

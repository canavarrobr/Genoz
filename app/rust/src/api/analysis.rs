//! Módulo 4: comparação A × B, páginas do resultado e exportação.
//! Como no resto da ponte, só adapta o `genoz_core`.

use std::fs::File;
use std::io::{BufReader, BufWriter, Read, Seek};
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, LazyLock, Mutex};

use genoz_core::call::SampleSelector;
use genoz_core::chip_compare::{compare_chip_to_store, ChipInput};
use genoz_core::compare::{compare_to_store_with, to_json_bytes, CompareInput, CompareOptions};
use genoz_core::consumer::read_chip;
use genoz_core::filter::RowFilter;
use genoz_core::manifest::{InputRef, Manifest, OutputRef};
use genoz_core::results::{export_rows as export, ExportFormat, ResultReader, RowIndex};

use super::genoz::{register, unregister, PROGRESS_STEP};
use crate::frb_generated::StreamSink;

pub enum CompareEvent {
    Progress {
        bytes_done: u64,
        bytes_total: u64,
    },
    /// Resumo e manifesto em JSON (mesmo formato do `genoz-cli compare`).
    Done {
        summary_json: String,
        manifest_json: String,
    },
    Failed {
        message: String,
    },
    Cancelled,
}

/// Uma das entradas da comparação, como o app a conhece.
pub struct CompareSide {
    pub path: String,
    /// Nome do arquivo mostrado ao usuário (vai para o manifesto).
    pub display_name: String,
    /// SHA-256 já calculado na importação (evita reler o arquivo).
    pub sha256: String,
    pub bytes: u64,
    /// `None` = primeira amostra do arquivo.
    pub sample: Option<String>,
}

/// Soma os bytes lidos num contador compartilhado e respeita o cancelamento.
struct CountingReader<R> {
    inner: R,
    counter: Arc<AtomicU64>,
    last: Arc<AtomicU64>,
    total: u64,
    cancel: Arc<AtomicBool>,
    sink: Arc<StreamSink<CompareEvent>>,
}

impl<R: Read> Read for CountingReader<R> {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        if self.cancel.load(Ordering::SeqCst) {
            return Err(std::io::Error::other("cancelado pelo usuário"));
        }
        let n = self.inner.read(buf)?;
        let done = self.counter.fetch_add(n as u64, Ordering::Relaxed) + n as u64;
        if done.saturating_sub(self.last.load(Ordering::Relaxed)) >= PROGRESS_STEP {
            self.last.store(done, Ordering::Relaxed);
            let _ = self.sink.add(CompareEvent::Progress {
                bytes_done: done,
                bytes_total: self.total,
            });
        }
        Ok(n)
    }
}

fn output_ref(dir: &Path, name: &str) -> Result<OutputRef, String> {
    let file = File::open(dir.join(name)).map_err(|e| e.to_string())?;
    let d = genoz_core::digest::sha256_reader(file).map_err(|e| e.user_message())?;
    Ok(OutputRef {
        name: name.into(),
        sha256: d.sha256,
        bytes: d.bytes,
    })
}

fn write_output(dir: &Path, name: &str, bytes: &[u8]) -> Result<OutputRef, String> {
    std::fs::write(dir.join(name), bytes).map_err(|e| format!("falha ao gravar {name}: {e}"))?;
    output_ref(dir, name)
}

#[allow(clippy::too_many_arguments)]
fn run_compare(
    a: &CompareSide,
    b: &CompareSide,
    chip_a: bool,
    reference: Option<&CompareSide>,
    options_json: &str,
    out_dir: &Path,
    created_at: &str,
    cancel: &Arc<AtomicBool>,
    sink: &Arc<StreamSink<CompareEvent>>,
) -> Result<(String, String), String> {
    let opts: CompareOptions =
        serde_json::from_str(options_json).map_err(|e| format!("opções inválidas: {e}"))?;
    // Varredura de ordem + leitura principal: cada arquivo é lido cerca de duas vezes.
    let total = 2 * (a.bytes + b.bytes);
    let counter = Arc::new(AtomicU64::new(0));
    let last = Arc::new(AtomicU64::new(0));
    let input = |label: &str, side: &CompareSide| {
        let (path, counter, last, cancel, sink) = (
            side.path.clone(),
            counter.clone(),
            last.clone(),
            cancel.clone(),
            sink.clone(),
        );
        CompareInput {
            label: label.into(),
            open: Box::new(move || {
                Ok(Box::new(CountingReader {
                    inner: File::open(&path)?,
                    counter: counter.clone(),
                    last: last.clone(),
                    total,
                    cancel: cancel.clone(),
                    sink: sink.clone(),
                }) as Box<dyn Read>)
            }),
            sample: side
                .sample
                .clone()
                .map_or(SampleSelector::First, SampleSelector::Name),
            callable: None,
        }
    };
    let mut ib = input("B", b);
    let mut fasta = match reference {
        Some(r) => Some(
            genoz_core::fasta::open_fasta(Path::new(&r.path))
                .map_err(|e| e.user_message())?
                .0,
        ),
        None => None,
    };
    let seq = fasta
        .as_mut()
        .map(|f| f as &mut dyn genoz_core::fasta::SequenceSource);

    std::fs::create_dir_all(out_dir)
        .map_err(|e| format!("não foi possível criar a pasta da análise: {e}"))?;
    let rows = BufWriter::new(File::create(out_dir.join("rows.bgz")).map_err(|e| e.to_string())?);
    let stored = if chip_a {
        let chip = read_chip_file(&a.path)?;
        compare_chip_to_store(chip, &mut ib, &opts, seq, rows).map_err(|e| e.user_message())?
    } else {
        let mut ia = input("A", a);
        compare_to_store_with(&mut ia, &mut ib, &opts, seq, rows).map_err(|e| e.user_message())?
    };
    drop(stored.rows_out);
    let s = &stored.outcome.summary;

    let summary_json = to_json_bytes(s);
    let outputs = vec![
        output_ref(out_dir, "rows.bgz")?,
        write_output(out_dir, "rows.idx", &stored.index.to_bytes())?,
        write_output(out_dir, "summary.json", &summary_json)?,
        write_output(
            out_dir,
            "stats_a.json",
            &to_json_bytes(&stored.outcome.stats_a),
        )?,
        write_output(
            out_dir,
            "stats_b.json",
            &to_json_bytes(&stored.outcome.stats_b),
        )?,
    ];
    let manifest_json = manifest_json(
        if chip_a { "compare_chip" } else { "compare" },
        side_ref(a),
        side_ref(b),
        reference.map(side_ref),
        s,
        &opts,
        outputs,
        created_at,
    );
    std::fs::write(out_dir.join("manifest.json"), &manifest_json).map_err(|e| e.to_string())?;
    Ok((
        String::from_utf8(summary_json).expect("UTF-8"),
        String::from_utf8(manifest_json).expect("UTF-8"),
    ))
}

fn side_ref(x: &CompareSide) -> SideRef<'_> {
    (&x.display_name, &x.sha256, x.bytes, &x.sample)
}

/// Lê um arquivo de chip (23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA).
pub(crate) fn chip_input<R: Read>(source: R) -> Result<ChipInput, String> {
    let (header, calls, rejected_lines) = read_chip(source)
        .map_err(|e| e.user_message())?
        .ok_or_else(|| "o arquivo A não é um arquivo de chip reconhecido".to_string())?;
    Ok(ChipInput {
        label: "A".into(),
        header,
        calls,
        rejected_lines,
    })
}

fn read_chip_file(path: &str) -> Result<ChipInput, String> {
    chip_input(File::open(path).map_err(|e| format!("não foi possível abrir o chip: {e}"))?)
}

/// (nome, sha256, bytes, amostra) de um lado da comparação.
pub(crate) type SideRef<'a> = (&'a str, &'a str, u64, &'a Option<String>);

/// Manifesto da comparação. Única montagem para o caminho por arquivo e o por bytes,
/// para que o ID da análise seja o mesmo em todas as plataformas.
#[allow(clippy::too_many_arguments)]
pub(crate) fn manifest_json(
    analysis_type: &str,
    a: SideRef,
    b: SideRef,
    reference: Option<SideRef>,
    s: &genoz_core::compare::CompareSummary,
    opts: &CompareOptions,
    outputs: Vec<OutputRef>,
    created_at: &str,
) -> Vec<u8> {
    let input_ref = |role: &str, side: SideRef, info: &genoz_core::compare::SideInfo| InputRef {
        role: role.into(),
        name: side.0.to_string(),
        sha256: side.1.to_string(),
        bytes: side.2,
        build: Some(info.build.build.label().into()),
        sample: info.sample.clone(),
    };
    let mut inputs = vec![input_ref("a", a, &s.a), input_ref("b", b, &s.b)];
    // FASTA usado na normalização / no chip × VCF: entra no ID da análise.
    if let Some(r) = reference {
        inputs.push(InputRef {
            role: "reference".into(),
            name: r.0.to_string(),
            sha256: r.1.to_string(),
            bytes: r.2,
            build: None,
            sample: None,
        });
    }
    let selector = |s: &Option<String>| s.clone().map_or(SampleSelector::First, SampleSelector::Name);
    let parameters = genoz_core::compare::manifest_parameters(opts, &selector(a.3), &selector(b.3));
    let platform = format!("app-{}-{}", std::env::consts::OS, std::env::consts::ARCH);
    to_json_bytes(&Manifest::new(analysis_type, inputs, parameters, outputs, &platform, created_at))
}

/// Compara A × B e grava o resultado em `out_dir`. `options_json` segue
/// `genoz_core::compare::CompareOptions`. Em falha ou cancelamento a pasta é apagada.
#[allow(clippy::too_many_arguments)]
pub fn compare_files(
    a: CompareSide,
    b: CompareSide,
    reference: Option<CompareSide>,
    options_json: String,
    out_dir: String,
    created_at: String,
    job_id: String,
    sink: StreamSink<CompareEvent>,
) {
    run_compare_job(a, b, false, reference, options_json, out_dir, created_at, job_id, sink);
}

/// Chip de consumidor (A) × uma amostra de VCF (B), restrito aos sítios do chip.
/// O FASTA (opcional) permite julgar homozigotos sem registro no VCF.
#[allow(clippy::too_many_arguments)]
pub fn compare_chip_files(
    chip: CompareSide,
    vcf: CompareSide,
    reference: Option<CompareSide>,
    options_json: String,
    out_dir: String,
    created_at: String,
    job_id: String,
    sink: StreamSink<CompareEvent>,
) {
    run_compare_job(chip, vcf, true, reference, options_json, out_dir, created_at, job_id, sink);
}

#[allow(clippy::too_many_arguments)]
fn run_compare_job(
    a: CompareSide,
    b: CompareSide,
    chip_a: bool,
    reference: Option<CompareSide>,
    options_json: String,
    out_dir: String,
    created_at: String,
    job_id: String,
    sink: StreamSink<CompareEvent>,
) {
    let cancel = register(&job_id);
    let sink = Arc::new(sink);
    let dir = Path::new(&out_dir);
    let event = match run_compare(
        &a,
        &b,
        chip_a,
        reference.as_ref(),
        &options_json,
        dir,
        &created_at,
        &cancel,
        &sink,
    ) {
        Ok((summary_json, manifest_json)) => CompareEvent::Done {
            summary_json,
            manifest_json,
        },
        Err(_) if cancel.load(Ordering::SeqCst) => {
            let _ = std::fs::remove_dir_all(dir);
            CompareEvent::Cancelled
        }
        Err(message) => {
            let _ = std::fs::remove_dir_all(dir);
            CompareEvent::Failed { message }
        }
    };
    unregister(&job_id);
    let _ = sink.add(event);
}

pub struct ResultPage {
    /// Total de linhas (com o filtro aplicado).
    pub total: u32,
    /// Linhas da página em JSON (lista de `ComparisonRow`).
    pub rows_json: String,
}

fn open_result(out_dir: &str) -> Result<ResultReader<BufReader<File>>, String> {
    let dir = Path::new(out_dir);
    let idx = std::fs::read(dir.join("rows.idx"))
        .map_err(|e| format!("resultado não encontrado: {e}"))?;
    let index = RowIndex::from_bytes(&idx).map_err(|e| e.user_message())?;
    let rows =
        File::open(dir.join("rows.bgz")).map_err(|e| format!("resultado não encontrado: {e}"))?;
    Ok(ResultReader::new(BufReader::new(rows), index))
}

type CacheKey = (String, String);
type FilterCache = Mutex<Vec<(CacheKey, Arc<Vec<u32>>)>>;

/// Índices de linhas filtradas mais recentes (trocar de página não reprocessa).
static FILTER_CACHE: LazyLock<FilterCache> = LazyLock::new(|| Mutex::new(Vec::new()));
const FILTER_CACHE_SIZE: usize = 6;

pub(crate) fn parse_filter(filter_json: &str) -> Result<RowFilter, String> {
    serde_json::from_str(filter_json).map_err(|e| format!("filtro inválido: {e}"))
}

fn matching<R: Read + Seek>(
    result_key: &str,
    filter: &RowFilter,
    reader: &mut ResultReader<R>,
) -> Result<Arc<Vec<u32>>, String> {
    let key = (
        result_key.to_string(),
        serde_json::to_string(filter).expect("JSON"),
    );
    if let Some((_, v)) = FILTER_CACHE
        .lock()
        .expect("lock")
        .iter()
        .find(|(k, _)| *k == key)
    {
        return Ok(v.clone());
    }
    let v = Arc::new(reader.matching_rows(filter).map_err(|e| e.user_message())?);
    let mut cache = FILTER_CACHE.lock().expect("lock");
    if cache.len() >= FILTER_CACHE_SIZE {
        cache.remove(0);
    }
    cache.push((key, v.clone()));
    Ok(v)
}

/// Página do resultado. Com filtro vazio (`{}`) lê direto pelo índice do arquivo;
/// com filtro, calcula uma vez as linhas que passam e guarda em cache.
pub fn result_page(
    out_dir: String,
    filter_json: String,
    start: u32,
    count: u32,
) -> Result<ResultPage, String> {
    let mut reader = open_result(&out_dir)?;
    page_of(&out_dir, &mut reader, &filter_json, start, count)
}

/// Densidade de variantes por cromossomo/faixa/categoria (JSON de `genoz_core::density`).
pub fn result_density(out_dir: String, filter_json: String, bin_size: u64) -> Result<String, String> {
    let mut reader = open_result(&out_dir)?;
    density_of(&mut reader, &filter_json, bin_size)
}

pub(crate) fn density_of<R: Read + Seek>(
    reader: &mut ResultReader<R>,
    filter_json: &str,
    bin_size: u64,
) -> Result<String, String> {
    let filter = parse_filter(filter_json)?;
    let map = genoz_core::density::density(reader, &filter, bin_size).map_err(|e| e.user_message())?;
    serde_json::to_string(&map).map_err(|e| e.to_string())
}

/// Página de qualquer resultado (arquivo ou memória). `result_key` identifica o
/// resultado no cache de linhas filtradas.
pub(crate) fn page_of<R: Read + Seek>(
    result_key: &str,
    reader: &mut ResultReader<R>,
    filter_json: &str,
    start: u32,
    count: u32,
) -> Result<ResultPage, String> {
    let filter = parse_filter(filter_json)?;
    let (total, rows) = if filter == RowFilter::default() {
        let total = reader.total_rows() as u32;
        (
            total,
            reader
                .page(u64::from(start), count as usize)
                .map_err(|e| e.user_message())?,
        )
    } else {
        let m = matching(result_key, &filter, reader)?;
        let from = (start as usize).min(m.len());
        let to = (from + count as usize).min(m.len());
        (
            m.len() as u32,
            reader.rows_at(&m[from..to]).map_err(|e| e.user_message())?,
        )
    };
    Ok(ResultPage {
        total,
        rows_json: serde_json::to_string(&rows).expect("JSON"),
    })
}

/// Esquece os índices em cache de um resultado (ao apagar a análise).
#[flutter_rust_bridge::frb(sync)]
pub fn forget_result(out_dir: String) {
    forget_key(&out_dir);
}

pub(crate) fn forget_key(out_dir: &str) {
    FILTER_CACHE
        .lock()
        .expect("lock")
        .retain(|((dir, _), _)| *dir != out_dir);
}

/// Exporta as linhas filtradas (`csv`, `tsv`, `json` ou `vcf`) e copia o manifesto
/// da análise ao lado (`<destino>.manifest.json`). Retorna quantas linhas foram gravadas.
pub fn export_rows(
    out_dir: String,
    filter_json: String,
    format: String,
    sample_a: String,
    sample_b: String,
    dest_path: String,
) -> Result<u64, String> {
    let filter = parse_filter(&filter_json)?;
    let format: ExportFormat = serde_json::from_value(serde_json::Value::String(format))
        .map_err(|_| "formato desconhecido".to_string())?;
    let mut reader = open_result(&out_dir)?;
    if let Some(parent) = Path::new(&dest_path).parent() {
        std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    let out = BufWriter::new(File::create(&dest_path).map_err(|e| e.to_string())?);
    let n = export(&mut reader, &filter, format, (&sample_a, &sample_b), out)
        .map_err(|e| e.user_message())?;
    let manifest = Path::new(&out_dir).join("manifest.json");
    if manifest.exists() {
        std::fs::copy(manifest, format!("{dest_path}.manifest.json")).map_err(|e| e.to_string())?;
    }
    Ok(n)
}

/// Interpreta uma região digitada (`chr7:117.5M-117.6M`, `chr1:1000`, `X`).
/// Devolve JSON `{chrom,start,end}` ou `None` se o texto não for uma região.
#[flutter_rust_bridge::frb(sync)]
pub fn parse_region(text: String) -> Option<String> {
    genoz_core::filter::parse_region(&text).map(|r| serde_json::to_string(&r).expect("JSON"))
}

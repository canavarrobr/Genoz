//! API do Genoz exposta ao Flutter.
//!
//! Regra: esta camada só adapta o `genoz_core` (tipos simples, progresso,
//! cancelamento). Nenhuma lógica científica nova vive aqui.

use std::collections::HashMap;
use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, Mutex};

use genoz_core::build::GenomeBuild;
use genoz_core::digest::FileDigest;
use genoz_core::inspect::{inspect, InspectOptions};
use genoz_core::io::BgzfWriter;
use genoz_core::synth::{write_synthetic_vcf, SynthParams};
use sha2::{Digest, Sha256};

use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// Versão do núcleo científico (vai para os manifestos).
#[flutter_rust_bridge::frb(sync)]
pub fn core_version() -> String {
    genoz_core::CORE_VERSION.to_string()
}

pub enum ImportPhase {
    /// Copiando para a pasta privada do app e calculando o SHA-256.
    Copying,
    /// Lendo e validando o VCF.
    Validating,
}

pub enum ImportEvent {
    Progress {
        phase: ImportPhase,
        bytes_done: u64,
        bytes_total: u64,
    },
    /// Relatório de inspeção em JSON (o mesmo formato de `genoz-cli inspect --json`).
    Done {
        report_json: String,
    },
    Failed {
        message: String,
    },
    Cancelled,
}

static JOBS: LazyLock<Mutex<HashMap<String, Arc<AtomicBool>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

pub(crate) fn register(job_id: &str) -> Arc<AtomicBool> {
    let flag = Arc::new(AtomicBool::new(false));
    JOBS.lock()
        .expect("lock")
        .insert(job_id.to_string(), flag.clone());
    flag
}

pub(crate) fn unregister(job_id: &str) {
    JOBS.lock().expect("lock").remove(job_id);
}

/// Pede o cancelamento de uma importação em andamento.
#[flutter_rust_bridge::frb(sync)]
pub fn cancel_job(job_id: String) {
    if let Some(flag) = JOBS.lock().expect("lock").get(&job_id) {
        flag.store(true, Ordering::SeqCst);
    }
}

pub(crate) const PROGRESS_STEP: u64 = 4 << 20;

/// Leitor que informa o progresso e interrompe a leitura quando cancelado.
struct ProgressReader<'a, R> {
    inner: R,
    done: u64,
    last: u64,
    total: u64,
    cancel: &'a AtomicBool,
    sink: &'a StreamSink<ImportEvent>,
}

impl<R: Read> Read for ProgressReader<'_, R> {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        if self.cancel.load(Ordering::SeqCst) {
            return Err(std::io::Error::other("cancelado pelo usuário"));
        }
        let n = self.inner.read(buf)?;
        self.done += n as u64;
        if self.done - self.last >= PROGRESS_STEP {
            self.last = self.done;
            let _ = self.sink.add(ImportEvent::Progress {
                phase: ImportPhase::Validating,
                bytes_done: self.done,
                bytes_total: self.total,
            });
        }
        Ok(n)
    }
}

enum Outcome {
    Done(String),
    Cancelled,
}

fn copy_and_hash(
    source: &Path,
    dest: &Path,
    cancel: &AtomicBool,
    sink: &StreamSink<ImportEvent>,
) -> Result<Option<FileDigest>, String> {
    let total = std::fs::metadata(source)
        .map(|m| m.len())
        .map_err(|e| format!("não foi possível ler o arquivo: {e}"))?;
    // Origem == destino: o app já gravou o arquivo (ex.: `content://` no Android);
    // aqui só calculamos o hash.
    let in_place = source == dest;
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("não foi possível criar a pasta do projeto: {e}"))?;
    }
    let mut input =
        File::open(source).map_err(|e| format!("não foi possível abrir o arquivo: {e}"))?;
    let mut output: Box<dyn Write> = if in_place {
        Box::new(std::io::sink())
    } else {
        Box::new(BufWriter::new(
            File::create(dest).map_err(|e| format!("não foi possível gravar a cópia: {e}"))?,
        ))
    };
    let mut hasher = Sha256::new();
    let mut buf = vec![0u8; 1 << 20];
    let (mut done, mut last) = (0u64, 0u64);
    loop {
        if cancel.load(Ordering::SeqCst) {
            return Ok(None);
        }
        let n = input
            .read(&mut buf)
            .map_err(|e| format!("falha de leitura: {e}"))?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
        output
            .write_all(&buf[..n])
            .map_err(|e| format!("falha ao gravar (espaço em disco?): {e}"))?;
        done += n as u64;
        if done - last >= PROGRESS_STEP || done == total {
            last = done;
            let _ = sink.add(ImportEvent::Progress {
                phase: ImportPhase::Copying,
                bytes_done: done,
                bytes_total: total,
            });
        }
    }
    output
        .flush()
        .map_err(|e| format!("falha ao gravar (espaço em disco?): {e}"))?;
    Ok(Some(FileDigest {
        sha256: format!("{:x}", hasher.finalize()),
        bytes: done,
    }))
}

fn run_import(
    source: &Path,
    dest: &Path,
    cancel: &AtomicBool,
    sink: &StreamSink<ImportEvent>,
) -> Result<Outcome, String> {
    let Some(digest) = copy_and_hash(source, dest, cancel, sink)? else {
        return Ok(Outcome::Cancelled);
    };
    let reader = ProgressReader {
        inner: File::open(dest).map_err(|e| format!("não foi possível reabrir a cópia: {e}"))?,
        done: 0,
        last: 0,
        total: digest.bytes,
        cancel,
        sink,
    };
    let mut report =
        inspect(reader, &InspectOptions { max_issues: 500 }).map_err(|e| e.user_message())?;
    if cancel.load(Ordering::SeqCst) {
        return Ok(Outcome::Cancelled);
    }
    report.digest = Some(digest);
    Ok(Outcome::Done(
        serde_json::to_string(&report).expect("relatório serializável"),
    ))
}

/// Copia um VCF para a pasta privada do app (`dest_path`), calcula o SHA-256
/// e valida. Emite progresso; termina com `Done`, `Failed` ou `Cancelled`.
/// Em falha ou cancelamento, a cópia parcial é apagada.
pub fn import_vcf(
    source_path: String,
    dest_path: String,
    job_id: String,
    sink: StreamSink<ImportEvent>,
) {
    let cancel = register(&job_id);
    let (source, dest) = (Path::new(&source_path), Path::new(&dest_path));
    let event = match run_import(source, dest, &cancel, &sink) {
        Ok(Outcome::Done(report_json)) => ImportEvent::Done { report_json },
        Ok(Outcome::Cancelled) => {
            let _ = std::fs::remove_file(dest);
            ImportEvent::Cancelled
        }
        Err(message) => {
            let _ = std::fs::remove_file(dest);
            ImportEvent::Failed { message }
        }
    };
    unregister(&job_id);
    let _ = sink.add(event);
}

/// Grava um VCF sintético (dados fictícios, BGZF) para experimentar o app sem arquivo real.
pub fn write_synthetic_example(
    dest_path: String,
    seed: u64,
    samples: u32,
    variants_per_chrom: u32,
    grch37: bool,
) -> Result<(), String> {
    let params = SynthParams {
        seed,
        samples: (1..=samples.max(1))
            .map(|i| format!("EXEMPLO_{i}"))
            .collect(),
        variants_per_chrom,
        build: if grch37 {
            GenomeBuild::Grch37
        } else {
            GenomeBuild::Grch38
        },
        ..Default::default()
    };
    if let Some(parent) = Path::new(&dest_path).parent() {
        std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    let file = BufWriter::new(File::create(&dest_path).map_err(|e| e.to_string())?);
    let mut w = BgzfWriter::new(file);
    write_synthetic_vcf(&params, &mut w).map_err(|e| e.user_message())?;
    w.finish().map_err(|e| e.to_string())?;
    Ok(())
}

//! Módulo 11: relatório, verificação e reexecução a partir do manifesto, abrir `.genoz`.

use std::fs::File;
use std::io::{BufReader, BufWriter, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use clap::{Args, ValueEnum};
use genoz_core::digest::sha256_reader;
use genoz_core::manifest::{check_outputs, Manifest, OutputCheck, OutputRef};
use genoz_core::report::{build_report, render_html, Lang, ReportInput};
use genoz_core::GenozError;

use crate::analysis::{now_utc, run_compare, RunSpec};

#[derive(Clone, Copy, ValueEnum)]
pub enum LangArg {
    Pt,
    En,
}

#[derive(Args)]
pub struct ReportArgs {
    /// Pasta do resultado (com summary.json, stats_*.json e manifest.json)
    pub result: PathBuf,
    /// Arquivo de saída: .html ou .pdf
    #[arg(long)]
    pub out: PathBuf,
    #[arg(long, value_enum, default_value_t = LangArg::Pt)]
    pub lang: LangArg,
    /// Nome do projeto no cabeçalho
    #[arg(long, default_value = "—")]
    pub project: String,
}

#[derive(Args)]
pub struct RerunArgs {
    /// Pasta do resultado original (com manifest.json)
    pub result: PathBuf,
    /// Entrada A (na análise de família: o VCF multiamostra)
    #[arg(long)]
    pub a: PathBuf,
    /// Entrada B (comparações)
    #[arg(long)]
    pub b: Option<PathBuf>,
    #[arg(long)]
    pub bed_a: Option<PathBuf>,
    #[arg(long)]
    pub bed_b: Option<PathBuf>,
    #[arg(long)]
    pub fasta: Option<PathBuf>,
    /// Pasta para a reexecução (padrão: pasta temporária do sistema)
    #[arg(long)]
    pub out: Option<PathBuf>,
}

#[derive(Args)]
pub struct UnpackArgs {
    /// Arquivo .genoz exportado pelo app
    pub file: PathBuf,
    /// Pasta de destino (precisa não existir ou estar vazia)
    #[arg(long)]
    pub out: PathBuf,
}

fn read_json(path: &Path) -> Result<serde_json::Value, GenozError> {
    let text = std::fs::read_to_string(path)?;
    serde_json::from_str(&text)
        .map_err(|e| GenozError::InvalidParam(format!("{}: JSON inválido ({e})", path.display())))
}

fn read_manifest(dir: &Path) -> Result<Manifest, GenozError> {
    let path = dir.join("manifest.json");
    serde_json::from_value(read_json(&path)?)
        .map_err(|e| GenozError::InvalidParam(format!("{}: manifesto inválido ({e})", path.display())))
}

pub fn report_cmd(args: ReportArgs) -> Result<ExitCode, GenozError> {
    let summary = read_json(&args.result.join("summary.json"))?;
    let optional = |name: &str| {
        let p = args.result.join(name);
        if p.exists() {
            read_json(&p).map(Some)
        } else {
            Ok(None)
        }
    };
    let (stats_a, stats_b, manifest) =
        (optional("stats_a.json")?, optional("stats_b.json")?, optional("manifest.json")?);
    let lang = match args.lang {
        LangArg::Pt => Lang::Pt,
        LangArg::En => Lang::En,
    };
    let now = now_utc();
    let doc = build_report(&ReportInput {
        project: &args.project,
        generated_at: &now.replace('T', " ").replace('Z', " UTC"),
        summary: &summary,
        stats_a: stats_a.as_ref(),
        stats_b: stats_b.as_ref(),
        manifest: manifest.as_ref(),
        lang,
    });
    let pdf = args.out.extension().is_some_and(|e| e.eq_ignore_ascii_case("pdf"));
    let bytes = if pdf { genoz_core::pdf::render_pdf(&doc) } else { render_html(&doc).into_bytes() };
    std::fs::write(&args.out, &bytes)?;
    println!(
        "relatório {} gravado em {} ({} bytes)",
        if pdf { "PDF" } else { "HTML" },
        args.out.display(),
        bytes.len()
    );
    Ok(ExitCode::SUCCESS)
}

fn outputs_in(dir: &Path, expected: &[OutputRef]) -> Result<Vec<OutputRef>, GenozError> {
    let mut found = Vec::new();
    for o in expected {
        let p = dir.join(&o.name);
        if p.exists() {
            let d = sha256_reader(File::open(&p)?)?;
            found.push(OutputRef { name: o.name.clone(), sha256: d.sha256, bytes: d.bytes });
        }
    }
    Ok(found)
}

fn print_checks(checks: &[OutputCheck]) -> bool {
    let ok = checks.iter().filter(|c| c.matches).count();
    for c in checks {
        let state = match (&c.actual_sha256, c.matches) {
            (_, true) => "idêntica".to_string(),
            (None, _) => "AUSENTE".to_string(),
            (Some(h), false) => format!("DIFERENTE ({}…)", &h[..12.min(h.len())]),
        };
        println!("  {:<14} {state}", c.name);
    }
    println!();
    println!("{ok} de {} saídas idênticas ao manifesto", checks.len());
    ok == checks.len()
}

/// Confere os SHA-256 das saídas de uma pasta de resultado contra o manifesto.
pub fn verify_cmd(result: &Path) -> Result<ExitCode, GenozError> {
    let m = read_manifest(result)?;
    println!("Análise {} ({})", m.analysis_id, m.analysis_type);
    let checks = check_outputs(&m.outputs, &outputs_in(result, &m.outputs)?);
    Ok(if print_checks(&checks) { ExitCode::SUCCESS } else { ExitCode::from(1) })
}

/// Refaz a análise com os parâmetros do manifesto e compara as saídas.
pub fn rerun_cmd(args: RerunArgs) -> Result<ExitCode, GenozError> {
    let m = read_manifest(&args.result)?;
    if !matches!(m.analysis_type.as_str(), "compare" | "compare_chip" | "family") {
        return Err(GenozError::InvalidParam(format!("reexecução de '{}' não é suportada", m.analysis_type)));
    }
    let given: Vec<(&str, &PathBuf)> = [
        ("a", Some(&args.a)),
        ("b", args.b.as_ref()),
        ("callable_a", args.bed_a.as_ref()),
        ("callable_b", args.bed_b.as_ref()),
        ("reference", args.fasta.as_ref()),
    ]
    .into_iter()
    .filter_map(|(r, p)| p.map(|p| (r, p)))
    .collect();
    // Entradas: mesmos papéis e mesmos SHA-256 do manifesto.
    println!("Entradas:");
    let mut inputs_ok = true;
    for input in &m.inputs {
        match given.iter().find(|(r, _)| *r == input.role) {
            None => {
                println!("  {:<12} FALTA: informe o arquivo {} ({})", input.role, input.name, role_flag(&input.role));
                inputs_ok = false;
            }
            Some((_, path)) => {
                let d = sha256_reader(File::open(path)?)?;
                let same = d.sha256 == input.sha256;
                println!(
                    "  {:<12} {} {}",
                    input.role,
                    path.display(),
                    if same { "SHA-256 confere" } else { "SHA-256 DIFERENTE" }
                );
                inputs_ok &= same;
            }
        }
    }
    for (role, path) in &given {
        if !m.inputs.iter().any(|i| i.role == *role) {
            println!("  {role:<12} {} não faz parte desta análise", path.display());
            inputs_ok = false;
        }
    }
    if !inputs_ok {
        println!();
        println!("As entradas não são as do manifesto: a reexecução não provaria nada.");
        return Ok(ExitCode::from(1));
    }
    let out = args.out.unwrap_or_else(|| std::env::temp_dir().join(format!("genoz_reexecucao_{}", m.analysis_id)));
    let again = if m.analysis_type == "family" {
        let opts = genoz_core::family::options_from_manifest(&m.parameters)?;
        crate::family_cmd::run_family(&args.a, &opts, &out)?.0
    } else {
        let (opts, sample_a, sample_b) = genoz_core::compare::parameters_from_manifest(&m.parameters)?;
        let b = args.b.ok_or_else(|| GenozError::InvalidParam("informe --b".into()))?;
        rerun_compare(args.a, b, sample_a, sample_b, args.bed_a, args.bed_b, args.fasta, opts, &m, &out)?
    };
    println!();
    println!("Reexecução em {}", out.display());
    if again.analysis_id != m.analysis_id {
        println!("ID da análise DIFERENTE: {} (original {})", again.analysis_id, m.analysis_id);
    } else {
        println!("ID da análise: {} (igual ao original)", m.analysis_id);
    }
    let checks = check_outputs(&m.outputs, &again.outputs);
    let ok = print_checks(&checks) && again.analysis_id == m.analysis_id;
    Ok(if ok { ExitCode::SUCCESS } else { ExitCode::from(1) })
}

#[allow(clippy::too_many_arguments)]
fn rerun_compare(
    a: PathBuf,
    b: PathBuf,
    sample_a: genoz_core::call::SampleSelector,
    sample_b: genoz_core::call::SampleSelector,
    bed_a: Option<PathBuf>,
    bed_b: Option<PathBuf>,
    fasta: Option<PathBuf>,
    opts: genoz_core::compare::CompareOptions,
    m: &Manifest,
    out: &Path,
) -> Result<Manifest, GenozError> {
    let spec = RunSpec { a, b, sample_a, sample_b, bed_a, bed_b, fasta, opts, chip: m.analysis_type == "compare_chip" };
    Ok(run_compare(&spec, out)?.0)
}

fn role_flag(role: &str) -> &'static str {
    match role {
        "a" => "--a",
        "b" => "--b",
        "callable_a" => "--bed-a",
        "callable_b" => "--bed-b",
        "reference" => "--fasta",
        _ => "?",
    }
}

fn password() -> Result<String, GenozError> {
    if let Ok(p) = std::env::var("GENOZ_SENHA") {
        return Ok(p);
    }
    eprint!("Senha do arquivo .genoz (ou defina GENOZ_SENHA): ");
    std::io::stderr().flush()?;
    let mut line = String::new();
    std::io::stdin().read_line(&mut line)?;
    Ok(line.trim_end_matches(['\r', '\n']).to_string())
}

/// Abre um `.genoz` no computador: extrai projeto.json, arquivos e resultados.
pub fn unpack_cmd(args: UnpackArgs) -> Result<ExitCode, GenozError> {
    if args.out.exists() && std::fs::read_dir(&args.out)?.next().is_some() {
        return Err(GenozError::InvalidParam(format!("{} já existe e não está vazia", args.out.display())));
    }
    let pw = password()?;
    let reader = genoz_core::vault::OpenReader::new(BufReader::new(File::open(&args.file)?), &pw)?;
    std::fs::create_dir_all(&args.out)?;
    let mut count = 0u64;
    let mut total = 0u64;
    let result = genoz_core::pack::read_pack(reader, |path, size, data| {
        let dest = args.out.join(path);
        if let Some(parent) = dest.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut w = BufWriter::new(File::create(&dest)?);
        std::io::copy(data, &mut w)?;
        w.flush()?;
        count += 1;
        total += size;
        println!("  {path} ({size} bytes)");
        Ok(())
    });
    if let Err(e) = result {
        // Nada pela metade: apaga o que foi extraído.
        let _ = std::fs::remove_dir_all(&args.out);
        return Err(e);
    }
    println!("{count} arquivos ({total} bytes) extraídos em {}", args.out.display());
    Ok(ExitCode::SUCCESS)
}

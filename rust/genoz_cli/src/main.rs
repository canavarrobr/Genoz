//! `genoz-cli`: ferramenta de desenvolvimento do Genoz.
//!
//! Exemplos:
//!   genoz-cli inspect amostra.vcf.gz
//!   genoz-cli inspect amostra.vcf --json
//!   genoz-cli hash amostra.vcf.gz
//!   genoz-cli synth --out sintetico.vcf.gz --seed 42 --samples 3
//!   genoz-cli split entrada.vcf.gz --out normalizado.vcf.gz
//!   genoz-cli compare a.vcf.gz b.vcf.gz --out resultado/
//!   genoz-cli view resultado/ --category only_a --page 2
//!   genoz-cli stats amostra.vcf.gz

mod analysis;

use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use clap::{Parser, Subcommand, ValueEnum};
use genoz_core::build::GenomeBuild;
use genoz_core::digest::sha256_reader;
use genoz_core::inspect::{inspect_path, InspectOptions, InspectReport, Verdict};
use genoz_core::io::BgzfWriter;
use genoz_core::normalize::split_multiallelic;
use genoz_core::reader::{Severity, VcfReader};
use genoz_core::synth::{write_synthetic_vcf, SynthParams};
use genoz_core::writer::{write_header, write_record};
use genoz_core::GenozError;

#[derive(Parser)]
#[command(name = "genoz-cli", version, about = "Ferramenta de desenvolvimento do Genoz (tudo local, sem rede)")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Valida um VCF e mostra um resumo (hash, build, amostras, contagens, problemas).
    Inspect {
        file: PathBuf,
        /// Saída em JSON (para scripts e testes).
        #[arg(long)]
        json: bool,
        /// Máximo de problemas listados em detalhe.
        #[arg(long, default_value_t = 20)]
        max_issues: usize,
    },
    /// Calcula o SHA-256 do arquivo.
    Hash { file: PathBuf },
    /// Gera um VCF sintético (dados fictícios) determinístico.
    Synth {
        #[arg(long)]
        out: PathBuf,
        #[arg(long, default_value_t = 42)]
        seed: u64,
        #[arg(long, default_value_t = 2)]
        samples: usize,
        #[arg(long, default_value_t = 1000)]
        variants_per_chrom: u32,
        #[arg(long, value_enum, default_value_t = Build::Grch38)]
        build: Build,
        /// Usa nomes sem "chr" (estilo Ensembl).
        #[arg(long)]
        no_chr: bool,
        #[arg(long)]
        phased: bool,
    },
    /// Divide multialélicos e apara bases redundantes; grava novo VCF.
    Split {
        file: PathBuf,
        #[arg(long)]
        out: PathBuf,
    },
    /// Compara duas amostras (A × B) e grava o resultado paginável + manifesto.
    Compare(analysis::CompareArgs),
    /// Estatísticas de QC de uma amostra (Ti/Tv, het/hom, profundidade...).
    Stats(analysis::StatsArgs),
    /// Mostra as linhas de um resultado de comparação, com filtros e páginas.
    View(analysis::ViewArgs),
}

#[derive(Clone, Copy, ValueEnum)]
enum Build {
    Grch37,
    Grch38,
}

fn main() -> ExitCode {
    match run(Cli::parse()) {
        Ok(code) => code,
        Err(e) => {
            eprintln!("erro: {}", e.user_message());
            ExitCode::from(2)
        }
    }
}

fn run(cli: Cli) -> Result<ExitCode, GenozError> {
    match cli.command {
        Command::Inspect { file, json, max_issues } => {
            let report = inspect_path(&file, &InspectOptions { max_issues })?;
            if json {
                println!("{}", serde_json::to_string_pretty(&report).expect("relatório serializável"));
            } else {
                print_report(&file, &report);
            }
            Ok(match report.verdict {
                Verdict::Valid | Verdict::ValidWithWarnings => ExitCode::SUCCESS,
                Verdict::PartiallyValid | Verdict::Invalid => ExitCode::from(1),
            })
        }
        Command::Hash { file } => {
            let d = sha256_reader(File::open(&file)?)?;
            println!("{}  {}", d.sha256, file.display());
            Ok(ExitCode::SUCCESS)
        }
        Command::Synth { out, seed, samples, variants_per_chrom, build, no_chr, phased } => {
            let params = SynthParams {
                seed,
                samples: (1..=samples).map(|i| format!("SINT_{i}")).collect(),
                variants_per_chrom,
                build: match build {
                    Build::Grch37 => GenomeBuild::Grch37,
                    Build::Grch38 => GenomeBuild::Grch38,
                },
                chr_prefix: !no_chr,
                phased,
                ..Default::default()
            };
            with_output(&out, |w| write_synthetic_vcf(&params, w))?;
            println!("VCF sintético gravado em {}", out.display());
            Ok(ExitCode::SUCCESS)
        }
        Command::Split { file, out } => {
            let mut reader = VcfReader::new(File::open(&file)?)?;
            let header = reader.header().clone();
            let (mut written, mut rejected) = (0u64, 0u64);
            with_output(&out, |w| {
                let extra = [format!("##genozCommand=split; genoz_core {}", genoz_core::CORE_VERSION)];
                write_header(w, &header, &extra)?;
                while let Some(parsed) = reader.next_parsed()? {
                    match parsed.record {
                        Some(rec) => {
                            for part in split_multiallelic(&rec, &header) {
                                write_record(w, &part)?;
                                written += 1;
                            }
                        }
                        None => rejected += 1,
                    }
                }
                Ok(())
            })?;
            println!("{written} registros gravados em {}; {rejected} linhas inválidas descartadas", out.display());
            Ok(ExitCode::SUCCESS)
        }
        Command::Compare(args) => analysis::compare_cmd(args).map(|()| ExitCode::SUCCESS),
        Command::Stats(args) => analysis::stats_cmd(args).map(|()| ExitCode::SUCCESS),
        Command::View(args) => analysis::view_cmd(args).map(|()| ExitCode::SUCCESS),
    }
}

/// Abre a saída; `.gz` gera BGZF (indexável).
fn with_output(path: &Path, body: impl FnOnce(&mut dyn Write) -> Result<(), GenozError>) -> Result<(), GenozError> {
    let file = BufWriter::new(File::create(path)?);
    if path.extension().is_some_and(|e| e == "gz") {
        let mut w = BgzfWriter::new(file);
        body(&mut w)?;
        w.finish()?;
    } else {
        let mut w = file;
        body(&mut w)?;
        w.flush()?;
    }
    Ok(())
}

fn print_report(file: &Path, r: &InspectReport) {
    let verdict = match r.verdict {
        Verdict::Valid => "VÁLIDO",
        Verdict::ValidWithWarnings => "VÁLIDO com avisos",
        Verdict::PartiallyValid => "PARCIALMENTE VÁLIDO (linhas descartadas)",
        Verdict::Invalid => "INVÁLIDO",
    };
    println!("Arquivo:      {}", file.display());
    println!("Resultado:    {verdict}");
    if let Some(d) = &r.digest {
        println!("SHA-256:      {}", d.sha256);
        println!("Tamanho:      {} bytes", d.bytes);
    }
    println!("Compressão:   {}", r.compression.label());
    println!("Formato:      {}", r.file_format.as_deref().unwrap_or("(não declarado)"));
    println!("Build:        {} (confiança {})", r.build.build.label(), r.build.confidence.label());
    for e in &r.build.evidence {
        println!("              - {e}");
    }
    println!("Cromossomos:  estilo {}; {} contigs no cabeçalho", r.chrom_style.label(), r.contigs_in_header);
    println!("Registros:    {} lidos, {} válidos, {} descartados", r.records_read, r.records_ok, r.records_rejected);
    println!("Multialélicos:{} (→ {} registros bialélicos)", r.multiallelic, r.biallelic_after_split);
    println!("FILTER:       PASS {}, filtrados {}, sem filtro {}", r.filter_pass, r.filter_failed, r.filter_missing);
    println!("Ordenado:     {}", if r.sorted { "sim" } else { "não" });
    println!("Tipos:");
    for (k, v) in &r.by_kind {
        println!("  {:<22}{v}", k.label());
    }
    println!("Por cromossomo:");
    for c in &r.by_chrom {
        println!("  {:<22}{}", c.raw, c.records);
    }
    if !r.samples.is_empty() {
        println!("Amostras ({}):", r.samples.len());
        println!("  {:<20}{:>10}{:>10}{:>10}{:>10}", "nome", "hom-ref", "het", "hom-alt", "ausente");
        for s in &r.samples {
            println!("  {:<20}{:>10}{:>10}{:>10}{:>10}", s.name, s.hom_ref, s.het, s.hom_alt, s.missing);
        }
    }
    if let Some(f) = &r.fatal {
        println!("LEITURA INTERROMPIDA: {f}");
    }
    println!("Problemas:    {} erros, {} avisos", r.errors, r.warnings);
    for i in &r.issues {
        let sev = match i.severity {
            Severity::Error => "ERRO ",
            Severity::Warning => "aviso",
        };
        let loc = if i.line == 0 { "cabeçalho".to_string() } else { format!("linha {}", i.line) };
        println!("  [{sev}] {loc}: {}", i.message);
    }
    if r.issues_truncated {
        println!("  ... (lista truncada; use --max-issues para ver mais)");
    }
}

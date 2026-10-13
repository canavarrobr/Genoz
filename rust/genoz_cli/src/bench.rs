//! Módulo 13: `genoz-cli bench` — benchmark reproduzível com dados sintéticos.
//!
//! Gera dois VCFs (BGZF) e uma família fictícia do tamanho pedido numa pasta, e mede
//! importação (validação + SHA-256), comparação, família, cofre e relatório. Os mesmos
//! arquivos podem ser copiados para o celular ou o navegador para medir lá.

use std::fs::File;
use std::io::{BufReader, BufWriter, Write};
use std::path::{Path, PathBuf};
use std::time::Instant;

use clap::Args;
use genoz_core::build::GenomeBuild;
use genoz_core::call::SampleSelector;
use genoz_core::compare::CompareOptions;
use genoz_core::digest::sha256_reader;
use genoz_core::inspect::{inspect, InspectOptions};
use genoz_core::io::BgzfWriter;
use genoz_core::synth::{write_family_vcf, write_synthetic_vcf, SynthParams};
use genoz_core::GenozError;

use crate::analysis::{run_compare, RunSpec};

#[derive(Args)]
pub struct BenchArgs {
    /// Pasta de trabalho (os arquivos gerados ficam lá para medir no celular/navegador)
    #[arg(long)]
    pub dir: PathBuf,
    /// Variantes por cromossomo em cada VCF da comparação (22 autossomos)
    #[arg(long, default_value_t = 25_000)]
    pub variants_per_chrom: u32,
    /// Sítios por cromossomo na família (3 cromossomos, 7 pessoas)
    #[arg(long, default_value_t = 100_000)]
    pub family_sites: u32,
}

fn mb(path: &Path) -> f64 {
    std::fs::metadata(path).map(|m| m.len() as f64 / 1e6).unwrap_or(0.0)
}

fn gen_vcf(path: &Path, seed: u64, per_chrom: u32) -> Result<(), GenozError> {
    let params = SynthParams {
        seed,
        samples: vec![format!("BENCH_{seed}")],
        variants_per_chrom: per_chrom,
        chroms: (1..=22).map(|n| n.to_string()).collect(),
        ..Default::default()
    };
    let mut w = BgzfWriter::new(BufWriter::new(File::create(path)?));
    write_synthetic_vcf(&params, &mut w)?;
    w.finish()?.flush()?;
    Ok(())
}

pub fn bench_cmd(args: BenchArgs) -> Result<(), GenozError> {
    std::fs::create_dir_all(&args.dir)?;
    let a = args.dir.join("bench_a.vcf.gz");
    let b = args.dir.join("bench_b.vcf.gz");
    let fam = args.dir.join("bench_familia.vcf.gz");
    let mut rows: Vec<(String, f64, String)> = Vec::new();
    let mut time = |label: &str, f: &mut dyn FnMut() -> Result<String, GenozError>| -> Result<(), GenozError> {
        let t = Instant::now();
        let note = f()?;
        let s = t.elapsed().as_secs_f64();
        println!("  {label:<38} {s:>8.2} s  {note}");
        rows.push((label.to_string(), s, note));
        Ok(())
    };
    println!("Benchmark do Genoz (núcleo {}) — dados sintéticos", genoz_core::CORE_VERSION);
    time("gerar 2 VCFs + família (BGZF)", &mut || {
        gen_vcf(&a, 1, args.variants_per_chrom)?;
        gen_vcf(&b, 2, args.variants_per_chrom)?;
        let mut w = BgzfWriter::new(BufWriter::new(File::create(&fam)?));
        write_family_vcf(2026, GenomeBuild::Grch38, args.family_sites, &mut w)?;
        w.finish()?.flush()?;
        Ok(format!("{:.1} MB + {:.1} MB + {:.1} MB", mb(&a), mb(&b), mb(&fam)))
    })?;
    time("importar A (validação + estatísticas)", &mut || {
        let r = inspect(BufReader::new(File::open(&a)?), &InspectOptions::default())?;
        Ok(format!("{} registros", r.records_ok))
    })?;
    time("SHA-256 de A", &mut || Ok(sha256_reader(File::open(&a)?)?.sha256[..12].to_string()))?;
    let out = args.dir.join("resultado");
    time("comparar A × B (streaming)", &mut || {
        let spec = RunSpec {
            a: a.clone(),
            b: b.clone(),
            sample_a: SampleSelector::First,
            sample_b: SampleSelector::First,
            bed_a: None,
            bed_b: None,
            fasta: None,
            opts: CompareOptions::default(),
            chip: false,
        };
        let (_, s) = run_compare(&spec, &out)?;
        Ok(format!("{} linhas", s.rows))
    })?;
    time("família (7 pessoas, trio)", &mut || {
        let opts = genoz_core::family::FamilyOptions {
            trio: Some(genoz_core::family::TrioRoles {
                child: "FILHO".into(),
                father: "PAI".into(),
                mother: "MAE".into(),
            }),
            ..Default::default()
        };
        let r = genoz_core::family::analyze_family(BufReader::new(File::open(&fam)?), &opts)?;
        Ok(format!("{} SNVs, {} pares", r.sites.used, r.pairs.len()))
    })?;
    let sealed = args.dir.join("bench.genoz");
    time("cofre: cifrar A (Argon2id + XChaCha20)", &mut || {
        let w = BufWriter::new(File::create(&sealed)?);
        let mut s = genoz_core::vault::SealWriter::new(w, "senha de teste", &[9; 32], Default::default())?;
        std::io::copy(&mut BufReader::new(File::open(&a)?), &mut s)?;
        s.finish()?.flush()?;
        Ok(format!("{:.1} MB", mb(&sealed)))
    })?;
    time("cofre: decifrar", &mut || {
        let mut r = genoz_core::vault::OpenReader::new(BufReader::new(File::open(&sealed)?), "senha de teste")?;
        let n = std::io::copy(&mut r, &mut std::io::sink())?;
        Ok(format!("{:.1} MB", n as f64 / 1e6))
    })?;
    time("relatório PDF", &mut || {
        let read = |n: &str| -> Result<serde_json::Value, GenozError> {
            Ok(serde_json::from_str(&std::fs::read_to_string(out.join(n))?).expect("JSON"))
        };
        let (s, sa, sb, m) = (read("summary.json")?, read("stats_a.json")?, read("stats_b.json")?, read("manifest.json")?);
        let doc = genoz_core::report::build_report(&genoz_core::report::ReportInput {
            project: "bench",
            generated_at: "-",
            summary: &s,
            stats_a: Some(&sa),
            stats_b: Some(&sb),
            manifest: Some(&m),
            lang: genoz_core::report::Lang::Pt,
        });
        Ok(format!("{} bytes", genoz_core::pdf::render_pdf(&doc).len()))
    })?;
    let json: Vec<serde_json::Value> =
        rows.iter().map(|(l, s, n)| serde_json::json!({"etapa": l, "segundos": s, "detalhe": n})).collect();
    std::fs::write(args.dir.join("bench.json"), serde_json::to_vec_pretty(&json).expect("JSON"))?;
    println!("Resultados em {}", args.dir.join("bench.json").display());
    Ok(())
}

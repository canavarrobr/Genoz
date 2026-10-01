//! Comandos de análise da CLI: `compare`, `stats` e `view`.

use std::fs::File;
use std::io::{BufReader, BufWriter, Read};
use std::path::{Path, PathBuf};

use clap::{Args, ValueEnum};
use genoz_core::call::SampleSelector;
use genoz_core::compare::{compare_to_store, to_json_bytes, Category, CompareInput, CompareOptions, Truth};
use genoz_core::digest::sha256_reader;
use genoz_core::filter::{parse_region, CallFilter, RowFilter};
use genoz_core::manifest::{InputRef, Manifest, OutputRef};
use genoz_core::record::VariantKind;
use genoz_core::regions::read_bed;
use genoz_core::results::{export_rows, ExportFormat, ResultReader, RowIndex};
use genoz_core::stats::{sample_stats, SampleStats};
use genoz_core::GenozError;

#[derive(Args)]
pub struct QualityArgs {
    /// Considera incertas as chamadas com FILTER diferente de PASS.
    #[arg(long)]
    pub pass_only: bool,
    #[arg(long)]
    pub min_qual: Option<f64>,
    #[arg(long)]
    pub min_dp: Option<u32>,
    #[arg(long)]
    pub min_gq: Option<u32>,
}

impl QualityArgs {
    fn filter(&self) -> CallFilter {
        CallFilter {
            pass_only: self.pass_only,
            min_qual: self.min_qual,
            min_dp: self.min_dp,
            min_gq: self.min_gq,
            conditions: Vec::new(),
        }
    }
}

#[derive(Args)]
pub struct CompareArgs {
    pub a: PathBuf,
    pub b: PathBuf,
    /// Pasta onde o resultado será gravado.
    #[arg(long)]
    pub out: PathBuf,
    /// Nome da amostra em A (padrão: a primeira).
    #[arg(long)]
    pub sample_a: Option<String>,
    #[arg(long)]
    pub sample_b: Option<String>,
    /// BED de regiões chamáveis de A.
    #[arg(long)]
    pub bed_a: Option<PathBuf>,
    #[arg(long)]
    pub bed_b: Option<PathBuf>,
    /// Trata A ou B como "verdade" e calcula precisão/sensibilidade/F1.
    #[arg(long, value_enum)]
    pub truth: Option<TruthArg>,
    #[command(flatten)]
    pub quality: QualityArgs,
    #[arg(long)]
    pub allow_build_mismatch: bool,
}

#[derive(Clone, Copy, ValueEnum)]
pub enum TruthArg {
    A,
    B,
}

#[derive(Args)]
pub struct StatsArgs {
    pub file: PathBuf,
    #[arg(long)]
    pub sample: Option<String>,
    #[arg(long)]
    pub json: bool,
    #[command(flatten)]
    pub quality: QualityArgs,
}

#[derive(Args)]
pub struct ViewArgs {
    /// Pasta de resultado criada por `compare`.
    pub dir: PathBuf,
    #[arg(long, default_value_t = 1)]
    pub page: u64,
    #[arg(long, default_value_t = 25)]
    pub page_size: usize,
    #[command(flatten)]
    pub filter: RowFilterArgs,
}

#[derive(Args)]
pub struct DensityArgs {
    /// Pasta de resultado criada por `compare`.
    pub dir: PathBuf,
    /// Tamanho de cada faixa, em pares de bases.
    #[arg(long, default_value_t = genoz_core::density::DEFAULT_BIN_SIZE)]
    pub bin: u64,
    /// Saída em JSON (a mesma estrutura que o app desenha no ideograma).
    #[arg(long)]
    pub json: bool,
    #[command(flatten)]
    pub filter: RowFilterArgs,
}

fn selector(name: &Option<String>) -> SampleSelector {
    name.clone().map_or(SampleSelector::First, SampleSelector::Name)
}

fn file_input(label: &str, path: &Path, sample: SampleSelector) -> CompareInput<'static> {
    let p = path.to_path_buf();
    CompareInput {
        label: label.into(),
        open: Box::new(move || Ok(Box::new(File::open(&p)?) as Box<dyn Read>)),
        sample,
        callable: None,
    }
}

fn input_ref(role: &str, path: &Path) -> Result<InputRef, GenozError> {
    let d = sha256_reader(File::open(path)?)?;
    Ok(InputRef {
        role: role.into(),
        name: path.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default(),
        sha256: d.sha256,
        bytes: d.bytes,
        build: None,
        sample: None,
    })
}

fn write_output(dir: &Path, name: &str, bytes: &[u8]) -> Result<OutputRef, GenozError> {
    std::fs::write(dir.join(name), bytes)?;
    output_ref(dir, name)
}

fn output_ref(dir: &Path, name: &str) -> Result<OutputRef, GenozError> {
    let d = sha256_reader(File::open(dir.join(name))?)?;
    Ok(OutputRef { name: name.into(), sha256: d.sha256, bytes: d.bytes })
}

/// Data/hora UTC em RFC 3339, sem dependências externas.
fn now_utc() -> String {
    let secs = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let (days, rem) = (secs / 86_400, secs % 86_400);
    // Algoritmo de Howard Hinnant (civil_from_days).
    let z = days as i64 + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + i64::from(m <= 2);
    format!("{y:04}-{m:02}-{d:02}T{:02}:{:02}:{:02}Z", rem / 3600, rem % 3600 / 60, rem % 60)
}

fn pct(v: Option<f64>) -> String {
    v.map_or_else(|| "—".into(), |x| format!("{:.1}%", x * 100.0))
}

pub fn compare_cmd(args: CompareArgs) -> Result<(), GenozError> {
    let mut a = file_input("A", &args.a, selector(&args.sample_a));
    let mut b = file_input("B", &args.b, selector(&args.sample_b));
    let mut inputs = vec![input_ref("a", &args.a)?, input_ref("b", &args.b)?];
    for (side, bed, role) in [(&mut a, &args.bed_a, "callable_a"), (&mut b, &args.bed_b, "callable_b")] {
        if let Some(path) = bed {
            let (set, issues) = read_bed(File::open(path)?)?;
            if let Some(i) = issues.first() {
                return Err(GenozError::InvalidParam(format!(
                    "BED {} linha {}: {}",
                    path.display(),
                    i.line,
                    i.message
                )));
            }
            side.callable = Some(set);
            inputs.push(input_ref(role, path)?);
        }
    }
    let opts = CompareOptions {
        call_filter: args.quality.filter(),
        truth: args.truth.map(|t| match t {
            TruthArg::A => Truth::A,
            TruthArg::B => Truth::B,
        }),
        allow_build_mismatch: args.allow_build_mismatch,
        force_in_memory: false,
    };

    std::fs::create_dir_all(&args.out)?;
    let rows_file = BufWriter::new(File::create(args.out.join("rows.bgz"))?);
    let stored = compare_to_store(&mut a, &mut b, &opts, rows_file)?;
    drop(stored.rows_out);
    let s = &stored.outcome.summary;

    let mut outputs = vec![output_ref(&args.out, "rows.bgz")?];
    outputs.push(write_output(&args.out, "rows.idx", &stored.index.to_bytes())?);
    outputs.push(write_output(&args.out, "summary.json", &to_json_bytes(s))?);
    outputs.push(write_output(&args.out, "stats_a.json", &to_json_bytes(&stored.outcome.stats_a))?);
    outputs.push(write_output(&args.out, "stats_b.json", &to_json_bytes(&stored.outcome.stats_b))?);

    inputs[0].build = Some(s.a.build.build.label().into());
    inputs[0].sample = s.a.sample.clone();
    inputs[1].build = Some(s.b.build.build.label().into());
    inputs[1].sample = s.b.sample.clone();
    let parameters =
        genoz_core::compare::manifest_parameters(&opts, &selector(&args.sample_a), &selector(&args.sample_b));
    let platform = format!("cli-{}-{}", std::env::consts::OS, std::env::consts::ARCH);
    let manifest = Manifest::new("compare", inputs, parameters, outputs, &platform, &now_utc());
    std::fs::write(args.out.join("manifest.json"), to_json_bytes(&manifest))?;

    let mode = match s.mode {
        genoz_core::compare::CompareMode::Streaming => "streaming, memória constante",
        genoz_core::compare::CompareMode::InMemory => "em memória",
    };
    println!("Comparação A × B  (modo: {mode})");
    println!("  A: {} — amostra {}", args.a.display(), s.a.sample.as_deref().unwrap_or("(apenas sítios)"));
    println!("  B: {} — amostra {}", args.b.display(), s.b.sample.as_deref().unwrap_or("(apenas sítios)"));
    println!();
    for c in Category::ALL {
        println!("  {:<22}{:>10}", c.label(), s.counts.get(&c).copied().unwrap_or(0));
    }
    println!("  {:<22}{:>10}", "total", s.rows);
    println!();
    println!("  Concordância de genótipos: {}", pct(s.genotype_concordance));
    println!("  Jaccard (sítios):          {}", pct(s.jaccard));
    if let Some(bm) = &s.benchmark {
        println!("  Verdade: {:?}", bm.truth);
        for (name, m) in [("todas", &bm.all), ("SNV", &bm.snv), ("indel", &bm.indel)] {
            println!("    {name:<6} precisão {}  sensibilidade {}  F1 {}", pct(m.precision), pct(m.recall), pct(m.f1));
        }
    }
    for w in &s.warnings {
        println!("  aviso: {w}");
    }
    println!();
    println!("Resultado gravado em {}", args.out.display());
    println!("ID da análise: {}", manifest.analysis_id);
    Ok(())
}

pub fn stats_cmd(args: StatsArgs) -> Result<(), GenozError> {
    let stats = sample_stats(File::open(&args.file)?, &selector(&args.sample), args.quality.filter(), "amostra")?;
    if args.json {
        print!("{}", String::from_utf8_lossy(&to_json_bytes(&stats)));
        return Ok(());
    }
    print_stats(&args.file, &stats);
    Ok(())
}

fn print_stats(file: &Path, s: &SampleStats) {
    let ratio = |v: Option<f64>| v.map_or_else(|| "—".into(), |x| format!("{x:.2}"));
    println!("QC de {}", file.display());
    println!("  chamadas: {}  (carrega: {}, 0/0: {}, ausentes: {})", s.calls_total, s.carriers, s.hom_ref, s.missing);
    println!("  het: {}  hom-alt: {}  razão het/hom: {}", s.het, s.hom_alt, ratio(s.het_hom_ratio));
    println!(
        "  Ti/Tv: {}  (transições {}, transversões {})  — referência: ~2,0–2,1 genoma, ~3,0 exoma",
        ratio(s.ti_tv),
        s.transitions,
        s.transversions
    );
    println!("  taxa de ausentes: {}", pct(s.missing_rate));
    if s.low_quality > 0 {
        println!("  reprovadas no portão de qualidade: {}", s.low_quality);
    }
    println!("  tipos:");
    for (k, v) in &s.by_kind {
        println!("    {:<22}{v}", k.label());
    }
    let x = &s.x_heterozygosity;
    if x.het + x.hom_alt > 0 {
        println!(
            "  X (fora das PAR{}): het {} / hom-alt {} → fração het {} (educacional; não determina sexo)",
            if x.par_excluded { "" } else { ", build desconhecido: PAR não excluídas" },
            x.het,
            x.hom_alt,
            pct(x.het_fraction)
        );
    }
    println!("  DP (profundidade):");
    for b in &s.dp_hist {
        let hi = b.hi.map_or_else(|| "+".into(), |h| format!("–{h}"));
        println!("    {:>5}{:<6}{:>10}", b.lo, hi, b.count);
    }
}

#[derive(Args)]
pub struct RowFilterArgs {
    /// Categorias: shared, genotype_difference, only_a, only_b, missing_uncertain, not_assessed.
    #[arg(long, value_delimiter = ',')]
    pub category: Vec<String>,
    /// Tipos: snv, mnv, insertion, deletion, complex, structural, other.
    #[arg(long, value_delimiter = ',')]
    pub kind: Vec<String>,
    /// Região, ex.: chr1:1-50000 ou chr7:117.5M-117.6M.
    #[arg(long)]
    pub region: Option<String>,
    #[arg(long)]
    pub id: Option<String>,
}

impl RowFilterArgs {
    fn filter(&self) -> Result<RowFilter, GenozError> {
        let bad = |what: &str, v: &str| GenozError::InvalidParam(format!("{what} desconhecido: {v}"));
        let mut filter = RowFilter::default();
        for c in &self.category {
            filter.categories.push(Category::from_code(c).ok_or_else(|| bad("categoria", c))?);
        }
        for k in &self.kind {
            let kind: VariantKind =
                serde_json::from_value(serde_json::Value::String(k.clone())).map_err(|_| bad("tipo", k))?;
            filter.kinds.push(kind);
        }
        if let Some(r) = &self.region {
            filter.region = Some(parse_region(r).ok_or_else(|| bad("formato de região", r))?);
        }
        filter.id_contains = self.id.clone();
        Ok(filter)
    }
}

fn open_result(dir: &Path) -> Result<ResultReader<BufReader<File>>, GenozError> {
    let index = RowIndex::from_bytes(&std::fs::read(dir.join("rows.idx"))?)?;
    Ok(ResultReader::new(BufReader::new(File::open(dir.join("rows.bgz"))?), index))
}

#[derive(Args)]
pub struct ExportArgs {
    /// Pasta de resultado criada por `compare`.
    pub dir: PathBuf,
    #[arg(long)]
    pub out: PathBuf,
    /// csv, tsv, json ou vcf.
    #[arg(long, default_value = "csv")]
    pub format: String,
    #[command(flatten)]
    pub filter: RowFilterArgs,
}

pub fn export_cmd(args: ExportArgs) -> Result<(), GenozError> {
    let format: ExportFormat = serde_json::from_value(serde_json::Value::String(args.format.clone()))
        .map_err(|_| GenozError::InvalidParam(format!("formato desconhecido: {}", args.format)))?;
    let summary: serde_json::Value = serde_json::from_slice(&std::fs::read(args.dir.join("summary.json"))?)
        .map_err(|e| GenozError::InvalidParam(format!("summary.json inválido: {e}")))?;
    let name = |side: &str| summary[side]["sample"].as_str().unwrap_or(side).to_string();
    let mut reader = open_result(&args.dir)?;
    let out = std::io::BufWriter::new(File::create(&args.out)?);
    let n = export_rows(&mut reader, &args.filter.filter()?, format, (&name("a"), &name("b")), out)?;
    println!("{n} linhas exportadas para {}", args.out.display());
    Ok(())
}

pub fn view_cmd(args: ViewArgs) -> Result<(), GenozError> {
    let mut reader = open_result(&args.dir)?;
    let filter = args.filter.filter()?;

    let skip = (args.page.max(1) - 1) * args.page_size as u64;
    let (rows, total) = if filter == RowFilter::default() {
        (reader.page(skip, args.page_size)?, reader.total_rows())
    } else {
        reader.scan(&filter, skip, args.page_size)?
    };
    let pages = total.div_ceil(args.page_size.max(1) as u64).max(1);
    println!("{total} linhas — página {} de {pages}", args.page);
    println!("{:<6}{:>11}  {:<12}{:<12}{:<20}{:<10}{:<10}", "chrom", "pos", "ref", "alt", "categoria", "GT A", "GT B");
    for r in rows {
        let short = |s: &str| if s.len() > 10 { format!("{}…", &s[..9]) } else { s.to_string() };
        println!(
            "{:<6}{:>11}  {:<12}{:<12}{:<20}{:<10}{:<10}",
            r.chrom,
            r.pos,
            short(&r.reference),
            short(&r.alt),
            r.category.label(),
            r.a.gt.as_deref().unwrap_or("·"),
            r.b.gt.as_deref().unwrap_or("·")
        );
    }
    Ok(())
}

pub fn density_cmd(args: DensityArgs) -> Result<(), GenozError> {
    let mut reader = open_result(&args.dir)?;
    let filter = args.filter.filter()?;
    let map = genoz_core::density::density(&mut reader, &filter, args.bin)?;
    if args.json {
        println!("{}", serde_json::to_string_pretty(&map).map_err(|e| GenozError::InvalidParam(e.to_string()))?);
        return Ok(());
    }
    println!("{} linhas — faixas de {} pb", map.total, args.bin);
    println!("{:<6}{:>8}{:>14}  categorias", "chrom", "linhas", "maior pos");
    for c in &map.chroms {
        let cats: Vec<String> =
            c.counts.iter().map(|(cat, bins)| format!("{} {}", cat.label(), bins.iter().sum::<u32>())).collect();
        println!("{:<6}{:>8}{:>14}  {}", c.chrom, c.total, c.max_pos, cats.join(" · "));
    }
    Ok(())
}

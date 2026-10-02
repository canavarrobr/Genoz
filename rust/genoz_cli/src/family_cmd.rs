//! Módulo 12: `genoz-cli family` — parentesco, ROH, trio e interseções de um VCF multiamostra.

use std::fs::File;
use std::path::{Path, PathBuf};

use clap::Args;
use genoz_core::compare::to_json_bytes;
use genoz_core::family::{analyze_family, FamilyOptions, FamilyResult, Relation, TrioRoles};
use genoz_core::manifest::{InputRef, Manifest, OutputRef};
use genoz_core::GenozError;

use crate::analysis::{now_utc, QualityArgs};

#[derive(Args)]
pub struct FamilyArgs {
    /// VCF multiamostra com chamada conjunta
    pub vcf: PathBuf,
    /// Pasta do resultado (familia.json + manifest.json)
    #[arg(long)]
    pub out: PathBuf,
    /// Amostras, separadas por vírgula (padrão: todas, até 32)
    #[arg(long)]
    pub samples: Option<String>,
    /// Trio: FILHO,PAI,MAE (nomes das amostras)
    #[arg(long)]
    pub trio: Option<String>,
    #[command(flatten)]
    pub quality: QualityArgs,
}

pub fn relation_label(r: Relation) -> &'static str {
    match r {
        Relation::Duplicate => "mesma pessoa / gêmeos idênticos",
        Relation::ParentOffspring => "pai/mãe e filho(a)",
        Relation::FullSiblings => "irmãos",
        Relation::FirstDegree => "1º grau (pai/mãe–filho ou irmãos)",
        Relation::SecondDegree => "2º grau",
        Relation::ThirdDegree => "3º grau",
        Relation::Unrelated => "sem parentesco próximo",
        Relation::Insufficient => "dados insuficientes",
    }
}

/// Roda a análise e grava o resultado e o manifesto (usado também pelo `rerun`).
pub(crate) fn run_family(vcf: &Path, opts: &FamilyOptions, out: &Path) -> Result<(Manifest, FamilyResult), GenozError> {
    let result = analyze_family(File::open(vcf)?, opts)?;
    std::fs::create_dir_all(out)?;
    let bytes = to_json_bytes(&result);
    std::fs::write(out.join("familia.json"), &bytes)?;
    let d = genoz_core::digest::sha256_reader(File::open(vcf)?)?;
    let input = InputRef {
        role: "a".into(),
        name: vcf.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default(),
        sha256: d.sha256,
        bytes: d.bytes,
        build: None,
        sample: None,
    };
    let output = OutputRef {
        name: "familia.json".into(),
        sha256: genoz_core::digest::sha256_bytes(&bytes),
        bytes: bytes.len() as u64,
    };
    let platform = format!("cli-{}-{}", std::env::consts::OS, std::env::consts::ARCH);
    let parameters = genoz_core::family::manifest_parameters(opts);
    let manifest = Manifest::new("family", vec![input], parameters, vec![output], &platform, &now_utc());
    std::fs::write(out.join("manifest.json"), to_json_bytes(&manifest))?;
    Ok((manifest, result))
}

pub fn family_cmd(args: FamilyArgs) -> Result<(), GenozError> {
    let split = |s: &str| s.split(',').map(|x| x.trim().to_string()).filter(|x| !x.is_empty()).collect::<Vec<_>>();
    let trio = match &args.trio {
        Some(t) => match split(t).as_slice() {
            [c, f, m] => Some(TrioRoles { child: c.clone(), father: f.clone(), mother: m.clone() }),
            _ => return Err(GenozError::InvalidParam("--trio precisa de FILHO,PAI,MAE".into())),
        },
        None => None,
    };
    let opts = FamilyOptions {
        call_filter: args.quality.filter(),
        samples: args.samples.as_deref().map(split).unwrap_or_default(),
        trio,
        ..Default::default()
    };
    let (manifest, r) = run_family(&args.vcf, &opts, &args.out)?;
    let name = |i: usize| r.samples[i].as_str();
    println!("Família e populações — {} amostras, {} SNVs usados", r.samples.len(), r.sites.used);
    println!();
    println!("Parentesco (KING-robust):");
    for p in &r.pairs {
        let k = p.kinship.map_or("—".into(), |k| format!("{k:+.4}"));
        println!(
            "  {:<16} × {:<16} φ {k:>8}  IBS0 {:>6}  M {:>8}  {}",
            name(p.a),
            name(p.b),
            p.ibs0,
            p.sites,
            relation_label(p.relation)
        );
    }
    if r.roh_available {
        println!();
        println!("Runs of homozygosity:");
        for s in &r.roh {
            println!(
                "  {:<16} {:>3} trechos, {:>8.1} Mb, F_ROH {}",
                name(s.sample),
                s.runs.len(),
                s.total_kb as f64 / 1000.0,
                s.froh.map_or("—".into(), |f| format!("{f:.4}"))
            );
        }
    }
    if let Some(t) = &r.trio {
        println!();
        println!("Trio: filho(a) {}, pai {}, mãe {}", name(t.child), name(t.father), name(t.mother));
        println!("  sítios com os três genotipados: {}", t.sites);
        println!("  candidatas a de novo:           {}", t.de_novo_candidates);
        println!("  outros erros mendelianos:       {}", t.other_errors);
        println!("  alelos do pai / da mãe:          {} / {}", t.paternal, t.maternal);
    }
    for w in &r.warnings {
        println!("  aviso: {w}");
    }
    println!();
    println!("Estimativa estatística, sujeita a erro: não é teste de paternidade com valor legal nem diagnóstico.");
    println!("Resultado em {} — ID da análise {}", args.out.display(), manifest.analysis_id);
    Ok(())
}

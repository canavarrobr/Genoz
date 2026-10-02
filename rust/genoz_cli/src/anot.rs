//! `genoz-cli anot`: pacotes de anotação locais (Módulo 10).

use std::fs::File;
use std::path::PathBuf;

use clap::{Args, Subcommand, ValueEnum};
use genoz_core::annotation::{
    build_custom, build_genes_from_gtf, build_sites_from_vcf, clinvar_fields, open_package_dir, write_package_dir,
    PackageMeta,
};
use genoz_core::digest::sha256_reader;
use genoz_core::filter::parse_region;
use genoz_core::GenozError;

#[derive(Subcommand)]
pub enum AnotCommand {
    /// Constrói um pacote a partir de um GTF (genes), VCF (ClinVar) ou BED/TSV próprio.
    Build(Box<BuildArgs>),
    /// Mostra o manifesto de um pacote (fonte, versão, licença…).
    Info { dir: PathBuf },
    /// Registros que se sobrepõem a uma região (ex.: chr13:32315508-32400268).
    Query { dir: PathBuf, region: String },
    /// Procura um gene (ou outro nome) no pacote.
    Gene { dir: PathBuf, name: String },
}

#[derive(Clone, Copy, ValueEnum)]
pub enum From {
    /// GTF do GENCODE/Ensembl (linhas `gene`).
    Gtf,
    /// VCF mensal do ClinVar.
    Clinvar,
    /// BED ou TSV do usuário.
    Custom,
}

#[derive(Args)]
pub struct BuildArgs {
    #[arg(long, value_enum)]
    pub from: From,
    pub input: PathBuf,
    /// Pasta do pacote a criar.
    #[arg(long)]
    pub out: PathBuf,
    #[arg(long)]
    pub id: String,
    #[arg(long)]
    pub name: String,
    /// GRCh37 ou GRCh38.
    #[arg(long)]
    pub build: String,
    #[arg(long)]
    pub version: String,
    /// Data da versão da fonte (AAAA-MM-DD).
    #[arg(long)]
    pub date: String,
    #[arg(long)]
    pub source_url: Option<String>,
    /// Para `custom`: fonte, licença e citação livres.
    #[arg(long)]
    pub source: Option<String>,
    #[arg(long)]
    pub license: Option<String>,
    #[arg(long)]
    pub citation: Option<String>,
}

pub fn run(cmd: AnotCommand) -> Result<(), GenozError> {
    match cmd {
        AnotCommand::Build(a) => build(*a),
        AnotCommand::Info { dir } => {
            let p = open_package_dir(&dir)?;
            println!("{}", serde_json::to_string_pretty(&p.manifest).expect("serializável"));
            Ok(())
        }
        AnotCommand::Query { dir, region } => {
            let r =
                parse_region(&region).ok_or_else(|| GenozError::InvalidParam(format!("região inválida: {region}")))?;
            let mut p = open_package_dir(&dir)?;
            let hits = p.query(&r.chrom, r.start, r.end)?;
            print_hits(&p.manifest.fields, &hits);
            Ok(())
        }
        AnotCommand::Gene { dir, name } => {
            let mut p = open_package_dir(&dir)?;
            let hits = p.find_name(&name)?;
            print_hits(&p.manifest.fields, &hits);
            Ok(())
        }
    }
}

fn print_hits(fields: &[genoz_core::annotation::FieldDef], hits: &[genoz_core::annotation::AnnotRecord]) {
    println!("{} registros", hits.len());
    for h in hits.iter().take(200) {
        let extra: Vec<String> = fields
            .iter()
            .zip(&h.fields)
            .filter(|(_, v)| !v.is_empty())
            .map(|(f, v)| format!("{}={v}", f.key))
            .collect();
        println!("  {}:{}-{}  {} {}>{}  {}", h.chrom, h.start, h.end, h.name, h.reference, h.alt, extra.join("; "));
    }
}

fn build(a: BuildArgs) -> Result<(), GenozError> {
    let input_sha = sha256_reader(File::open(&a.input)?)?.sha256;
    let mut meta = PackageMeta {
        id: a.id,
        name: a.name,
        build: a.build,
        version: a.version,
        date: a.date,
        source_url: a.source_url.unwrap_or_default(),
        input_sha256: input_sha,
        ..Default::default()
    };
    let built = match a.from {
        From::Gtf => {
            meta.source = "GENCODE".into();
            meta.license = "Acesso aberto (EMBL-EBI: sem restrições adicionais; atribuição esperada)".into();
            meta.license_url = "https://www.ebi.ac.uk/about/terms-of-use".into();
            meta.citation = "Mudge JM et al. GENCODE 2025: reference gene annotation for human and mouse. \
                Nucleic Acids Res. 2025. https://www.gencodegenes.org"
                .into();
            build_genes_from_gtf(File::open(&a.input)?, meta)?
        }
        From::Clinvar => {
            meta.source = "ClinVar (NCBI)".into();
            meta.license = "Uso e redistribuição livres com atribuição ao ClinVar".into();
            meta.license_url = "https://www.ncbi.nlm.nih.gov/clinvar/docs/maintenance_use/".into();
            meta.citation = "Landrum MJ et al. ClinVar: improving access to variant interpretations and \
                supporting evidence. Nucleic Acids Res. 2018;46(D1):D1062-D1067. PMID 29165669"
                .into();
            meta.disclaimer = "O ClinVar não é para uso diagnóstico direto nem decisão médica sem revisão \
                de um profissional de genética; o NIH não verifica as informações enviadas."
                .into();
            build_sites_from_vcf(File::open(&a.input)?, clinvar_fields(), meta)?
        }
        From::Custom => {
            meta.source = a.source.unwrap_or_else(|| "arquivo do usuário".into());
            meta.license = a.license.unwrap_or_else(|| "do usuário".into());
            meta.citation = a.citation.unwrap_or_default();
            build_custom(File::open(&a.input)?, meta)?
        }
    };
    write_package_dir(&a.out, &built)?;
    println!(
        "pacote '{}' gravado em {}: {} registros ({} linhas ignoradas), {} bytes de dados",
        built.manifest.id,
        a.out.display(),
        built.manifest.records,
        built.skipped,
        built.records_bgz.len()
    );
    for i in built.issues.iter().take(10) {
        println!("  linha {}: {}", i.line, i.message);
    }
    Ok(())
}

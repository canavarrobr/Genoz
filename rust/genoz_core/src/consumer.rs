//! Arquivos brutos de testes de consumidor (chips de genotipagem):
//! 23andMe, AncestryDNA, MyHeritage e FamilyTreeDNA.
//!
//! Formatos (todos de texto, um sítio por linha, coordenadas 1-based):
//! - 23andMe: comentários `#`; `rsid<TAB>chromosome<TAB>position<TAB>genotype` (`AG`, `A`, `--`, `DI`…);
//! - AncestryDNA: comentários `#`; cabeçalho `rsid chromosome position allele1 allele2`;
//!   sem chamada = `0`; cromossomos 23 = X, 24 = Y, 25 = X (região pseudoautossômica), 26 = MT;
//! - MyHeritage e FamilyTreeDNA: CSV com aspas, `RSID,CHROMOSOME,POSITION,RESULT`.
//!
//! O formato é reconhecido pelo CONTEÚDO, não pela extensão. Os chips não dizem
//! qual é a base de referência: os genótipos ficam como letras (`AG`), e a
//! comparação com um VCF ([`crate::chip_compare`]) é feita por conjunto de letras.

use std::collections::BTreeMap;
use std::io::{BufRead, Read};

use serde::Serialize;

use crate::build::{BuildGuess, Confidence, GenomeBuild};
use crate::chrom::{canonical_chrom, chrom_sort_key, ChromStyle};
use crate::inspect::{ChromCount, InspectReport, SampleSummary, Verdict};
use crate::io::open_reader;
use crate::reader::{Issue, IssueCode, Severity};
use crate::record::VariantKind;
use crate::Result;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ChipVendor {
    #[serde(rename = "23andme")]
    TwentyThreeAndMe,
    AncestryDna,
    MyHeritage,
    FamilyTreeDna,
}

impl ChipVendor {
    pub fn label(self) -> &'static str {
        match self {
            ChipVendor::TwentyThreeAndMe => "23andMe",
            ChipVendor::AncestryDna => "AncestryDNA",
            ChipVendor::MyHeritage => "MyHeritage",
            ChipVendor::FamilyTreeDna => "FamilyTreeDNA",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Layout {
    /// rsid, chromosome, position, genotype (TAB)
    Tab4,
    /// rsid, chromosome, position, allele1, allele2 (TAB)
    Tab5,
    /// "RSID","CHROMOSOME","POSITION","RESULT" (vírgulas, aspas opcionais)
    Csv4,
}

/// Uma linha de dados de chip.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChipCall {
    pub rsid: String,
    /// Nome canônico (`1`..`22`, `X`, `Y`, `MT`).
    pub chrom: String,
    pub pos: u64,
    /// Letras maiúsculas (`ACGT`): 2 = diploide, 1 = haploide (X/Y/MT em homens), vazio = sem chamada.
    pub alleles: Vec<u8>,
    /// Inserção/deleção (`I`/`D`): sem posição de base comparável; ignorada na comparação.
    pub indel: bool,
    pub line: u64,
}

impl ChipCall {
    pub fn is_no_call(&self) -> bool {
        self.alleles.is_empty() && !self.indel
    }

    /// Genótipo em letras para mostrar (`A/G`, `A`, `--`).
    pub fn genotype_text(&self) -> String {
        if self.indel {
            return "indel".into();
        }
        if self.alleles.is_empty() {
            return "--".into();
        }
        self.alleles.iter().map(|&b| (b as char).to_string()).collect::<Vec<_>>().join("/")
    }
}

/// Informação do cabeçalho (comentários) de um arquivo de chip.
#[derive(Debug, Clone, Serialize)]
pub struct ChipHeader {
    pub vendor: ChipVendor,
    pub build: BuildGuess,
    /// O arquivo declara GRCh36/hg18 (não suportado).
    pub grch36: bool,
}

/// Reconhece um arquivo de chip pelas primeiras linhas. `None` = não é chip.
pub fn sniff(prefix: &str) -> Option<ChipVendor> {
    let mut vendor_hint = None;
    for raw in prefix.lines().take(60) {
        let line = raw.trim_start_matches('\u{feff}').trim();
        if line.is_empty() {
            continue;
        }
        let lower = line.to_ascii_lowercase();
        if line.starts_with("##fileformat=VCF") || line.starts_with("#CHROM") {
            return None;
        }
        if lower.contains("23andme") {
            vendor_hint.get_or_insert(ChipVendor::TwentyThreeAndMe);
        } else if lower.contains("ancestrydna") || lower.contains("ancestry.com") {
            vendor_hint.get_or_insert(ChipVendor::AncestryDna);
        } else if lower.contains("myheritage") {
            vendor_hint.get_or_insert(ChipVendor::MyHeritage);
        } else if lower.contains("familytreedna") || lower.contains("family tree dna") {
            vendor_hint.get_or_insert(ChipVendor::FamilyTreeDna);
        }
        if let Some(layout) = header_layout(line) {
            return Some(match (layout, vendor_hint) {
                (_, Some(v)) => v,
                (Layout::Tab5, None) => ChipVendor::AncestryDna,
                (Layout::Tab4, None) => ChipVendor::TwentyThreeAndMe,
                (Layout::Csv4, None) => ChipVendor::FamilyTreeDna,
            });
        }
        // Primeira linha de dados sem cabeçalho de colunas (alguns exportadores omitem).
        if !line.starts_with('#') {
            if let Some(layout) = data_layout(line) {
                return Some(vendor_hint.unwrap_or(match layout {
                    Layout::Tab4 => ChipVendor::TwentyThreeAndMe,
                    Layout::Tab5 => ChipVendor::AncestryDna,
                    Layout::Csv4 => ChipVendor::FamilyTreeDna,
                }));
            }
            return None;
        }
    }
    None
}

fn header_layout(line: &str) -> Option<Layout> {
    let l = line.trim_start_matches('#').trim().to_ascii_lowercase().replace('"', "");
    let cols: Vec<&str> = l.split(['\t', ',']).map(str::trim).collect();
    match cols.as_slice() {
        ["rsid", "chromosome", "position", "genotype"] => Some(Layout::Tab4),
        ["rsid", "chromosome", "position", "allele1", "allele2"] => Some(Layout::Tab5),
        ["rsid", "chromosome", "position", "result"] if l.contains(',') => Some(Layout::Csv4),
        ["rsid", "chromosome", "position", "result"] => Some(Layout::Tab4),
        _ => None,
    }
}

fn data_layout(line: &str) -> Option<Layout> {
    let looks_rsid = |s: &str| {
        let s = s.trim_matches('"');
        (s.starts_with("rs") || s.starts_with('i') || s.starts_with("VG")) && s.len() > 2
    };
    let tab: Vec<&str> = line.split('\t').collect();
    if tab.len() == 4 && looks_rsid(tab[0]) && tab[2].parse::<u64>().is_ok() {
        return Some(Layout::Tab4);
    }
    if tab.len() == 5 && looks_rsid(tab[0]) && tab[2].parse::<u64>().is_ok() {
        return Some(Layout::Tab5);
    }
    let csv: Vec<&str> = line.split(',').map(|s| s.trim().trim_matches('"')).collect();
    if csv.len() == 4 && looks_rsid(csv[0]) && csv[2].parse::<u64>().is_ok() {
        return Some(Layout::Csv4);
    }
    None
}

fn layout_for(vendor: ChipVendor, header: Option<Layout>) -> Layout {
    header.unwrap_or(match vendor {
        ChipVendor::TwentyThreeAndMe => Layout::Tab4,
        ChipVendor::AncestryDna => Layout::Tab5,
        ChipVendor::MyHeritage | ChipVendor::FamilyTreeDna => Layout::Csv4,
    })
}

/// Build declarado nos comentários; sem declaração, GRCh37 presumido (os quatro
/// fornecedores publicam em GRCh37) com confiança baixa.
fn build_from_comments(comments: &str) -> (BuildGuess, bool) {
    let t = comments.to_ascii_lowercase().replace(['_', '-'], " ");
    let has = |keys: &[&str]| keys.iter().any(|k| t.contains(k));
    if has(&["build 36", "build36", "ncbi36", "hg18", "grch36"]) {
        let evidence = vec!["o arquivo declara GRCh36/hg18 (anterior ao GRCh37)".into()];
        return (BuildGuess { build: GenomeBuild::Unknown, confidence: Confidence::None, evidence }, true);
    }
    if has(&["grch38", "build 38", "build38", "hg38"]) {
        let evidence = vec!["o arquivo declara GRCh38".into()];
        return (BuildGuess { build: GenomeBuild::Grch38, confidence: Confidence::High, evidence }, false);
    }
    if has(&["grch37", "build 37", "build37", "hg19", "37.1", "37.3"]) {
        let evidence = vec!["o arquivo declara GRCh37 (build 37)".into()];
        return (BuildGuess { build: GenomeBuild::Grch37, confidence: Confidence::High, evidence }, false);
    }
    let evidence = vec!["sem declaração de build; presumido GRCh37 (padrão dos fornecedores de chips)".into()];
    (BuildGuess { build: GenomeBuild::Grch37, confidence: Confidence::Low, evidence }, false)
}

/// Leitor de chip em streaming: consome os comentários na criação e depois
/// devolve uma linha de dados por vez.
pub struct ChipReader<'a> {
    inner: Box<dyn BufRead + 'a>,
    layout: Layout,
    header: ChipHeader,
    line_no: u64,
    pending: Option<(u64, String)>,
    buf: String,
}

/// Resultado de uma linha de dados: chamada ou problema.
pub type ChipLine = std::result::Result<ChipCall, Issue>;

impl<'a> ChipReader<'a> {
    /// `None` se a fonte não for um arquivo de chip reconhecido.
    pub fn new<R: Read + 'a>(source: R) -> Result<Option<Self>> {
        let (_, mut inner) = open_reader(source)?;
        let mut comments = String::new();
        let mut header_line = None;
        let mut pending = None;
        let mut line_no = 0u64;
        let mut seen = String::new();
        let mut buf = String::new();
        loop {
            buf.clear();
            if inner.read_line(&mut buf)? == 0 {
                break;
            }
            line_no += 1;
            let line = buf.trim_end_matches(['\n', '\r']).trim_start_matches('\u{feff}').to_string();
            if line.trim().is_empty() {
                continue;
            }
            seen.push_str(&line);
            seen.push('\n');
            if let Some(layout) = header_layout(&line) {
                header_line = Some(layout);
                if line.starts_with('#') {
                    comments.push_str(&line);
                    comments.push('\n');
                }
                continue;
            }
            if line.starts_with('#') {
                comments.push_str(&line);
                comments.push('\n');
                continue;
            }
            pending = Some((line_no, line));
            break;
        }
        let Some(vendor) = sniff(&seen) else { return Ok(None) };
        let (build, grch36) = build_from_comments(&comments);
        Ok(Some(Self {
            inner,
            layout: layout_for(vendor, header_line),
            header: ChipHeader { vendor, build, grch36 },
            line_no,
            pending,
            buf: String::new(),
        }))
    }

    pub fn header(&self) -> &ChipHeader {
        &self.header
    }

    /// Próxima linha de dados (`None` no fim do arquivo).
    pub fn next_line(&mut self) -> Result<Option<ChipLine>> {
        let (line_no, line) = match self.pending.take() {
            Some(p) => p,
            None => loop {
                self.buf.clear();
                if self.inner.read_line(&mut self.buf)? == 0 {
                    return Ok(None);
                }
                self.line_no += 1;
                let l = self.buf.trim_end_matches(['\n', '\r']);
                if l.trim().is_empty() || l.starts_with('#') {
                    continue;
                }
                break (self.line_no, l.to_string());
            },
        };
        Ok(Some(parse_line(&line, line_no, self.layout)))
    }
}

fn parse_line(line: &str, line_no: u64, layout: Layout) -> ChipLine {
    let err = |code, msg: String| Issue::error(line_no, code, msg);
    let cols: Vec<String> = match layout {
        Layout::Tab4 | Layout::Tab5 => line.split('\t').map(|s| s.trim().to_string()).collect(),
        Layout::Csv4 => line.split(',').map(|s| s.trim().trim_matches('"').to_string()).collect(),
    };
    let want = if layout == Layout::Tab5 { 5 } else { 4 };
    if cols.len() < want {
        return Err(err(IssueCode::TooFewColumns, format!("esperadas {want} colunas, encontradas {}", cols.len())));
    }
    let chrom = match cols[1].as_str() {
        "23" | "25" | "XY" => "X".to_string(),
        "24" => "Y".to_string(),
        "26" => "MT".to_string(),
        other => canonical_chrom(other),
    };
    let valid_chrom =
        chrom == "X" || chrom == "Y" || chrom == "MT" || chrom.parse::<u32>().is_ok_and(|n| (1..=22).contains(&n));
    if !valid_chrom {
        return Err(err(IssueCode::InvalidChrom, format!("cromossomo '{}' desconhecido", cols[1])));
    }
    let Ok(pos) = cols[2].parse::<u64>() else {
        return Err(err(IssueCode::InvalidPos, format!("posição '{}' não é um número", cols[2])));
    };
    if pos == 0 {
        return Err(err(IssueCode::InvalidPos, "posição 0 (as posições começam em 1)".into()));
    }
    let raw_gt: String = match layout {
        Layout::Tab5 => {
            let (a, b) = (cols[3].as_str(), cols[4].as_str());
            if a == "0" || b == "0" {
                String::new()
            } else {
                format!("{a}{b}")
            }
        }
        _ => cols[3].clone(),
    };
    let gt = raw_gt.to_ascii_uppercase();
    let (alleles, indel) = if gt.is_empty() || gt == "--" || gt == "-" || gt == "00" || gt == "NC" {
        (Vec::new(), false)
    } else if gt.bytes().all(|b| b == b'I' || b == b'D') && gt.len() <= 2 {
        (Vec::new(), true)
    } else if gt.len() <= 2 && gt.bytes().all(|b| matches!(b, b'A' | b'C' | b'G' | b'T')) {
        (gt.into_bytes(), false)
    } else {
        return Err(err(IssueCode::InvalidGenotype, format!("genótipo '{raw_gt}' inválido (esperado ex.: AG, A, --)")));
    };
    Ok(ChipCall { rsid: cols[0].clone(), chrom, pos, alleles, indel, line: line_no })
}

/// Informações específicas de chip no relatório de inspeção.
#[derive(Debug, Clone, Default, Serialize)]
pub struct ChipSummary {
    pub vendor: Option<ChipVendor>,
    pub vendor_label: String,
    pub sites: u64,
    pub called: u64,
    pub no_calls: u64,
    pub indels: u64,
    pub heterozygous: u64,
    pub homozygous: u64,
    pub haploid: u64,
    pub duplicate_positions: u64,
}

/// Inspeção de um arquivo de chip: o mesmo relatório do VCF (veredito, build,
/// cromossomos, problemas por linha) com `file_format = "chip:<fornecedor>"`
/// e o bloco [`ChipSummary`]. `None` se não for chip.
pub fn inspect_chip<R: Read>(source: R, max_issues: usize) -> Result<Option<(InspectReport, ChipSummary)>> {
    let Some(mut reader) = ChipReader::new(source)? else { return Ok(None) };
    let header = reader.header().clone();
    let mut summary =
        ChipSummary { vendor: Some(header.vendor), vendor_label: header.vendor.label().into(), ..Default::default() };
    let mut issues: Vec<Issue> = Vec::new();
    let mut issue_counts: BTreeMap<IssueCode, u64> = BTreeMap::new();
    let (mut errors, mut warnings, mut truncated) = (0u64, 0u64, false);
    let mut push = |i: Issue, issues: &mut Vec<Issue>| {
        *issue_counts.entry(i.code).or_default() += 1;
        match i.severity {
            Severity::Error => errors += 1,
            Severity::Warning => warnings += 1,
        }
        if issues.len() < max_issues {
            issues.push(i);
        } else {
            truncated = true;
        }
    };
    if header.grch36 {
        push(
            Issue::error(
                0,
                IssueCode::UnsupportedVersion,
                "arquivo em GRCh36/hg18: as posições não correspondem às do GRCh37/GRCh38".into(),
            ),
            &mut issues,
        );
    }

    let mut by_chrom: BTreeMap<String, u64> = BTreeMap::new();
    let mut sample = SampleSummary { name: header.vendor.label().into(), ..Default::default() };
    let (mut read, mut ok, mut rejected) = (0u64, 0u64, 0u64);
    let mut last: Option<(String, u64)> = None;
    let mut sorted = true;
    let mut fatal = None;
    loop {
        let item = match reader.next_line() {
            Ok(Some(item)) => item,
            Ok(None) => break,
            Err(e) => {
                fatal = Some(e.user_message());
                break;
            }
        };
        read += 1;
        match item {
            Err(issue) => {
                rejected += 1;
                push(issue, &mut issues);
            }
            Ok(call) => {
                ok += 1;
                summary.sites += 1;
                *by_chrom.entry(call.chrom.clone()).or_default() += 1;
                if let Some((c, p)) = &last {
                    if *c == call.chrom && call.pos == *p {
                        summary.duplicate_positions += 1;
                    } else if *c == call.chrom && call.pos < *p {
                        sorted = false;
                    }
                }
                last = Some((call.chrom.clone(), call.pos));
                if call.indel {
                    summary.indels += 1;
                } else if call.alleles.is_empty() {
                    summary.no_calls += 1;
                    sample.missing += 1;
                } else {
                    summary.called += 1;
                    match call.alleles.as_slice() {
                        [_] => summary.haploid += 1,
                        [a, b] if a != b => {
                            summary.heterozygous += 1;
                            sample.het += 1;
                        }
                        _ => summary.homozygous += 1,
                    }
                }
            }
        }
    }
    if summary.duplicate_positions > 0 {
        push(
            Issue {
                line: 0,
                severity: Severity::Warning,
                code: IssueCode::UnsortedPositions,
                message: format!(
                    "{} posições aparecem mais de uma vez (sondas diferentes); na comparação vale a primeira",
                    summary.duplicate_positions
                ),
            },
            &mut issues,
        );
    }
    let mut by_chrom: Vec<ChromCount> =
        by_chrom.into_iter().map(|(chrom, records)| ChromCount { raw: chrom.clone(), chrom, records }).collect();
    by_chrom.sort_by_key(|c| chrom_sort_key(&c.chrom));

    let verdict = if fatal.is_some() || ok == 0 || header.grch36 {
        Verdict::Invalid
    } else if rejected > 0 {
        Verdict::PartiallyValid
    } else if warnings > 0 {
        Verdict::ValidWithWarnings
    } else {
        Verdict::Valid
    };
    let report = InspectReport {
        core_version: crate::CORE_VERSION,
        digest: None,
        compression: crate::io::Compression::None,
        file_format: Some(format!("chip:{}", header.vendor.label())),
        build: header.build.clone(),
        chrom_style: ChromStyle::Ensembl,
        contigs_in_header: 0,
        info_fields: 0,
        format_fields: 0,
        samples: vec![sample],
        records_read: read,
        records_ok: ok,
        records_rejected: rejected,
        multiallelic: 0,
        biallelic_after_split: summary.called,
        by_kind: BTreeMap::from([(VariantKind::Snv, summary.called)]),
        by_chrom,
        filter_pass: 0,
        filter_failed: 0,
        filter_missing: 0,
        sorted,
        errors,
        warnings,
        issue_counts,
        issues,
        issues_truncated: truncated,
        fatal,
        verdict,
    };
    Ok(Some((report, summary)))
}

/// Carrega todas as chamadas de um chip (para a comparação), na ordem do arquivo.
pub fn read_chip<R: Read>(source: R) -> Result<Option<(ChipHeader, Vec<ChipCall>, u64)>> {
    let Some(mut reader) = ChipReader::new(source)? else { return Ok(None) };
    let header = reader.header().clone();
    let mut calls = Vec::new();
    let mut rejected = 0u64;
    while let Some(item) = reader.next_line()? {
        match item {
            Ok(c) => calls.push(c),
            Err(_) => rejected += 1,
        }
    }
    Ok(Some((header, calls, rejected)))
}

#[cfg(test)]
mod tests {
    use super::*;

    pub(crate) const T23: &str = "# This data file generated by 23andMe at: Mon Jan 01 2024\n\
# We are using reference human assembly build 37 (also known as Annotation Release 104).\n\
# rsid\tchromosome\tposition\tgenotype\n\
rs1\t1\t1000\tAG\n\
rs2\t1\t2000\tCC\n\
rs3\t1\t3000\t--\n\
i4\t1\t4000\tDI\n\
rs5\tX\t5000\tA\n\
rs6\tMT\t6000\tG\n";

    const ANCESTRY: &str = "#AncestryDNA raw data download\n\
#This file was generated by AncestryDNA at: 01/01/2024\n\
#Genotypes are reported on the forward (+) strand of build 37.1\n\
rsid\tchromosome\tposition\tallele1\tallele2\n\
rs1\t1\t1000\tA\tG\n\
rs2\t23\t2000\tC\tC\n\
rs3\t24\t3000\t0\t0\n\
rs4\t25\t4000\tT\tC\n\
rs5\t26\t5000\tA\tA\n";

    const MYHERITAGE: &str = "# MyHeritage DNA raw data.\n\
# This file was generated on 2024-01-01 using reference build 37.\n\
RSID,CHROMOSOME,POSITION,RESULT\n\
\"rs1\",\"1\",\"1000\",\"AG\"\n\
\"rs2\",\"2\",\"2000\",\"--\"\n";

    const FTDNA: &str = "RSID,CHROMOSOME,POSITION,RESULT\n\
\"rs1\",\"1\",\"1000\",\"AG\"\n\
\"rs2\",\"X\",\"2000\",\"TT\"\n";

    fn inspect(s: &str) -> (InspectReport, ChipSummary) {
        inspect_chip(s.as_bytes(), 100).unwrap().unwrap()
    }

    #[test]
    fn reconhece_os_quatro_formatos() {
        assert_eq!(sniff(T23), Some(ChipVendor::TwentyThreeAndMe));
        assert_eq!(sniff(ANCESTRY), Some(ChipVendor::AncestryDna));
        assert_eq!(sniff(MYHERITAGE), Some(ChipVendor::MyHeritage));
        assert_eq!(sniff(FTDNA), Some(ChipVendor::FamilyTreeDna));
        assert_eq!(sniff("##fileformat=VCFv4.3\n#CHROM\tPOS\n"), None);
        assert_eq!(sniff("qualquer coisa\n"), None);
    }

    #[test]
    fn le_23andme() {
        let (r, s) = inspect(T23);
        assert_eq!(r.file_format.as_deref(), Some("chip:23andMe"));
        assert_eq!((r.build.build, r.build.confidence), (GenomeBuild::Grch37, Confidence::High));
        assert_eq!((s.sites, s.called, s.no_calls, s.indels), (6, 4, 1, 1));
        assert_eq!((s.heterozygous, s.homozygous, s.haploid), (1, 1, 2));
        assert_eq!(r.verdict, Verdict::Valid);
        assert_eq!(r.by_chrom.iter().map(|c| c.chrom.as_str()).collect::<Vec<_>>(), ["1", "X", "MT"]);
    }

    #[test]
    fn ancestry_cromossomos_23_a_26() {
        let (_, header_calls, _) = read_chip(ANCESTRY.as_bytes()).unwrap().unwrap();
        let chroms: Vec<_> = header_calls.iter().map(|c| (c.chrom.as_str(), c.genotype_text())).collect();
        assert_eq!(
            chroms,
            [
                ("1", "A/G".to_string()),
                ("X", "C/C".into()),
                ("Y", "--".into()),
                ("X", "T/C".into()),
                ("MT", "A/A".into())
            ]
        );
    }

    #[test]
    fn csv_com_e_sem_comentarios() {
        let (r, s) = inspect(MYHERITAGE);
        assert_eq!(r.file_format.as_deref(), Some("chip:MyHeritage"));
        assert_eq!((s.called, s.no_calls), (1, 1));
        let (r, _) = inspect(FTDNA);
        assert_eq!(r.file_format.as_deref(), Some("chip:FamilyTreeDNA"));
        assert_eq!(r.build.confidence, Confidence::Low, "sem declaração: presumido");
    }

    #[test]
    fn linhas_ruins_viram_problemas_com_numero_da_linha() {
        let txt = "# 23andMe\n# rsid\tchromosome\tposition\tgenotype\nrs1\t1\t100\tAG\nrs2\t1\tabc\tAG\nrs3\t99\t5\tAA\nrs4\t1\t200\tXZ\n";
        let (r, _) = inspect(txt);
        assert_eq!(r.verdict, Verdict::PartiallyValid);
        let lines: Vec<u64> = r.issues.iter().map(|i| i.line).collect();
        assert_eq!(lines, [4, 5, 6]);
    }

    #[test]
    fn grch36_e_invalido() {
        let txt = "# 23andMe ... build 36\n# rsid\tchromosome\tposition\tgenotype\nrs1\t1\t100\tAG\n";
        let (r, _) = inspect(txt);
        assert_eq!(r.verdict, Verdict::Invalid);
    }
}

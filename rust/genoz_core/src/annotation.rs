//! Pacotes de anotação locais (Módulo 10).
//!
//! Um pacote é uma pasta com:
//! - `manifest.json` — fonte, versão, data, licença, citação, campos, hashes;
//! - `records.bgz`  — registros ordenados (cromossomo, início) em BGZF, uma linha TSV cada;
//! - `records.idx`  — índice JSON de blocos: cromossomo, menor início, maior fim e
//!   deslocamento virtual de cada bloco de [`RECORDS_PER_BLOCK`] registros.
//!
//! Dois tipos: `sites` (variantes: posição + REF/ALT, ex.: ClinVar) e `intervals`
//! (trechos: ex.: genes). Coordenadas 1-based e inclusivas.
//!
//! O Genoz não classifica variantes: os campos são mostrados como "o que a fonte diz".

use std::collections::HashMap;
use std::io::{BufRead, Read, Seek, Write};

use serde::{Deserialize, Serialize};

use crate::chrom::{canonical_chrom, chrom_sort_key};
use crate::io::{open_reader, BgzfReader, BgzfWriter};
use crate::reader::{Issue, IssueCode};
use crate::{GenozError, Result};

pub const PACKAGE_SCHEMA: u32 = 1;
pub const RECORDS_PER_BLOCK: usize = 256;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PackageKind {
    Sites,
    Intervals,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FieldDef {
    pub key: String,
    pub label_pt: String,
    pub label_en: String,
}

impl FieldDef {
    fn new(key: &str, pt: &str, en: &str) -> Self {
        Self { key: key.into(), label_pt: pt.into(), label_en: en.into() }
    }
}

/// Metadados de um pacote (a parte que o usuário vê: de onde veio e sob que licença).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PackageManifest {
    pub schema: u32,
    pub id: String,
    pub name: String,
    pub kind: PackageKind,
    /// `GRCh37` ou `GRCh38`.
    pub build: String,
    pub source: String,
    pub source_url: String,
    pub version: String,
    /// Data da versão da fonte (AAAA-MM-DD).
    pub date: String,
    pub license: String,
    pub license_url: String,
    pub citation: String,
    /// Aviso da própria fonte (ex.: "não é para uso diagnóstico direto").
    #[serde(default)]
    pub disclaimer: String,
    pub fields: Vec<FieldDef>,
    pub records: u64,
    /// SHA-256 do arquivo de origem (ex.: o VCF do ClinVar baixado).
    #[serde(default)]
    pub input_sha256: String,
    /// SHA-256 de `records.bgz`.
    #[serde(default)]
    pub data_sha256: String,
}

/// Um registro de anotação.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AnnotRecord {
    pub chrom: String,
    pub start: u64,
    pub end: u64,
    /// Vazio em pacotes de intervalos.
    pub reference: String,
    pub alt: String,
    pub name: String,
    /// Alinhado com `PackageManifest::fields`.
    pub fields: Vec<String>,
}

fn clean(s: &str) -> String {
    s.replace(['\t', '\n', '\r'], " ")
}

impl AnnotRecord {
    fn encode(&self) -> String {
        let mut cols = vec![
            self.chrom.clone(),
            self.start.to_string(),
            self.end.to_string(),
            clean(&self.reference),
            clean(&self.alt),
            clean(&self.name),
        ];
        cols.extend(self.fields.iter().map(|f| clean(f)));
        cols.join("\t")
    }

    fn decode(line: &str) -> Option<Self> {
        let mut it = line.split('\t');
        let chrom = it.next()?.to_string();
        let start = it.next()?.parse().ok()?;
        let end = it.next()?.parse().ok()?;
        let reference = it.next()?.to_string();
        let alt = it.next()?.to_string();
        let name = it.next()?.to_string();
        Some(Self { chrom, start, end, reference, alt, name, fields: it.map(str::to_string).collect() })
    }
}

/// Um bloco do índice: `[cromossomo, menor início, maior fim, deslocamento virtual, registros]`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Block(pub u32, pub u64, pub u64, pub u64, pub u32);

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct PackageIndex {
    pub chroms: Vec<String>,
    pub blocks: Vec<Block>,
}

/// Grava registros já ordenados por cromossomo (contíguo) e início.
pub struct PackageWriter<W: Write> {
    out: BgzfWriter<W>,
    index: PackageIndex,
    in_block: usize,
    records: u64,
    last: Option<(String, u64)>,
    n_fields: usize,
}

impl<W: Write> PackageWriter<W> {
    pub fn new(inner: W, n_fields: usize) -> Self {
        Self {
            out: BgzfWriter::new(inner),
            index: PackageIndex::default(),
            in_block: 0,
            records: 0,
            last: None,
            n_fields,
        }
    }

    pub fn push(&mut self, mut r: AnnotRecord) -> Result<()> {
        r.chrom = canonical_chrom(&r.chrom);
        r.fields.resize(self.n_fields, String::new());
        if r.end < r.start {
            r.end = r.start;
        }
        // Ordem: cada cromossomo num trecho contíguo, inícios crescentes.
        match &self.last {
            Some((c, p)) if *c == r.chrom && r.start < *p => {
                return Err(GenozError::InvalidParam(format!(
                    "registros fora de ordem em {}:{} (o arquivo precisa estar ordenado por posição)",
                    r.chrom, r.start
                )));
            }
            Some((c, _)) if *c != r.chrom && self.index.chroms.contains(&r.chrom) => {
                return Err(GenozError::InvalidParam(format!(
                    "o cromossomo {} aparece em trechos separados (o arquivo precisa estar ordenado)",
                    r.chrom
                )));
            }
            _ => {}
        }
        let chrom_changed = self.last.as_ref().is_none_or(|(c, _)| *c != r.chrom);
        if chrom_changed {
            self.index.chroms.push(r.chrom.clone());
        }
        let chrom_id = (self.index.chroms.len() - 1) as u32;
        if chrom_changed || self.in_block == RECORDS_PER_BLOCK {
            self.index.blocks.push(Block(chrom_id, r.start, r.end, self.out.virtual_offset(), 0));
            self.in_block = 0;
        }
        let b = self.index.blocks.last_mut().expect("bloco aberto");
        b.2 = b.2.max(r.end);
        b.4 += 1;
        writeln!(self.out, "{}", r.encode())?;
        self.in_block += 1;
        self.records += 1;
        self.last = Some((r.chrom, r.start));
        Ok(())
    }

    /// Devolve (saída, índice, número de registros).
    pub fn finish(self) -> Result<(W, PackageIndex, u64)> {
        Ok((self.out.finish()?, self.index, self.records))
    }
}

/// Pacote aberto para consulta.
pub struct AnnotationPackage<R: Read + Seek> {
    pub manifest: PackageManifest,
    index: PackageIndex,
    bgzf: BgzfReader<R>,
}

impl<R: Read + Seek> AnnotationPackage<R> {
    pub fn new(manifest: PackageManifest, index: PackageIndex, records: R) -> Result<Self> {
        if manifest.schema > PACKAGE_SCHEMA {
            return Err(GenozError::InvalidParam(format!(
                "pacote '{}' feito por uma versão mais nova do Genoz",
                manifest.name
            )));
        }
        Ok(Self { manifest, index, bgzf: BgzfReader::new(records) })
    }

    fn read_block(&mut self, b: &Block) -> Result<Vec<AnnotRecord>> {
        self.bgzf.seek_virtual(b.3)?;
        let mut reader = std::io::BufReader::new(&mut self.bgzf);
        let mut out = Vec::with_capacity(b.4 as usize);
        let mut line = String::new();
        for _ in 0..b.4 {
            line.clear();
            if reader.read_line(&mut line)? == 0 {
                break;
            }
            if let Some(r) = AnnotRecord::decode(line.trim_end_matches(['\n', '\r'])) {
                out.push(r);
            }
        }
        Ok(out)
    }

    /// Registros que se sobrepõem a `chrom:start-end`.
    pub fn query(&mut self, chrom: &str, start: u64, end: u64) -> Result<Vec<AnnotRecord>> {
        let c = canonical_chrom(chrom);
        let Some(cid) = self.index.chroms.iter().position(|x| *x == c) else { return Ok(Vec::new()) };
        let blocks: Vec<Block> =
            self.index.blocks.iter().filter(|b| b.0 == cid as u32 && b.1 <= end && b.2 >= start).cloned().collect();
        let mut out = Vec::new();
        for b in &blocks {
            out.extend(self.read_block(b)?.into_iter().filter(|r| r.start <= end && r.end >= start));
        }
        Ok(out)
    }

    /// Variantes exatamente nesta posição com este REF/ALT (pacotes `sites`).
    pub fn sites(&mut self, chrom: &str, pos: u64, reference: &str, alt: &str) -> Result<Vec<AnnotRecord>> {
        Ok(self
            .query(chrom, pos, pos)?
            .into_iter()
            .filter(|r| {
                r.start == pos && r.reference.eq_ignore_ascii_case(reference) && r.alt.eq_ignore_ascii_case(alt)
            })
            .collect())
    }

    /// Registros com este nome (sem diferenciar maiúsculas), na ordem do pacote.
    pub fn find_name(&mut self, name: &str) -> Result<Vec<AnnotRecord>> {
        let wanted = name.trim().to_ascii_uppercase();
        let blocks = self.index.blocks.clone();
        let mut out = Vec::new();
        for b in &blocks {
            out.extend(self.read_block(b)?.into_iter().filter(|r| r.name.to_ascii_uppercase() == wanted));
        }
        Ok(out)
    }

    /// Anotação de uma variante: intervalos que a contêm ou sítios idênticos.
    pub fn annotate(&mut self, chrom: &str, pos: u64, reference: &str, alt: &str) -> Result<Vec<AnnotRecord>> {
        match self.manifest.kind {
            PackageKind::Intervals => {
                let end = pos + reference.len().max(1) as u64 - 1;
                self.query(chrom, pos, end)
            }
            PackageKind::Sites => self.sites(chrom, pos, reference, alt),
        }
    }
}

// ---------------------------------------------------------------------------
// Construtores
// ---------------------------------------------------------------------------

/// Metadados informados por quem constrói o pacote.
#[derive(Debug, Clone, Default)]
pub struct PackageMeta {
    pub id: String,
    pub name: String,
    pub build: String,
    pub source: String,
    pub source_url: String,
    pub version: String,
    pub date: String,
    pub license: String,
    pub license_url: String,
    pub citation: String,
    pub disclaimer: String,
    pub input_sha256: String,
}

/// Pacote construído em memória (o chamador grava os três arquivos).
pub struct BuiltPackage {
    pub manifest: PackageManifest,
    pub records_bgz: Vec<u8>,
    pub index: PackageIndex,
    /// Linhas ignoradas e por quê (limitado).
    pub issues: Vec<Issue>,
    pub skipped: u64,
}

fn finish_build(
    meta: PackageMeta,
    kind: PackageKind,
    fields: Vec<FieldDef>,
    mut records: Vec<AnnotRecord>,
    sort: bool,
    issues: Vec<Issue>,
    skipped: u64,
) -> Result<BuiltPackage> {
    if sort {
        records.sort_by(|a, b| {
            chrom_sort_key(&canonical_chrom(&a.chrom))
                .cmp(&chrom_sort_key(&canonical_chrom(&b.chrom)))
                .then(a.start.cmp(&b.start))
                .then(a.end.cmp(&b.end))
        });
    }
    let mut w = PackageWriter::new(Vec::new(), fields.len());
    for r in records {
        w.push(r)?;
    }
    let (records_bgz, index, n) = w.finish()?;
    if n == 0 {
        return Err(GenozError::InvalidParam("nenhum registro válido para o pacote".into()));
    }
    let manifest = PackageManifest {
        schema: PACKAGE_SCHEMA,
        id: meta.id,
        name: meta.name,
        kind,
        build: meta.build,
        source: meta.source,
        source_url: meta.source_url,
        version: meta.version,
        date: meta.date,
        license: meta.license,
        license_url: meta.license_url,
        citation: meta.citation,
        disclaimer: meta.disclaimer,
        fields,
        records: n,
        input_sha256: meta.input_sha256,
        data_sha256: crate::digest::sha256_bytes(&records_bgz),
    };
    Ok(BuiltPackage { manifest, records_bgz, index, issues, skipped })
}

const MAX_ISSUES: usize = 200;

fn note(issues: &mut Vec<Issue>, skipped: &mut u64, line: u64, code: IssueCode, msg: String) {
    *skipped += 1;
    if issues.len() < MAX_ISSUES {
        issues.push(Issue::error(line, code, msg));
    }
}

/// Genes de um GTF (GENCODE/Ensembl): linhas `gene`, nome = `gene_name`.
pub fn build_genes_from_gtf<R: Read>(source: R, meta: PackageMeta) -> Result<BuiltPackage> {
    let (_, reader) = open_reader(source)?;
    let attr = |attrs: &str, key: &str| -> String {
        attrs
            .split(';')
            .filter_map(|kv| {
                let kv = kv.trim();
                let (k, v) = kv.split_once(' ')?;
                (k == key).then(|| v.trim().trim_matches('"').to_string())
            })
            .next()
            .unwrap_or_default()
    };
    let (mut records, mut issues, mut skipped) = (Vec::new(), Vec::new(), 0u64);
    for (i, line) in reader.lines().enumerate() {
        let line = line?;
        if line.starts_with('#') || line.trim().is_empty() {
            continue;
        }
        let c: Vec<&str> = line.split('\t').collect();
        if c.len() < 9 {
            note(
                &mut issues,
                &mut skipped,
                i as u64 + 1,
                IssueCode::TooFewColumns,
                "linha GTF com menos de 9 colunas".into(),
            );
            continue;
        }
        if c[2] != "gene" {
            continue;
        }
        let (Ok(start), Ok(end)) = (c[3].parse::<u64>(), c[4].parse::<u64>()) else {
            note(&mut issues, &mut skipped, i as u64 + 1, IssueCode::InvalidPos, "início/fim inválidos".into());
            continue;
        };
        let name = attr(c[8], "gene_name");
        records.push(AnnotRecord {
            chrom: c[0].into(),
            start,
            end,
            reference: String::new(),
            alt: String::new(),
            name: if name.is_empty() { attr(c[8], "gene_id") } else { name },
            fields: vec![attr(c[8], "gene_id"), attr(c[8], "gene_type"), c[6].into()],
        });
    }
    let fields = vec![
        FieldDef::new("gene_id", "ID do gene", "Gene ID"),
        FieldDef::new("gene_type", "Tipo", "Type"),
        FieldDef::new("strand", "Fita", "Strand"),
    ];
    finish_build(meta, PackageKind::Intervals, fields, records, true, issues, skipped)
}

/// Campos do ClinVar guardados no pacote.
pub fn clinvar_fields() -> Vec<FieldDef> {
    vec![
        FieldDef::new("CLNSIG", "Significado clínico (segundo o ClinVar)", "Clinical significance (per ClinVar)"),
        FieldDef::new("CLNREVSTAT", "Status de revisão", "Review status"),
        FieldDef::new("CLNDN", "Condição", "Condition"),
        FieldDef::new("GENEINFO", "Gene", "Gene"),
        FieldDef::new("RS", "rsID", "rsID"),
    ]
}

/// Sítios de um VCF de anotação (ex.: ClinVar), com os campos INFO pedidos.
/// Precisa estar ordenado (como o VCF oficial do ClinVar); nome = coluna ID.
pub fn build_sites_from_vcf<R: Read>(source: R, fields: Vec<FieldDef>, meta: PackageMeta) -> Result<BuiltPackage> {
    let (_, reader) = open_reader(source)?;
    let mut w = PackageWriter::new(Vec::new(), fields.len());
    let (mut issues, mut skipped) = (Vec::new(), 0u64);
    let mut saw_header = false;
    for (i, line) in reader.lines().enumerate() {
        let line = line?;
        if line.starts_with("##") {
            continue;
        }
        if line.starts_with("#CHROM") {
            saw_header = true;
            continue;
        }
        if line.trim().is_empty() {
            continue;
        }
        if !saw_header {
            return Err(GenozError::InvalidHeader("linha #CHROM não encontrada".into()));
        }
        let c: Vec<&str> = line.splitn(9, '\t').collect();
        if c.len() < 8 {
            note(&mut issues, &mut skipped, i as u64 + 1, IssueCode::TooFewColumns, "menos de 8 colunas".into());
            continue;
        }
        let Ok(pos) = c[1].parse::<u64>() else {
            note(&mut issues, &mut skipped, i as u64 + 1, IssueCode::InvalidPos, "posição inválida".into());
            continue;
        };
        let (reference, alts) = (c[3], c[4]);
        if alts == "." {
            continue; // sem ALT: nada a anotar por variante
        }
        let info: HashMap<&str, &str> =
            c[7].split(';').filter_map(|kv| kv.split_once('=').or(Some((kv, "")))).collect();
        let values: Vec<String> =
            fields.iter().map(|f| info.get(f.key.as_str()).copied().unwrap_or("").to_string()).collect();
        for alt in alts.split(',') {
            w.push(AnnotRecord {
                chrom: c[0].into(),
                start: pos,
                end: pos + reference.len().max(1) as u64 - 1,
                reference: reference.into(),
                alt: alt.into(),
                name: c[2].into(),
                fields: values.clone(),
            })?;
        }
    }
    let (records_bgz, index, n) = w.finish()?;
    if n == 0 {
        return Err(GenozError::InvalidParam("nenhum registro válido para o pacote".into()));
    }
    let manifest = PackageManifest {
        schema: PACKAGE_SCHEMA,
        id: meta.id,
        name: meta.name,
        kind: PackageKind::Sites,
        build: meta.build,
        source: meta.source,
        source_url: meta.source_url,
        version: meta.version,
        date: meta.date,
        license: meta.license,
        license_url: meta.license_url,
        citation: meta.citation,
        disclaimer: meta.disclaimer,
        fields,
        records: n,
        input_sha256: meta.input_sha256,
        data_sha256: crate::digest::sha256_bytes(&records_bgz),
    };
    Ok(BuiltPackage { manifest, records_bgz, index, issues, skipped })
}

/// Pacote personalizado: BED (0-based, `chrom start end [nome] [...]`) ou TSV com
/// cabeçalho `chrom start end [nome] [colunas...]` (1-based, inclusivo).
pub fn build_custom<R: Read>(source: R, meta: PackageMeta) -> Result<BuiltPackage> {
    let (_, reader) = open_reader(source)?;
    let mut lines = Vec::new();
    for l in reader.lines() {
        lines.push(l?);
    }
    let first_data = lines.iter().position(|l| {
        !l.trim().is_empty() && !l.starts_with('#') && !l.starts_with("track") && !l.starts_with("browser")
    });
    let header: Option<Vec<String>> = first_data.and_then(|i| {
        let cols: Vec<String> = lines[i].split('\t').map(|s| s.trim().to_ascii_lowercase()).collect();
        (cols.first().map(String::as_str) == Some("chrom") || cols.first().map(String::as_str) == Some("chr"))
            .then_some(cols)
    });
    let tsv = header.is_some();
    let extra: Vec<String> = header.as_ref().map(|h| h.iter().skip(4).cloned().collect()).unwrap_or_default();
    let fields: Vec<FieldDef> = extra.iter().map(|k| FieldDef::new(k, k, k)).collect();
    let (mut records, mut issues, mut skipped) = (Vec::new(), Vec::new(), 0u64);
    for (i, line) in lines.iter().enumerate() {
        if Some(i) == first_data && tsv {
            continue;
        }
        let t = line.trim_end_matches('\r');
        if t.trim().is_empty() || t.starts_with('#') || t.starts_with("track") || t.starts_with("browser") {
            continue;
        }
        let c: Vec<&str> = t.split('\t').collect();
        if c.len() < 3 {
            note(
                &mut issues,
                &mut skipped,
                i as u64 + 1,
                IssueCode::TooFewColumns,
                "esperadas ao menos 3 colunas (cromossomo, início, fim)".into(),
            );
            continue;
        }
        let (Ok(s), Ok(e)) = (c[1].trim().parse::<u64>(), c[2].trim().parse::<u64>()) else {
            note(&mut issues, &mut skipped, i as u64 + 1, IssueCode::InvalidPos, "início/fim não são números".into());
            continue;
        };
        // BED é 0-based semiaberto; o TSV do Genoz é 1-based inclusivo.
        let (start, end) = if tsv { (s, e) } else { (s + 1, e) };
        if start == 0 || end < start {
            note(&mut issues, &mut skipped, i as u64 + 1, IssueCode::InvalidPos, "início maior que o fim".into());
            continue;
        }
        records.push(AnnotRecord {
            chrom: c[0].trim().into(),
            start,
            end,
            reference: String::new(),
            alt: String::new(),
            name: c.get(3).map(|s| s.trim().to_string()).unwrap_or_default(),
            fields: if tsv { c.iter().skip(4).map(|s| s.trim().to_string()).collect() } else { Vec::new() },
        });
    }
    finish_build(meta, PackageKind::Intervals, fields, records, true, issues, skipped)
}

/// Grava um pacote construído numa pasta (`manifest.json`, `records.bgz`, `records.idx`).
pub fn write_package_dir(dir: &std::path::Path, built: &BuiltPackage) -> Result<()> {
    std::fs::create_dir_all(dir)?;
    std::fs::write(dir.join("records.bgz"), &built.records_bgz)?;
    std::fs::write(dir.join("records.idx"), serde_json::to_vec(&built.index).expect("serializável"))?;
    std::fs::write(dir.join("manifest.json"), serde_json::to_vec_pretty(&built.manifest).expect("serializável"))?;
    Ok(())
}

/// Abre um pacote gravado numa pasta.
pub fn open_package_dir(dir: &std::path::Path) -> Result<AnnotationPackage<std::io::BufReader<std::fs::File>>> {
    let manifest: PackageManifest = serde_json::from_slice(&std::fs::read(dir.join("manifest.json"))?)
        .map_err(|e| GenozError::InvalidParam(format!("manifesto do pacote inválido: {e}")))?;
    let index: PackageIndex = serde_json::from_slice(&std::fs::read(dir.join("records.idx"))?)
        .map_err(|e| GenozError::InvalidParam(format!("índice do pacote inválido: {e}")))?;
    let records = std::io::BufReader::new(std::fs::File::open(dir.join("records.bgz"))?);
    AnnotationPackage::new(manifest, index, records)
}

/// Abre um pacote a partir dos bytes dos três arquivos (Web).
pub fn open_package_bytes(
    manifest_json: &[u8],
    index_json: &[u8],
    records: Vec<u8>,
) -> Result<AnnotationPackage<std::io::Cursor<Vec<u8>>>> {
    let manifest: PackageManifest = serde_json::from_slice(manifest_json)
        .map_err(|e| GenozError::InvalidParam(format!("manifesto do pacote inválido: {e}")))?;
    let index: PackageIndex = serde_json::from_slice(index_json)
        .map_err(|e| GenozError::InvalidParam(format!("índice do pacote inválido: {e}")))?;
    AnnotationPackage::new(manifest, index, std::io::Cursor::new(records))
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use super::*;

    fn meta(id: &str) -> PackageMeta {
        PackageMeta { id: id.into(), name: id.into(), build: "GRCh38".into(), ..Default::default() }
    }

    fn open(b: &BuiltPackage) -> AnnotationPackage<Cursor<Vec<u8>>> {
        AnnotationPackage::new(b.manifest.clone(), b.index.clone(), Cursor::new(b.records_bgz.clone())).unwrap()
    }

    const GTF: &str = "##description: teste\n\
chr1\tHAVANA\tgene\t11869\t14409\t.\t+\t.\tgene_id \"ENSG01\"; gene_type \"lncRNA\"; gene_name \"DDX11L2\";\n\
chr1\tHAVANA\ttranscript\t11869\t14409\t.\t+\t.\tgene_id \"ENSG01\"; gene_name \"DDX11L2\";\n\
chr13\tHAVANA\tgene\t32315508\t32400268\t.\t+\t.\tgene_id \"ENSG02\"; gene_type \"protein_coding\"; gene_name \"BRCA2\";\n\
chr1\tHAVANA\tgene\t65419\t71585\t.\t+\t.\tgene_id \"ENSG03\"; gene_type \"protein_coding\"; gene_name \"OR4F5\";\n";

    #[test]
    fn genes_do_gtf_ordenados_e_por_nome() {
        let b = build_genes_from_gtf(GTF.as_bytes(), meta("genes")).unwrap();
        assert_eq!(b.manifest.records, 3);
        assert_eq!(b.manifest.kind, PackageKind::Intervals);
        let mut p = open(&b);
        let hits = p.query("1", 70000, 70000).unwrap();
        assert_eq!(hits.iter().map(|r| r.name.as_str()).collect::<Vec<_>>(), ["OR4F5"]);
        let brca2 = p.find_name("brca2").unwrap();
        assert_eq!((brca2[0].chrom.as_str(), brca2[0].start, brca2[0].end), ("13", 32315508, 32400268));
        assert_eq!(brca2[0].fields, ["ENSG02", "protein_coding", "+"]);
        assert!(p.query("13", 1, 100).unwrap().is_empty());
        assert!(p.query("X", 1, 1_000_000_000).unwrap().is_empty());
    }

    const CLINVAR: &str = "##fileformat=VCFv4.1\n\
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n\
1\t69134\t2205837\tA\tG\t.\t.\tCLNSIG=Likely_benign;CLNREVSTAT=criteria_provided,_single_submitter;GENEINFO=OR4F5:79501;RS=781394307\n\
1\t69581\t2252161\tC\tG\t.\t.\tCLNSIG=Uncertain_significance;CLNDN=not_specified\n\
1\t69581\t9999\tC\tT\t.\t.\tCLNSIG=Benign\n\
2\t100\t1\tA\t.\t.\t.\tCLNSIG=Benign\n";

    #[test]
    fn sitios_do_clinvar_casam_por_posicao_ref_e_alt() {
        let b = build_sites_from_vcf(CLINVAR.as_bytes(), clinvar_fields(), meta("clinvar")).unwrap();
        assert_eq!(b.manifest.records, 3, "ALT '.' fica de fora");
        let mut p = open(&b);
        let hit = p.annotate("chr1", 69581, "C", "G").unwrap();
        assert_eq!(hit.len(), 1);
        assert_eq!(hit[0].fields[0], "Uncertain_significance");
        assert_eq!(hit[0].fields[2], "not_specified");
        assert!(p.annotate("1", 69581, "C", "A").unwrap().is_empty(), "outro ALT não casa");
        assert_eq!(p.annotate("1", 69134, "A", "G").unwrap()[0].fields[4], "781394307");
    }

    #[test]
    fn indice_com_muitos_blocos_igual_a_busca_linear() {
        let mut lines = String::from("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n");
        for chrom in ["1", "2"] {
            for i in 0..2000u64 {
                lines.push_str(&format!("{chrom}\t{}\tv{i}\tA\tG\t.\t.\tCLNSIG=x{i}\n", 1000 + i * 7));
            }
        }
        let b = build_sites_from_vcf(lines.as_bytes(), clinvar_fields(), meta("grande")).unwrap();
        assert!(b.index.blocks.len() > 10);
        let mut p = open(&b);
        for (s, e) in [(1000, 1000), (1000, 5000), (13990, 14100), (9000, 12000)] {
            let fast: Vec<u64> = p.query("2", s, e).unwrap().iter().map(|r| r.start).collect();
            let slow: Vec<u64> = (0..2000u64).map(|i| 1000 + i * 7).filter(|&x| x >= s && x <= e).collect();
            assert_eq!(fast, slow, "{s}-{e}");
        }
    }

    #[test]
    fn vcf_fora_de_ordem_e_recusado() {
        let v = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n1\t500\t.\tA\tG\t.\t.\t.\n1\t100\t.\tA\tG\t.\t.\t.\n";
        assert!(build_sites_from_vcf(v.as_bytes(), clinvar_fields(), meta("x")).is_err());
    }

    #[test]
    fn bed_e_tsv_do_usuario() {
        let bed = "track name=aula\nchr7\t117480024\t117668665\tCFTR\nchr7\t1\tx\tquebrado\n";
        let b = build_custom(bed.as_bytes(), meta("bed")).unwrap();
        assert_eq!((b.manifest.records, b.skipped), (1, 1));
        assert_eq!(b.issues[0].line, 3);
        let mut p = open(&b);
        let r = &p.find_name("cftr").unwrap()[0];
        assert_eq!((r.start, r.end), (117480025, 117668665), "BED 0-based vira 1-based");

        let tsv = "chrom\tstart\tend\tnome\tdisciplina\n7\t100\t200\tGENE_A\tGenética I\n";
        let b = build_custom(tsv.as_bytes(), meta("tsv")).unwrap();
        assert_eq!(b.manifest.fields[0].key, "disciplina");
        let mut p = open(&b);
        let r = &p.query("7", 100, 100).unwrap()[0];
        assert_eq!((r.start, r.name.as_str(), r.fields[0].as_str()), (100, "GENE_A", "Genética I"));
    }

    #[test]
    fn pacote_gravado_em_pasta_e_reaberto() {
        let b = build_genes_from_gtf(GTF.as_bytes(), meta("genes")).unwrap();
        let dir = std::env::temp_dir().join(format!("genoz_anot_{}", std::process::id()));
        write_package_dir(&dir, &b).unwrap();
        let mut p = open_package_dir(&dir).unwrap();
        assert_eq!(p.manifest.data_sha256, crate::digest::sha256_bytes(&b.records_bgz));
        assert_eq!(p.find_name("OR4F5").unwrap().len(), 1);
        std::fs::remove_dir_all(&dir).ok();
    }
}

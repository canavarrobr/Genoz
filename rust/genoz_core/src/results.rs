//! Armazenamento paginável das linhas de comparação.
//!
//! - `rows.bgz`: uma linha TSV por resultado, compactada em BGZF;
//! - `rows.idx`: offset virtual BGZF a cada [`ROWS_PER_MARK`] linhas.
//!
//! Abrir a página N lê só um ou dois blocos de ~64 KiB, então a tabela do
//! app rola por milhões de linhas sem carregar o arquivo inteiro.

use std::io::{BufRead, BufReader, Read, Seek, Write};

use crate::call::FilterState;
use crate::compare::{Category, ComparisonRow, SideState, SideView};
use crate::filter::RowFilter;
use crate::io::{BgzfReader, BgzfWriter};
use crate::record::VariantKind;
use crate::{GenozError, Result};

pub const ROWS_PER_MARK: u64 = 1024;
const INDEX_MAGIC: &[u8; 8] = b"GENOZIX1";

/// Cabeçalho da primeira linha de `rows.bgz` (documenta as colunas).
pub const TSV_HEADER: &str = "#chrom\tpos\tref\talt\tkind\tcategory\tids\t\
a_state\ta_gt\ta_qual\ta_dp\ta_gq\ta_filter\tb_state\tb_gt\tb_qual\tb_dp\tb_gq\tb_filter";

fn kind_code(k: VariantKind) -> &'static str {
    match k {
        VariantKind::Snv => "snv",
        VariantKind::Mnv => "mnv",
        VariantKind::Insertion => "insertion",
        VariantKind::Deletion => "deletion",
        VariantKind::Complex => "complex",
        VariantKind::Structural => "structural",
        VariantKind::Other => "other",
    }
}

fn kind_from(s: &str) -> Option<VariantKind> {
    [
        VariantKind::Snv,
        VariantKind::Mnv,
        VariantKind::Insertion,
        VariantKind::Deletion,
        VariantKind::Complex,
        VariantKind::Structural,
        VariantKind::Other,
    ]
    .into_iter()
    .find(|k| kind_code(*k) == s)
}

fn filter_code(f: Option<FilterState>) -> &'static str {
    match f {
        None => ".",
        Some(FilterState::Pass) => "pass",
        Some(FilterState::NotApplied) => "not_applied",
        Some(FilterState::Failed) => "failed",
    }
}

fn filter_from(s: &str) -> Option<Option<FilterState>> {
    Some(match s {
        "." => None,
        "pass" => Some(FilterState::Pass),
        "not_applied" => Some(FilterState::NotApplied),
        "failed" => Some(FilterState::Failed),
        _ => return None,
    })
}

fn opt<T: ToString>(v: &Option<T>) -> String {
    v.as_ref().map_or_else(|| ".".to_string(), ToString::to_string)
}

fn side_fields(s: &SideView, out: &mut Vec<String>) {
    out.push(s.state.code().into());
    out.push(opt(&s.gt));
    out.push(opt(&s.qual));
    out.push(opt(&s.dp));
    out.push(opt(&s.gq));
    out.push(filter_code(s.filter).into());
}

pub fn encode_row(row: &ComparisonRow) -> String {
    let mut f = vec![
        row.chrom.clone(),
        row.pos.to_string(),
        row.reference.clone(),
        row.alt.clone(),
        kind_code(row.kind).into(),
        row.category.code().into(),
        if row.ids.is_empty() { ".".into() } else { row.ids.join(";") },
    ];
    side_fields(&row.a, &mut f);
    side_fields(&row.b, &mut f);
    f.join("\t")
}

pub fn decode_row(line: &str) -> Option<ComparisonRow> {
    let f: Vec<&str> = line.trim_end_matches(['\n', '\r']).split('\t').collect();
    if f.len() != 19 {
        return None;
    }
    let parse_opt = |s: &str| (s != ".").then(|| s.to_string());
    let side = |o: usize| -> Option<SideView> {
        Some(SideView {
            state: SideState::from_code(f[o])?,
            gt: parse_opt(f[o + 1]),
            qual: if f[o + 2] == "." { None } else { Some(f[o + 2].parse().ok()?) },
            dp: if f[o + 3] == "." { None } else { Some(f[o + 3].parse().ok()?) },
            gq: if f[o + 4] == "." { None } else { Some(f[o + 4].parse().ok()?) },
            filter: filter_from(f[o + 5])?,
        })
    };
    Some(ComparisonRow {
        chrom: f[0].into(),
        pos: f[1].parse().ok()?,
        reference: f[2].into(),
        alt: f[3].into(),
        kind: kind_from(f[4])?,
        category: Category::from_code(f[5])?,
        ids: if f[6] == "." { vec![] } else { f[6].split(';').map(str::to_string).collect() },
        a: side(7)?,
        b: side(13)?,
    })
}

/// Índice de `rows.bgz`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RowIndex {
    pub rows: u64,
    /// Offset virtual das linhas 0, 1024, 2048...
    pub marks: Vec<u64>,
}

impl RowIndex {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut v = Vec::with_capacity(24 + self.marks.len() * 8);
        v.extend_from_slice(INDEX_MAGIC);
        v.extend_from_slice(&self.rows.to_le_bytes());
        v.extend_from_slice(&(self.marks.len() as u64).to_le_bytes());
        for m in &self.marks {
            v.extend_from_slice(&m.to_le_bytes());
        }
        v
    }

    pub fn from_bytes(b: &[u8]) -> Result<Self> {
        let bad = || GenozError::InvalidParam("índice de resultado inválido ou corrompido".into());
        if b.len() < 24 || &b[..8] != INDEX_MAGIC {
            return Err(bad());
        }
        let u = |i: usize| u64::from_le_bytes(b[i..i + 8].try_into().expect("8 bytes"));
        let (rows, n) = (u(8), u(16) as usize);
        if b.len() != 24 + n * 8 {
            return Err(bad());
        }
        Ok(Self { rows, marks: (0..n).map(|i| u(24 + i * 8)).collect() })
    }
}

pub struct ResultWriter<W: Write> {
    out: BgzfWriter<W>,
    index: RowIndex,
}

impl<W: Write> ResultWriter<W> {
    pub fn new(inner: W) -> Result<Self> {
        let mut out = BgzfWriter::new(inner);
        writeln!(out, "{TSV_HEADER}")?;
        Ok(Self { out, index: RowIndex { rows: 0, marks: Vec::new() } })
    }

    pub fn push(&mut self, row: &ComparisonRow) -> Result<()> {
        if self.index.rows % ROWS_PER_MARK == 0 {
            self.index.marks.push(self.out.virtual_offset());
        }
        writeln!(self.out, "{}", encode_row(row))?;
        self.index.rows += 1;
        Ok(())
    }

    pub fn finish(self) -> Result<(W, RowIndex)> {
        Ok((self.out.finish()?, self.index))
    }
}

pub struct ResultReader<R: Read + Seek> {
    bgzf: BgzfReader<R>,
    index: RowIndex,
}

impl<R: Read + Seek> ResultReader<R> {
    pub fn new(rows: R, index: RowIndex) -> Self {
        Self { bgzf: BgzfReader::new(rows), index }
    }

    pub fn total_rows(&self) -> u64 {
        self.index.rows
    }

    /// Linhas `start..start+count` (sem filtro).
    pub fn page(&mut self, start: u64, count: usize) -> Result<Vec<ComparisonRow>> {
        if start >= self.index.rows || count == 0 {
            return Ok(Vec::new());
        }
        let mark = (start / ROWS_PER_MARK) as usize;
        self.bgzf.seek_virtual(self.index.marks[mark])?;
        let mut reader = BufReader::new(&mut self.bgzf);
        let mut line = String::new();
        let mut current = mark as u64 * ROWS_PER_MARK;
        let mut out = Vec::with_capacity(count);
        while out.len() < count {
            line.clear();
            if reader.read_line(&mut line)? == 0 {
                break;
            }
            if current >= start {
                out.push(
                    decode_row(&line)
                        .ok_or_else(|| GenozError::InvalidParam("linha de resultado corrompida".into()))?,
                );
            }
            current += 1;
        }
        Ok(out)
    }

    /// Percorre todas as linhas que passam no filtro, pulando `skip` e
    /// devolvendo até `count`. Também retorna o total de linhas que passam.
    pub fn scan(&mut self, filter: &RowFilter, skip: u64, count: usize) -> Result<(Vec<ComparisonRow>, u64)> {
        if self.index.marks.is_empty() {
            return Ok((Vec::new(), 0));
        }
        self.bgzf.seek_virtual(self.index.marks[0])?;
        let mut reader = BufReader::new(&mut self.bgzf);
        let (mut line, mut matched, mut out) = (String::new(), 0u64, Vec::new());
        loop {
            line.clear();
            if reader.read_line(&mut line)? == 0 {
                break;
            }
            let row =
                decode_row(&line).ok_or_else(|| GenozError::InvalidParam("linha de resultado corrompida".into()))?;
            if filter.matches(&row) {
                if matched >= skip && out.len() < count {
                    out.push(row);
                }
                matched += 1;
            }
        }
        Ok((out, matched))
    }

    /// Chama `f` para cada linha que passa no filtro, em ordem.
    pub fn for_each(&mut self, filter: &RowFilter, mut f: impl FnMut(u32, &ComparisonRow) -> Result<()>) -> Result<()> {
        if self.index.marks.is_empty() {
            return Ok(());
        }
        self.bgzf.seek_virtual(self.index.marks[0])?;
        let mut reader = BufReader::new(&mut self.bgzf);
        let mut line = String::new();
        let mut n = 0u32;
        loop {
            line.clear();
            if reader.read_line(&mut line)? == 0 {
                break;
            }
            let row = decode_row(&line).ok_or_else(corrupted)?;
            if filter.matches(&row) {
                f(n, &row)?;
            }
            n += 1;
        }
        Ok(())
    }

    /// Números (0-based) das linhas que passam no filtro. Com eles, a tabela
    /// pagina o resultado filtrado sem varrer o arquivo a cada página.
    pub fn matching_rows(&mut self, filter: &RowFilter) -> Result<Vec<u32>> {
        let mut out = Vec::new();
        self.for_each(filter, |n, _| {
            out.push(n);
            Ok(())
        })?;
        Ok(out)
    }

    /// Linhas pelos números informados (em ordem crescente).
    pub fn rows_at(&mut self, rows: &[u32]) -> Result<Vec<ComparisonRow>> {
        let mut out = Vec::with_capacity(rows.len());
        let mut line = String::new();
        let marks = &self.index.marks;
        let total = self.index.rows;
        let mut rd = BufReader::new(&mut self.bgzf);
        // Número da próxima linha que o leitor devolveria (None = não posicionado).
        let mut current: Option<u64> = None;
        for &r in rows {
            let r = u64::from(r);
            if r >= total {
                break;
            }
            // Reposiciona se voltou ou se pular linhas custaria mais que um bloco.
            let reposition = current.is_none_or(|c| r < c || r / ROWS_PER_MARK > c / ROWS_PER_MARK);
            if reposition {
                let inner = rd.into_inner(); // descarta o buffer antigo
                inner.seek_virtual(marks[(r / ROWS_PER_MARK) as usize])?;
                rd = BufReader::new(inner);
                current = Some(r / ROWS_PER_MARK * ROWS_PER_MARK);
            }
            let mut c = current.expect("posicionado");
            while c < r {
                line.clear();
                rd.read_line(&mut line)?;
                c += 1;
            }
            line.clear();
            rd.read_line(&mut line)?;
            out.push(decode_row(&line).ok_or_else(corrupted)?);
            current = Some(c + 1);
        }
        Ok(out)
    }
}

fn corrupted() -> GenozError {
    GenozError::InvalidParam("linha de resultado corrompida".into())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ExportFormat {
    Csv,
    Tsv,
    Json,
    /// VCF com duas colunas de amostra (A e B) e a categoria em INFO/GENOZ_CAT.
    Vcf,
}

const EXPORT_COLUMNS: [&str; 19] = [
    "chrom", "pos", "ref", "alt", "kind", "category", "ids", "a_state", "a_gt", "a_qual", "a_dp", "a_gq", "a_filter",
    "b_state", "b_gt", "b_qual", "b_dp", "b_gq", "b_filter",
];

fn csv_field(v: &str) -> String {
    if v.contains([',', '"', '\n']) {
        format!("\"{}\"", v.replace('"', "\"\""))
    } else {
        v.to_string()
    }
}

/// Exporta as linhas que passam no filtro. Retorna quantas linhas foram gravadas.
/// A saída é determinística: mesmo resultado + mesmo filtro → mesmos bytes.
pub fn export_rows<R: Read + Seek, W: Write>(
    reader: &mut ResultReader<R>,
    filter: &RowFilter,
    format: ExportFormat,
    sample_names: (&str, &str),
    mut out: W,
) -> Result<u64> {
    let mut n = 0u64;
    match format {
        ExportFormat::Csv | ExportFormat::Tsv => {
            let sep = if format == ExportFormat::Csv { "," } else { "\t" };
            writeln!(out, "{}", EXPORT_COLUMNS.join(sep))?;
            reader.for_each(filter, |_, row| {
                let line = encode_row(row);
                let fields: Vec<String> = line
                    .split('\t')
                    .map(|f| if format == ExportFormat::Csv { csv_field(f) } else { f.to_string() })
                    .collect();
                writeln!(out, "{}", fields.join(sep))?;
                n += 1;
                Ok(())
            })?;
        }
        ExportFormat::Json => {
            write!(out, "[")?;
            reader.for_each(filter, |_, row| {
                if n > 0 {
                    write!(out, ",")?;
                }
                write!(out, "\n  {}", serde_json::to_string(row).expect("linha serializável"))?;
                n += 1;
                Ok(())
            })?;
            writeln!(out, "\n]")?;
        }
        ExportFormat::Vcf => {
            writeln!(out, "##fileformat=VCFv4.3")?;
            writeln!(out, "##source=Genoz {} (comparação A x B)", crate::CORE_VERSION)?;
            writeln!(
                out,
                "##INFO=<ID=GENOZ_CAT,Number=1,Type=String,Description=\"Categoria da comparação (shared, genotype_difference, only_a, only_b, missing_uncertain, not_assessed)\">"
            )?;
            writeln!(out, "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genótipo\">")?;
            writeln!(
                out,
                "##FORMAT=<ID=GZST,Number=1,Type=String,Description=\"Estado do lado na comparação Genoz\">"
            )?;
            writeln!(
                out,
                "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{}\t{}",
                sample_names.0, sample_names.1
            )?;
            reader.for_each(filter, |_, row| {
                let side = |s: &SideView| format!("{}:{}", s.gt.as_deref().unwrap_or("."), s.state.code());
                let ids = if row.ids.is_empty() { ".".to_string() } else { row.ids.join(";") };
                writeln!(
                    out,
                    "{}\t{}\t{}\t{}\t{}\t.\t.\tGENOZ_CAT={}\tGT:GZST\t{}\t{}",
                    row.chrom,
                    row.pos,
                    ids,
                    row.reference,
                    row.alt,
                    row.category.code(),
                    side(&row.a),
                    side(&row.b)
                )?;
                n += 1;
                Ok(())
            })?;
        }
    }
    out.flush()?;
    Ok(n)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn row(i: u64) -> ComparisonRow {
        ComparisonRow {
            chrom: "1".into(),
            pos: 1000 + i,
            reference: "A".into(),
            alt: "G".into(),
            kind: VariantKind::Snv,
            category: if i % 3 == 0 { Category::OnlyA } else { Category::Shared },
            ids: if i % 5 == 0 { vec![format!("syn{i}")] } else { vec![] },
            a: SideView {
                state: SideState::Carrier,
                gt: Some("0/1".into()),
                qual: Some(50.5),
                dp: Some(12),
                gq: None,
                filter: Some(FilterState::Pass),
            },
            b: SideView { state: SideState::AbsentUnknown, gt: None, qual: None, dp: None, gq: None, filter: None },
        }
    }

    #[test]
    fn encode_decode_round_trip() {
        for i in 0..10 {
            let r = row(i);
            assert_eq!(decode_row(&encode_row(&r)), Some(r));
        }
    }

    #[test]
    fn pages_and_scan() {
        let mut w = ResultWriter::new(Vec::new()).unwrap();
        for i in 0..5000 {
            w.push(&row(i)).unwrap();
        }
        let (bytes, index) = w.finish().unwrap();
        let index = RowIndex::from_bytes(&index.to_bytes()).unwrap();
        assert_eq!(index.rows, 5000);
        assert_eq!(index.marks.len(), 5);
        let mut r = ResultReader::new(std::io::Cursor::new(bytes), index);
        let page = r.page(2047, 3).unwrap();
        assert_eq!(page.iter().map(|x| x.pos).collect::<Vec<_>>(), [3047, 3048, 3049]);
        assert_eq!(r.page(4998, 10).unwrap().len(), 2);
        assert!(r.page(6000, 10).unwrap().is_empty());
        let f = RowFilter { categories: vec![Category::OnlyA], ..Default::default() };
        let (rows, total) = r.scan(&f, 10, 5).unwrap();
        assert_eq!(total, 1667);
        assert_eq!(rows[0].pos, 1030);
    }

    fn store(n: u64) -> ResultReader<std::io::Cursor<Vec<u8>>> {
        let mut w = ResultWriter::new(Vec::new()).unwrap();
        for i in 0..n {
            w.push(&row(i)).unwrap();
        }
        let (bytes, index) = w.finish().unwrap();
        ResultReader::new(std::io::Cursor::new(bytes), index)
    }

    #[test]
    fn matching_rows_and_random_access_agree_with_scan() {
        let mut r = store(5000);
        let f = RowFilter { categories: vec![Category::OnlyA], ..Default::default() };
        let idx = r.matching_rows(&f).unwrap();
        assert_eq!(idx.len(), 1667);
        // Páginas espalhadas, inclusive voltando para trás e cruzando blocos.
        for (skip, count) in [(0usize, 5usize), (1600, 67), (300, 400), (10, 3)] {
            let want = r.scan(&f, skip as u64, count).unwrap().0;
            let got = r.rows_at(&idx[skip..(skip + count).min(idx.len())]).unwrap();
            assert_eq!(got, want, "skip={skip}");
        }
        // Linhas fora do intervalo são ignoradas.
        assert!(r.rows_at(&[9_999_999]).unwrap().is_empty());
    }

    #[test]
    fn exports() {
        let mut r = store(4);
        let all = RowFilter::default();
        let mut csv = Vec::new();
        assert_eq!(export_rows(&mut r, &all, ExportFormat::Csv, ("A", "B"), &mut csv).unwrap(), 4);
        let csv = String::from_utf8(csv).unwrap();
        assert!(csv.starts_with("chrom,pos,ref,alt,kind,category,ids,a_state"));
        assert!(csv.contains("\n1,1000,A,G,snv,only_a,syn0,carrier,0/1,50.5,12,.,pass,absent_unknown"));

        let mut json = Vec::new();
        export_rows(&mut r, &all, ExportFormat::Json, ("A", "B"), &mut json).unwrap();
        let parsed: Vec<ComparisonRow> = serde_json::from_slice(&json).unwrap();
        assert_eq!(parsed.len(), 4);

        let mut vcf = Vec::new();
        let f = RowFilter { categories: vec![Category::Shared], ..Default::default() };
        assert_eq!(export_rows(&mut r, &f, ExportFormat::Vcf, ("PESSOA_A", "PESSOA_B"), &mut vcf).unwrap(), 2);
        let vcf = String::from_utf8(vcf).unwrap();
        assert!(vcf.contains("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tPESSOA_A\tPESSOA_B\n"));
        assert!(vcf.contains("1\t1001\t.\tA\tG\t.\t.\tGENOZ_CAT=shared\tGT:GZST\t0/1:carrier\t.:absent_unknown\n"));
        // O VCF exportado é lido de volta pelo próprio Genoz sem erros.
        let report = crate::inspect::inspect(vcf.as_bytes(), &Default::default()).unwrap();
        assert_eq!(report.errors, 0, "{:#?}", report.issues);
        assert_eq!(report.records_ok, 2);
    }
}

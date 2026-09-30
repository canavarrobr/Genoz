//! Cabeçalho VCF (linhas `##` e a linha `#CHROM`). Ver VCFv4.5.pdf, seção 1.4.

use serde::Serialize;

use crate::chrom::canonical_chrom;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Contig {
    /// Nome exatamente como está no arquivo.
    pub id: String,
    pub canonical: String,
    pub length: Option<u64>,
    pub assembly: Option<String>,
}

/// Campo `Number` de INFO/FORMAT.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum Number {
    Fixed(u32),
    /// Um valor por alelo alternativo.
    A,
    /// Um valor por alelo, incluindo a referência.
    R,
    /// Um valor por genótipo possível.
    G,
    /// Um valor por alelo do GT (VCF 4.4+, ex.: PSL).
    P,
    /// `.` ou outro valor variável.
    Unknown,
}

impl Number {
    fn parse(s: &str) -> Number {
        match s {
            "A" => Number::A,
            "R" => Number::R,
            "G" => Number::G,
            "P" => Number::P,
            n => n.parse().map(Number::Fixed).unwrap_or(Number::Unknown),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct FieldDef {
    pub id: String,
    pub number: Number,
    pub ty: String,
    pub description: String,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct VcfHeader {
    pub file_format: Option<String>,
    pub contigs: Vec<Contig>,
    pub info: Vec<FieldDef>,
    pub format: Vec<FieldDef>,
    pub filters: Vec<String>,
    pub reference: Option<String>,
    pub samples: Vec<String>,
    /// Linhas `##` originais, na ordem, para reescrita fiel.
    #[serde(skip)]
    pub meta_lines: Vec<String>,
}

impl VcfHeader {
    pub fn info_def(&self, id: &str) -> Option<&FieldDef> {
        self.info.iter().find(|d| d.id == id)
    }

    pub fn format_def(&self, id: &str) -> Option<&FieldDef> {
        self.format.iter().find(|d| d.id == id)
    }

    pub fn has_contig(&self, canonical: &str) -> bool {
        self.contigs.iter().any(|c| c.canonical == canonical)
    }

    /// Interpreta uma linha `##...` e acumula no cabeçalho.
    pub fn push_meta_line(&mut self, line: &str) {
        self.meta_lines.push(line.to_string());
        let Some(body) = line.strip_prefix("##") else { return };
        let Some((key, value)) = body.split_once('=') else { return };
        match key {
            "fileformat" => self.file_format = Some(value.to_string()),
            "reference" => self.reference = Some(value.to_string()),
            "contig" => {
                let f = parse_structured(value);
                if let Some(id) = get(&f, "ID") {
                    self.contigs.push(Contig {
                        canonical: canonical_chrom(id),
                        id: id.to_string(),
                        length: get(&f, "length").and_then(|l| l.parse().ok()),
                        assembly: get(&f, "assembly").map(str::to_string),
                    });
                }
            }
            "INFO" | "FORMAT" => {
                let f = parse_structured(value);
                if let Some(id) = get(&f, "ID") {
                    let def = FieldDef {
                        id: id.to_string(),
                        number: Number::parse(get(&f, "Number").unwrap_or(".")),
                        ty: get(&f, "Type").unwrap_or("String").to_string(),
                        description: get(&f, "Description").unwrap_or("").to_string(),
                    };
                    if key == "INFO" {
                        self.info.push(def);
                    } else {
                        self.format.push(def);
                    }
                }
            }
            "FILTER" => {
                if let Some(id) = get(&parse_structured(value), "ID") {
                    self.filters.push(id.to_string());
                }
            }
            _ => {}
        }
    }

    /// Linha `#CHROM ...` reconstruída a partir das amostras.
    pub fn column_line(&self) -> String {
        let mut s = String::from("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO");
        if !self.samples.is_empty() {
            s.push_str("\tFORMAT");
            for name in &self.samples {
                s.push('\t');
                s.push_str(name);
            }
        }
        s
    }
}

fn get<'a>(fields: &'a [(String, String)], key: &str) -> Option<&'a str> {
    fields.iter().find(|(k, _)| k == key).map(|(_, v)| v.as_str())
}

/// Interpreta `<ID=x,Number=1,Description="a, b">` respeitando aspas.
pub fn parse_structured(value: &str) -> Vec<(String, String)> {
    let inner = value.trim().trim_start_matches('<').trim_end_matches('>');
    let mut out = Vec::new();
    let (mut key, mut val) = (String::new(), String::new());
    let (mut in_key, mut quoted, mut escaped) = (true, false, false);
    for ch in inner.chars() {
        if in_key {
            match ch {
                '=' => in_key = false,
                ',' => {
                    if !key.is_empty() {
                        out.push((std::mem::take(&mut key), String::new()));
                    }
                }
                c => key.push(c),
            }
            continue;
        }
        match ch {
            _ if escaped => {
                val.push(ch);
                escaped = false;
            }
            '\\' if quoted => escaped = true,
            '"' => quoted = !quoted,
            ',' if !quoted => {
                out.push((std::mem::take(&mut key), std::mem::take(&mut val)));
                in_key = true;
            }
            c => val.push(c),
        }
    }
    if !key.is_empty() {
        out.push((key, val));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn structured_with_quotes() {
        let f = parse_structured(r#"<ID=AF,Number=A,Type=Float,Description="Allele frequency, \"estimated\"">"#);
        assert_eq!(get(&f, "ID"), Some("AF"));
        assert_eq!(get(&f, "Number"), Some("A"));
        assert_eq!(get(&f, "Description"), Some(r#"Allele frequency, "estimated""#));
    }

    #[test]
    fn meta_lines() {
        let mut h = VcfHeader::default();
        h.push_meta_line("##fileformat=VCFv4.3");
        h.push_meta_line("##contig=<ID=chr1,length=248956422,assembly=GRCh38>");
        h.push_meta_line("##FORMAT=<ID=PL,Number=G,Type=Integer,Description=\"PL\">");
        h.push_meta_line("##FILTER=<ID=LowQual,Description=\"x\">");
        assert_eq!(h.file_format.as_deref(), Some("VCFv4.3"));
        assert_eq!(h.contigs[0].canonical, "1");
        assert_eq!(h.contigs[0].length, Some(248_956_422));
        assert_eq!(h.format_def("PL").unwrap().number, Number::G);
        assert_eq!(h.filters, ["LowQual"]);
        assert!(h.has_contig("1"));
    }
}

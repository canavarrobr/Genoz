//! Relatório de uma comparação (Módulo 11): um modelo de documento único,
//! desenhado em HTML autocontido (aqui) e em PDF ([`crate::pdf`]).
//!
//! Lê o JSON gravado (summary.json, stats_*.json, manifest.json), então funciona
//! também com análises antigas. Mesma entrada → mesmos bytes: a data de geração
//! vem de quem chama; nada de relógio, rede ou fonte externa.

use serde_json::Value;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Lang {
    Pt,
    En,
}

impl Lang {
    pub fn parse(s: &str) -> Self {
        if s.to_ascii_lowercase().starts_with("en") {
            Lang::En
        } else {
            Lang::Pt
        }
    }
}

/// Um bloco do relatório. Os dois desenhos (HTML e PDF) entendem os mesmos blocos.
#[derive(Debug, Clone, PartialEq)]
pub enum Block {
    Heading(String),
    Paragraph(String),
    /// Aviso destacado (não é diagnóstico, avisos da análise).
    Notice(String),
    KeyValues(Vec<(String, String)>),
    Table {
        head: Vec<String>,
        rows: Vec<Vec<String>>,
        /// Colunas alinhadas à direita (números).
        numeric: Vec<usize>,
        /// Colunas em fonte monoespaçada (hashes).
        mono: Vec<usize>,
    },
    /// Barras horizontais: rótulo, valor, cor (#rrggbb).
    Bars(Vec<(String, u64, &'static str)>),
}

#[derive(Debug, Clone, PartialEq)]
pub struct ReportDoc {
    pub lang: Lang,
    pub title: String,
    pub subtitle: String,
    pub blocks: Vec<Block>,
    pub footer: String,
}

pub struct ReportInput<'a> {
    pub project: &'a str,
    /// Data/hora de geração, já formatada por quem chama.
    pub generated_at: &'a str,
    pub summary: &'a Value,
    pub stats_a: Option<&'a Value>,
    pub stats_b: Option<&'a Value>,
    pub manifest: Option<&'a Value>,
    pub lang: Lang,
}

pub const CATEGORIES: [&str; 6] =
    ["shared", "genotype_difference", "only_a", "only_b", "missing_uncertain", "not_assessed"];

fn category_label(code: &str, lang: Lang) -> &'static str {
    match (code, lang) {
        ("shared", Lang::Pt) => "Compartilhada",
        ("shared", Lang::En) => "Shared",
        ("genotype_difference", Lang::Pt) => "Genótipo diferente",
        ("genotype_difference", Lang::En) => "Genotype difference",
        ("only_a", Lang::Pt) => "Somente em A",
        ("only_a", Lang::En) => "Only in A",
        ("only_b", Lang::Pt) => "Somente em B",
        ("only_b", Lang::En) => "Only in B",
        ("missing_uncertain", Lang::Pt) => "Ausente/incerta",
        ("missing_uncertain", Lang::En) => "Missing/uncertain",
        (_, Lang::Pt) => "Não avaliada",
        (_, Lang::En) => "Not assessed",
    }
}

/// Mesmas cores do app (paleta do guia de estilo).
fn category_color(code: &str) -> &'static str {
    match code {
        "shared" => "#2f9e44",
        "genotype_difference" => "#f59e0b",
        "only_a" => "#0b7285",
        "only_b" => "#6366f1",
        "missing_uncertain" => "#94a3b8",
        _ => "#64748b",
    }
}

pub fn fmt_int(n: u64, lang: Lang) -> String {
    let s = n.to_string();
    let sep = if lang == Lang::Pt { '.' } else { ',' };
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 {
            out.push(sep);
        }
        out.push(c);
    }
    out
}

fn fmt_dec(v: f64, digits: usize, lang: Lang) -> String {
    let s = format!("{v:.digits$}");
    if lang == Lang::Pt {
        s.replace('.', ",")
    } else {
        s
    }
}

fn fmt_pct(v: Option<f64>, lang: Lang) -> String {
    v.map_or_else(|| "—".into(), |x| format!("{}%", fmt_dec(x * 100.0, 1, lang)))
}

fn u(v: &Value, k: &str) -> u64 {
    v.get(k).and_then(Value::as_u64).unwrap_or(0)
}

fn f(v: &Value, k: &str) -> Option<f64> {
    v.get(k).and_then(Value::as_f64)
}

fn s<'v>(v: &'v Value, k: &str) -> Option<&'v str> {
    v.get(k).and_then(Value::as_str)
}

fn opt_num(v: Option<f64>, digits: usize, lang: Lang) -> String {
    v.map_or_else(|| "—".into(), |x| fmt_dec(x, digits, lang))
}

/// Monta o documento a partir dos JSONs gravados.
pub fn build_report(input: &ReportInput) -> ReportDoc {
    let lang = input.lang;
    let t = |pt: &'static str, en: &'static str| if lang == Lang::Pt { pt } else { en };
    let sm = input.summary;
    let side = |k: &str| sm.get(k).cloned().unwrap_or(Value::Null);
    let (sa, sb) = (side("a"), side("b"));
    let name = |v: &Value, fallback: &str| s(v, "sample").unwrap_or(fallback).to_string();
    let (name_a, name_b) = (name(&sa, "A"), name(&sb, "B"));
    let mut blocks = Vec::new();

    blocks.push(Block::Notice(
        t(
            "Uso educacional e de pesquisa. Não é diagnóstico. Os resultados dependem da qualidade dos arquivos e dos parâmetros abaixo.",
            "For education and research. Not a diagnosis. Results depend on the quality of the files and on the parameters below.",
        )
        .into(),
    ));

    // Amostras
    blocks.push(Block::Heading(t("Amostras", "Samples").into()));
    let inputs: Vec<Value> =
        input.manifest.and_then(|m| m.get("inputs")).and_then(Value::as_array).cloned().unwrap_or_default();
    let file_of = |role: &str| {
        inputs.iter().find(|i| s(i, "role") == Some(role)).and_then(|i| s(i, "name")).unwrap_or("—").to_string()
    };
    let build_of = |v: &Value| {
        let b = v.get("build").cloned().unwrap_or(Value::Null);
        let conf = match s(&b, "confidence") {
            Some("high") => t("alta", "high"),
            Some("medium") => t("média", "medium"),
            Some("low") => t("baixa", "low"),
            _ => "—",
        };
        format!("{} ({} {conf})", s(&b, "build").unwrap_or("?"), t("confiança", "confidence"))
    };
    blocks.push(Block::Table {
        head: vec![
            t("Lado", "Side").into(),
            t("Arquivo", "File").into(),
            t("Amostra", "Sample").into(),
            t("Genoma de referência", "Reference genome").into(),
            t("Registros", "Records").into(),
        ],
        rows: vec![
            vec!["A".into(), file_of("a"), name_a.clone(), build_of(&sa), fmt_int(u(&sa, "records"), lang)],
            vec!["B".into(), file_of("b"), name_b.clone(), build_of(&sb), fmt_int(u(&sb, "records"), lang)],
        ],
        numeric: vec![4],
        mono: vec![],
    });

    // Resultado
    blocks.push(Block::Heading(t("Resultado da comparação", "Comparison result").into()));
    let counts = sm.get("counts").cloned().unwrap_or(Value::Null);
    let present: Vec<&str> = CATEGORIES.iter().copied().filter(|c| *c != "not_assessed" || u(&counts, c) > 0).collect();
    blocks.push(Block::Bars(
        present.iter().map(|c| (category_label(c, lang).to_string(), u(&counts, c), category_color(c))).collect(),
    ));
    let mut kv = vec![
        (t("Linhas (variantes)", "Rows (variants)").to_string(), fmt_int(u(sm, "rows"), lang)),
        (t("Sítios presentes nos dois", "Sites in both").to_string(), fmt_int(u(sm, "sites_in_both"), lang)),
        (
            t("Concordância de genótipos", "Genotype concordance").to_string(),
            fmt_pct(f(sm, "genotype_concordance"), lang),
        ),
    ];
    if sm.get("chip").is_none() {
        kv.push((t("Jaccard de sítios", "Site Jaccard").to_string(), fmt_pct(f(sm, "jaccard"), lang)));
    }
    blocks.push(Block::KeyValues(kv));

    if let Some(chip) = sm.get("chip").filter(|c| c.is_object()) {
        blocks.push(Block::Heading(t("Chip × sequenciamento", "Chip × sequencing").into()));
        blocks.push(Block::Paragraph(
            t(
                "Comparação restrita aos sítios medidos pelo chip, por conjunto de letras do genótipo.",
                "Comparison restricted to the sites measured by the chip, by the set of genotype letters.",
            )
            .into(),
        ));
        blocks.push(Block::KeyValues(vec![
            (t("Fabricante", "Vendor").into(), s(chip, "vendor").unwrap_or("—").into()),
            (t("Sítios do chip", "Chip sites").into(), fmt_int(u(chip, "sites"), lang)),
            (t("Sem chamada no chip", "No call on chip").into(), fmt_int(u(chip, "no_calls"), lang)),
            (
                t("Homozigotos sem referência conhecida", "Homozygous with unknown reference").into(),
                fmt_int(u(chip, "unknown_reference"), lang),
            ),
            (
                t("Variantes do VCF fora do chip", "VCF variants off chip").into(),
                fmt_int(u(chip, "vcf_variants_off_chip"), lang),
            ),
            (
                t("Possíveis trocas de fita", "Possible strand flips").into(),
                fmt_int(u(chip, "possible_strand_flips"), lang),
            ),
            (
                t("Concordância fora da referência", "Non-reference concordance").into(),
                fmt_pct(f(chip, "nonref_concordance"), lang),
            ),
        ]));
    }

    if let Some(bm) = sm.get("benchmark").filter(|b| b.is_object()) {
        blocks.push(Block::Heading(t("Benchmark (amostra verdade)", "Benchmark (truth sample)").into()));
        let truth = s(bm, "truth").unwrap_or("?").to_uppercase();
        blocks.push(Block::Paragraph(format!(
            "{} {truth}.",
            t("Amostra tratada como verdade:", "Sample treated as truth:")
        )));
        let row = |k: &str, label: &str| {
            let m = bm.get(k).cloned().unwrap_or(Value::Null);
            vec![
                label.to_string(),
                fmt_int(u(&m, "true_positives"), lang),
                fmt_int(u(&m, "false_positives"), lang),
                fmt_int(u(&m, "false_negatives"), lang),
                fmt_pct(f(&m, "precision"), lang),
                fmt_pct(f(&m, "recall"), lang),
                opt_num(f(&m, "f1"), 3, lang),
            ]
        };
        blocks.push(Block::Table {
            head: vec![
                t("Classe", "Class").into(),
                "TP".into(),
                "FP".into(),
                "FN".into(),
                t("Precisão", "Precision").into(),
                t("Sensibilidade", "Recall").into(),
                "F1".into(),
            ],
            rows: vec![row("all", t("Todas", "All")), row("snv", "SNV"), row("indel", "Indel")],
            numeric: vec![1, 2, 3, 4, 5, 6],
            mono: vec![],
        });
    }

    // Por cromossomo
    if let Some(by_chrom) = sm.get("by_chrom").and_then(Value::as_array).filter(|a| !a.is_empty()) {
        blocks.push(Block::Heading(t("Por cromossomo", "By chromosome").into()));
        let mut head = vec![t("Cromossomo", "Chromosome").to_string()];
        head.extend(present.iter().map(|c| category_label(c, lang).to_string()));
        let rows = by_chrom
            .iter()
            .map(|c| {
                let counts = c.get("counts").cloned().unwrap_or(Value::Null);
                let mut r = vec![s(c, "chrom").unwrap_or("?").to_string()];
                r.extend(present.iter().map(|k| fmt_int(u(&counts, k), lang)));
                r
            })
            .collect();
        blocks.push(Block::Table { head, rows, numeric: (1..=present.len()).collect(), mono: vec![] });
    }

    // QC
    if let (Some(a), Some(b)) = (input.stats_a, input.stats_b) {
        blocks.push(Block::Heading(t("Controle de qualidade", "Quality control").into()));
        let line = |label: &str, va: String, vb: String| vec![label.to_string(), va, vb];
        let int = |v: &Value, k: &str| fmt_int(u(v, k), lang);
        let xh = |v: &Value| fmt_pct(v.get("x_heterozygosity").and_then(|x| f(x, "het_fraction")), lang);
        blocks.push(Block::Table {
            head: vec![t("Métrica", "Metric").into(), format!("A · {name_a}"), format!("B · {name_b}")],
            rows: vec![
                line(t("Chamadas", "Calls"), int(a, "calls_total"), int(b, "calls_total")),
                line(t("Portadoras do alelo", "Allele carriers"), int(a, "carriers"), int(b, "carriers")),
                line(t("Heterozigotas", "Heterozygous"), int(a, "het"), int(b, "het")),
                line(t("Homozigotas alternativas", "Homozygous alternative"), int(a, "hom_alt"), int(b, "hom_alt")),
                line(t("Homozigotas de referência", "Homozygous reference"), int(a, "hom_ref"), int(b, "hom_ref")),
                line(t("Sem chamada", "Missing"), int(a, "missing"), int(b, "missing")),
                line(
                    t("Abaixo do filtro de qualidade", "Below quality filter"),
                    int(a, "low_quality"),
                    int(b, "low_quality"),
                ),
                line("Ti/Tv", opt_num(f(a, "ti_tv"), 2, lang), opt_num(f(b, "ti_tv"), 2, lang)),
                line("het / hom-alt", opt_num(f(a, "het_hom_ratio"), 2, lang), opt_num(f(b, "het_hom_ratio"), 2, lang)),
                line(
                    t("Taxa de ausência", "Missing rate"),
                    fmt_pct(f(a, "missing_rate"), lang),
                    fmt_pct(f(b, "missing_rate"), lang),
                ),
                line(t("Heterozigosidade no X (educacional)", "X heterozygosity (educational)"), xh(a), xh(b)),
            ],
            numeric: vec![1, 2],
            mono: vec![],
        });
        if sm.get("chip").is_some_and(Value::is_object) {
            blocks.push(Block::Paragraph(
                t(
                    "O chip não traz QUAL, DP nem GQ: o controle de qualidade vale para o VCF (lado B).",
                    "The chip has no QUAL, DP or GQ: quality control applies to the VCF (side B).",
                )
                .into(),
            ));
        }
        blocks.push(Block::Paragraph(
            t(
                "Ti/Tv de referência: ~2,0–2,1 em genoma e ~3,0 em exoma; valores distantes sugerem falsos positivos. A heterozigosidade no X é uma checagem de consistência, não determinação de sexo.",
                "Reference Ti/Tv: ~2.0–2.1 for genomes and ~3.0 for exomes; distant values suggest false positives. X heterozygosity is a consistency check, not sex determination.",
            )
            .into(),
        ));
        for (key, label) in [("qual_hist", "QUAL"), ("dp_hist", "DP"), ("gq_hist", "GQ")] {
            let (ha, hb) = (a.get(key).and_then(Value::as_array), b.get(key).and_then(Value::as_array));
            let (Some(ha), Some(hb)) = (ha, hb) else { continue };
            if ha.iter().chain(hb).all(|bin| u(bin, "count") == 0) {
                continue;
            }
            let rows = ha
                .iter()
                .zip(hb)
                .map(|(x, y)| {
                    let lo = opt_num(f(x, "lo"), 0, lang);
                    let range = match f(x, "hi") {
                        Some(hi) => format!("{lo}–{}", fmt_dec(hi, 0, lang)),
                        None => format!("≥ {lo}"),
                    };
                    vec![range, fmt_int(u(x, "count"), lang), fmt_int(u(y, "count"), lang)]
                })
                .collect();
            blocks.push(Block::Table {
                head: vec![
                    format!("{label} ({})", t("faixa", "range")),
                    format!("A · {name_a}"),
                    format!("B · {name_b}"),
                ],
                rows,
                numeric: vec![1, 2],
                mono: vec![],
            });
        }
    }

    // Avisos da análise
    let warnings: Vec<String> = sm
        .get("warnings")
        .and_then(Value::as_array)
        .map(|w| w.iter().filter_map(Value::as_str).map(String::from).collect())
        .unwrap_or_default();
    if !warnings.is_empty() {
        blocks.push(Block::Heading(t("Avisos", "Warnings").into()));
        for w in warnings {
            blocks.push(Block::Notice(w));
        }
    }

    // Parâmetros
    blocks.push(Block::Heading(t("Parâmetros", "Parameters").into()));
    let opts = sm.get("options").cloned().unwrap_or(Value::Null);
    let cf = opts.get("call_filter").cloned().unwrap_or(Value::Null);
    let yes_no = |b: bool| if b { t("sim", "yes") } else { t("não", "no") }.to_string();
    let min = |k: &str| opt_num(f(&cf, k), 0, lang);
    let conditions = cf.get("conditions").and_then(Value::as_array).map_or(0, Vec::len);
    let truth = match s(&opts, "truth") {
        Some(x) => x.to_uppercase(),
        None => t("nenhuma", "none").into(),
    };
    blocks.push(Block::KeyValues(vec![
        (
            t("Somente FILTER = PASS", "Only FILTER = PASS").into(),
            yes_no(cf.get("pass_only").and_then(Value::as_bool).unwrap_or(false)),
        ),
        (t("QUAL mínima", "Minimum QUAL").into(), min("min_qual")),
        (t("DP mínima", "Minimum DP").into(), min("min_dp")),
        (t("GQ mínima", "Minimum GQ").into(), min("min_gq")),
        (t("Condições extras (INFO/FORMAT)", "Extra conditions (INFO/FORMAT)").into(), conditions.to_string()),
        (t("Amostra verdade", "Truth sample").into(), truth),
        (
            t("Indels alinhados com FASTA de referência", "Indels left-aligned with reference FASTA").into(),
            yes_no(opts.get("normalize_with_reference").and_then(Value::as_bool).unwrap_or(false)),
        ),
        (
            t("Builds diferentes permitidos", "Different builds allowed").into(),
            yes_no(opts.get("allow_build_mismatch").and_then(Value::as_bool).unwrap_or(false)),
        ),
    ]));

    // Manifesto
    if let Some(m) = input.manifest {
        blocks.push(Block::Heading(t("Manifesto de reprodutibilidade", "Reproducibility manifest").into()));
        blocks.push(Block::Paragraph(
            t(
                "O ID da análise vem do conteúdo: os mesmos arquivos (SHA-256) com os mesmos parâmetros dão o mesmo ID e as mesmas saídas em qualquer aparelho.",
                "The analysis ID comes from the content: the same files (SHA-256) with the same parameters give the same ID and the same outputs on any device.",
            )
            .into(),
        ));
        blocks.push(Block::KeyValues(vec![
            (t("ID da análise", "Analysis ID").into(), s(m, "analysis_id").unwrap_or("—").into()),
            (t("Tipo", "Type").into(), s(m, "analysis_type").unwrap_or("—").into()),
            (t("Versão do núcleo", "Core version").into(), s(m, "core_version").unwrap_or("—").into()),
            (t("Plataforma", "Platform").into(), s(m, "platform").unwrap_or("—").into()),
            (t("Criada em", "Created at").into(), s(m, "created_at").unwrap_or("—").into()),
        ]));
        let refs = |k: &str, with_role: bool| -> Vec<Vec<String>> {
            m.get(k)
                .and_then(Value::as_array)
                .map(|a| {
                    a.iter()
                        .map(|i| {
                            let mut r = Vec::new();
                            if with_role {
                                r.push(s(i, "role").unwrap_or("").to_string());
                            }
                            r.push(s(i, "name").unwrap_or("").to_string());
                            r.push(fmt_int(u(i, "bytes"), lang));
                            r.push(s(i, "sha256").unwrap_or("").to_string());
                            r
                        })
                        .collect()
                })
                .unwrap_or_default()
        };
        blocks.push(Block::Table {
            head: vec![t("Papel", "Role").into(), t("Entrada", "Input").into(), "Bytes".into(), "SHA-256".into()],
            rows: refs("inputs", true),
            numeric: vec![2],
            mono: vec![3],
        });
        blocks.push(Block::Table {
            head: vec![t("Saída", "Output").into(), "Bytes".into(), "SHA-256".into()],
            rows: refs("outputs", false),
            numeric: vec![1],
            mono: vec![2],
        });
    }

    let version = s(sm, "core_version").unwrap_or(crate::CORE_VERSION);
    ReportDoc {
        lang,
        title: format!("{} — {name_a} × {name_b}", t("Relatório Genoz", "Genoz report")),
        subtitle: format!(
            "{}: {} · {}: {}",
            t("Projeto", "Project"),
            input.project,
            t("Gerado em", "Generated at"),
            input.generated_at
        ),
        blocks,
        footer: format!(
            "Genoz ({} {version}) · {}",
            t("núcleo", "core"),
            t("Uso educacional e de pesquisa. Não é diagnóstico.", "For education and research. Not a diagnosis.")
        ),
    }
}

fn esc(s: &str) -> String {
    let mut o = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => o.push_str("&amp;"),
            '<' => o.push_str("&lt;"),
            '>' => o.push_str("&gt;"),
            '"' => o.push_str("&quot;"),
            '\'' => o.push_str("&#39;"),
            _ => o.push(c),
        }
    }
    o
}

const CSS: &str = "*{box-sizing:border-box}body{margin:0;background:#f6fafb;color:#17212b;\
font:15px/1.5 system-ui,-apple-system,'Segoe UI',Roboto,Arial,sans-serif}\
main{max-width:960px;margin:0 auto;padding:24px 16px 48px}\
header{background:linear-gradient(135deg,#073b4c,#0b7285);color:#fff;border-radius:16px;padding:24px;margin-bottom:16px}\
header h1{margin:0 0 6px;font-size:24px;line-height:1.25}header p{margin:0;opacity:.85}\
h2{font-size:19px;margin:28px 0 10px;color:#073b4c}\
section.card{background:#fff;border-radius:12px;padding:14px 16px;margin:10px 0;box-shadow:0 1px 2px rgba(0,0,0,.06)}\
.notice{background:#fff7e6;border-left:4px solid #f59e0b;border-radius:8px;padding:10px 14px;margin:10px 0}\
.tbl{overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:14px}\
th,td{padding:6px 8px;border-bottom:1px solid #e2e8f0;text-align:left;vertical-align:top}\
th{background:#eef6f8;color:#073b4c;font-weight:600}td.n,th.n{text-align:right;font-variant-numeric:tabular-nums}\
td.m{font-family:ui-monospace,Consolas,monospace;font-size:12px;word-break:break-all}\
dl{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:4px 16px;margin:0}dt{color:#64748b}\
dd{margin:0;text-align:right;font-weight:600;word-break:break-all}\
.bar{display:grid;grid-template-columns:minmax(120px,200px) 1fr auto;gap:10px;align-items:center;margin:6px 0}\
.bar svg{width:100%;height:14px}footer{margin-top:32px;color:#64748b;font-size:13px;text-align:center}\
@media (prefers-color-scheme:dark){body{background:#0f1a20;color:#e2e8f0}section.card{background:#16252d}\
th{background:#1d323c;color:#e2e8f0}th,td{border-color:#2a3d47}h2{color:#7dd3e0}.notice{background:#3a2c0f}}\
@media print{body{background:#fff}header{-webkit-print-color-adjust:exact;print-color-adjust:exact}section.card{box-shadow:none}}";

/// HTML autocontido: sem script, sem recurso externo (abre offline em qualquer navegador).
pub fn render_html(doc: &ReportDoc) -> String {
    let lang = if doc.lang == Lang::Pt { "pt-BR" } else { "en" };
    let mut h = String::new();
    h.push_str(&format!(
        "<!doctype html>\n<html lang=\"{lang}\"><head><meta charset=\"utf-8\">\
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\
<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; style-src 'unsafe-inline'; img-src data:\">\
<title>{}</title><style>{CSS}</style></head><body><main>\n",
        esc(&doc.title)
    ));
    h.push_str(&format!("<header><h1>{}</h1><p>{}</p></header>\n", esc(&doc.title), esc(&doc.subtitle)));
    for b in &doc.blocks {
        match b {
            Block::Heading(t) => h.push_str(&format!("<h2>{}</h2>\n", esc(t))),
            Block::Paragraph(t) => h.push_str(&format!("<p>{}</p>\n", esc(t))),
            Block::Notice(t) => h.push_str(&format!("<div class=\"notice\">{}</div>\n", esc(t))),
            Block::KeyValues(kv) => {
                h.push_str("<section class=\"card\"><dl>");
                for (k, v) in kv {
                    h.push_str(&format!("<dt>{}</dt><dd>{}</dd>", esc(k), esc(v)));
                }
                h.push_str("</dl></section>\n");
            }
            Block::Table { head, rows, numeric, mono } => {
                h.push_str("<section class=\"card tbl\"><table><thead><tr>");
                for (i, c) in head.iter().enumerate() {
                    let cls = if numeric.contains(&i) { " class=\"n\"" } else { "" };
                    h.push_str(&format!("<th{cls}>{}</th>", esc(c)));
                }
                h.push_str("</tr></thead><tbody>");
                for r in rows {
                    h.push_str("<tr>");
                    for (i, c) in r.iter().enumerate() {
                        let cls = if numeric.contains(&i) {
                            " class=\"n\""
                        } else if mono.contains(&i) {
                            " class=\"m\""
                        } else {
                            ""
                        };
                        h.push_str(&format!("<td{cls}>{}</td>", esc(c)));
                    }
                    h.push_str("</tr>");
                }
                h.push_str("</tbody></table></section>\n");
            }
            Block::Bars(items) => {
                let max = items.iter().map(|i| i.1).max().unwrap_or(0).max(1);
                h.push_str("<section class=\"card\">");
                for (label, v, color) in items {
                    let w = (*v as f64 / max as f64 * 1000.0).round() as u64;
                    h.push_str(&format!(
                        "<div class=\"bar\"><span>{}</span><svg viewBox=\"0 0 1000 14\" preserveAspectRatio=\"none\" \
role=\"img\" aria-label=\"{} {v}\"><rect width=\"1000\" height=\"14\" rx=\"7\" fill=\"#e2e8f0\"/>\
<rect width=\"{w}\" height=\"14\" rx=\"7\" fill=\"{color}\"/></svg><b>{}</b></div>",
                        esc(label),
                        esc(label),
                        fmt_int(*v, doc.lang)
                    ));
                }
                h.push_str("</section>\n");
            }
        }
    }
    h.push_str(&format!("<footer>{}</footer>\n</main></body></html>\n", esc(&doc.footer)));
    h
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    pub(crate) fn fixture(name: &str) -> Value {
        let p = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../app/test/fixtures").join(name);
        serde_json::from_str(&std::fs::read_to_string(p).expect("fixture")).expect("json")
    }

    pub(crate) fn sample_doc(lang: Lang) -> ReportDoc {
        let (sm, a, b, m) = (
            fixture("compare_summary.json"),
            fixture("compare_stats_a.json"),
            fixture("compare_stats_b.json"),
            fixture("compare_manifest.json"),
        );
        build_report(&ReportInput {
            project: "Aula <1>",
            generated_at: "2026-10-01 22:00",
            summary: &sm,
            stats_a: Some(&a),
            stats_b: Some(&b),
            manifest: Some(&m),
            lang,
        })
    }

    #[test]
    fn numbers_come_from_the_summary() {
        let doc = sample_doc(Lang::Pt);
        assert_eq!(doc.title, "Relatório Genoz — PESSOA_A × PESSOA_B");
        let bars = doc.blocks.iter().find_map(|b| if let Block::Bars(x) = b { Some(x.clone()) } else { None }).unwrap();
        assert_eq!(bars.iter().map(|b| b.1).collect::<Vec<_>>(), [5, 1, 4, 1, 1]);
        let html = render_html(&doc);
        assert!(html.contains("<dd>83,3%</dd>"), "concordância 5/6");
        assert!(html.contains("<dd>54,5%</dd>"), "Jaccard");
        assert!(html.contains("c7e0bc9d-f41f-8309-b678-5e20bea871b2"));
        assert!(html.contains("3198114255695529607571549ceb3a276242c01cb9dda698857b4ff36cb3a1ae"));
        assert!(html.contains("Não é diagnóstico"));
        assert!(html.contains("Aula &lt;1&gt;"), "texto do usuário escapado");
        let en = render_html(&sample_doc(Lang::En));
        assert!(en.contains("<dd>83.3%</dd>") && en.contains("Not a diagnosis") && en.contains("Only in A"));
    }

    #[test]
    fn self_contained_and_deterministic() {
        let html = render_html(&sample_doc(Lang::Pt));
        assert_eq!(html, render_html(&sample_doc(Lang::Pt)));
        for forbidden in ["<script", "http://", "https://", "src=\"http", "@import", "url("] {
            assert!(!html.contains(forbidden), "{forbidden}");
        }
    }

    #[test]
    fn works_without_stats_and_manifest() {
        let sm = fixture("chip_compare_summary.json");
        let doc = build_report(&ReportInput {
            project: "p",
            generated_at: "agora",
            summary: &sm,
            stats_a: None,
            stats_b: None,
            manifest: None,
            lang: Lang::Pt,
        });
        let html = render_html(&doc);
        assert!(html.contains("Chip × sequenciamento"));
        assert!(!html.contains("Jaccard"), "Jaccard não se aplica ao chip");
        assert_eq!(fmt_int(1234567, Lang::Pt), "1.234.567");
        assert_eq!(fmt_int(1234567, Lang::En), "1,234,567");
        assert_eq!(fmt_int(12, Lang::En), "12");
    }
}

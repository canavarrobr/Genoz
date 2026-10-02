//! PDF do relatório (Módulo 11): escritor mínimo, sem dependência externa.
//!
//! Usa as fontes padrão do PDF (Helvetica, Helvetica-Bold, Courier) com
//! WinAnsiEncoding — acentos do português cabem; caracteres fora dela viram `?`.
//! Páginas A4, conteúdo comprimido (Flate), sem data de criação: mesma entrada →
//! mesmos bytes.

use std::fmt::Write as _;
use std::io::Write as _;

use flate2::write::ZlibEncoder;
use flate2::Compression;

use crate::report::{Block, Lang, ReportDoc};

const PAGE_W: f64 = 595.28;
const PAGE_H: f64 = 841.89;
const MARGIN: f64 = 44.0;
const BOTTOM: f64 = 56.0;
const CONTENT_W: f64 = PAGE_W - 2.0 * MARGIN;

#[derive(Clone, Copy, PartialEq)]
enum Font {
    Regular,
    Bold,
    Mono,
}

impl Font {
    fn name(self) -> &'static str {
        match self {
            Font::Regular => "F1",
            Font::Bold => "F2",
            Font::Mono => "F3",
        }
    }
}

// Larguras (1/1000 em) dos caracteres 32..=126, das tabelas AFM padrão.
const HELV: [u16; 95] = [
    278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556,
    556, 556, 556, 278, 278, 584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833,
    722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556,
    556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334,
    260, 334, 584,
];
const HELV_BOLD: [u16; 95] = [
    278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, 556, 556, 556, 556, 556, 556, 556,
    556, 556, 556, 333, 333, 584, 584, 584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833,
    722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333, 556, 611, 556, 611,
    556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389,
    280, 389, 584,
];

/// Caractere → byte WinAnsi (`?` quando não existe).
fn win_ansi(c: char) -> u8 {
    match c {
        ' '..='~' => c as u8,
        '\u{a0}'..='\u{ff}' => c as u32 as u8,
        '€' => 0x80,
        '…' => 0x85,
        '•' => 0x95,
        '–' => 0x96,
        '—' => 0x97,
        '‘' => 0x91,
        '’' => 0x92,
        '“' => 0x93,
        '”' => 0x94,
        _ => b'?',
    }
}

/// Texto pronto para WinAnsi (troca o que não existe por equivalentes).
fn prepare(s: &str) -> String {
    s.replace('≥', ">=").replace('≤', "<=").replace('→', "->").replace('\n', " ")
}

fn char_width(b: u8, font: Font) -> f64 {
    if font == Font::Mono {
        return 600.0;
    }
    let table = if font == Font::Bold { &HELV_BOLD } else { &HELV };
    let w = match b {
        32..=126 => table[(b - 32) as usize],
        0xC0..=0xC5 | 0xC8..=0xCB => 667,
        0xC7 | 0xD1 | 0xD9..=0xDC => 722,
        0xCC..=0xCF | 0xEC..=0xEF => 278,
        0xD2..=0xD6 => 778,
        0xD7 | 0xF7 => 584,
        0xB7 => 278,
        0xB0 => 400,
        0x96 => 556,
        0x97 => 1000,
        0xE7 => {
            if font == Font::Bold {
                556
            } else {
                500
            }
        }
        _ => {
            if font == Font::Bold {
                611
            } else {
                556
            }
        }
    };
    f64::from(w)
}

fn text_width(s: &str, font: Font, size: f64) -> f64 {
    s.chars().map(|c| char_width(win_ansi(c), font)).sum::<f64>() * size / 1000.0
}

/// Quebra em linhas que cabem em `width`. Palavras longas demais (hashes) são cortadas.
fn wrap(s: &str, font: Font, size: f64, width: f64) -> Vec<String> {
    let s = prepare(s);
    let mut lines = Vec::new();
    let mut cur = String::new();
    for word in s.split(' ') {
        let candidate = if cur.is_empty() { word.to_string() } else { format!("{cur} {word}") };
        if text_width(&candidate, font, size) <= width {
            cur = candidate;
            continue;
        }
        if !cur.is_empty() {
            lines.push(std::mem::take(&mut cur));
        }
        // A palavra sozinha não cabe: corta por caractere.
        let mut piece = String::new();
        for c in word.chars() {
            piece.push(c);
            if text_width(&piece, font, size) > width && piece.chars().count() > 1 {
                piece.pop();
                lines.push(std::mem::take(&mut piece));
                piece.push(c);
            }
        }
        cur = piece;
    }
    if !cur.is_empty() || lines.is_empty() {
        lines.push(cur);
    }
    lines
}

fn pdf_string(s: &str) -> String {
    let mut o = String::from("(");
    for c in prepare(s).chars() {
        match win_ansi(c) {
            b'(' => o.push_str("\\("),
            b')' => o.push_str("\\)"),
            b'\\' => o.push_str("\\\\"),
            b @ 32..=126 => o.push(b as char),
            b => {
                let _ = write!(o, "\\{b:03o}");
            }
        }
    }
    o.push(')');
    o
}

fn rgb(hex: &str) -> String {
    let v = u32::from_str_radix(hex.trim_start_matches('#'), 16).unwrap_or(0);
    let c = |shift: u32| f64::from((v >> shift) & 0xff) / 255.0;
    format!("{:.3} {:.3} {:.3}", c(16), c(8), c(0))
}

const DEEP: &str = "#073b4c";
const TEXT: &str = "#17212b";
const MUTED: &str = "#64748b";
const LINE: &str = "#e2e8f0";
const HEAD_BG: &str = "#eef6f8";

struct Writer {
    pages: Vec<String>,
    cur: String,
    y: f64,
    footer: String,
    lang: Lang,
}

impl Writer {
    fn new(footer: String, lang: Lang) -> Self {
        Self { pages: Vec::new(), cur: String::new(), y: PAGE_H - MARGIN, footer, lang }
    }

    fn text(&mut self, x: f64, y: f64, s: &str, font: Font, size: f64, color: &str) {
        let _ = writeln!(
            self.cur,
            "BT /{} {size:.2} Tf {} rg {x:.2} {y:.2} Td {} Tj ET",
            font.name(),
            rgb(color),
            pdf_string(s)
        );
    }

    fn rect(&mut self, x: f64, y: f64, w: f64, h: f64, color: &str) {
        let _ = writeln!(self.cur, "{} rg {x:.2} {y:.2} {w:.2} {h:.2} re f", rgb(color));
    }

    fn hline(&mut self, x: f64, y: f64, w: f64) {
        let _ = writeln!(self.cur, "{} RG 0.5 w {x:.2} {y:.2} m {:.2} {y:.2} l S", rgb(LINE), x + w);
    }

    fn finish_page(&mut self) {
        let n = self.pages.len() + 1;
        let label = if self.lang == Lang::Pt { format!("página {n}") } else { format!("page {n}") };
        let footer = self.footer.clone();
        self.hline(MARGIN, BOTTOM - 14.0, CONTENT_W);
        self.text(MARGIN, BOTTOM - 26.0, &footer, Font::Regular, 7.5, MUTED);
        let w = text_width(&label, Font::Regular, 7.5);
        self.text(PAGE_W - MARGIN - w, BOTTOM - 26.0, &label, Font::Regular, 7.5, MUTED);
        self.pages.push(std::mem::take(&mut self.cur));
        self.y = PAGE_H - MARGIN;
    }

    /// Garante `h` pontos livres; senão, página nova.
    fn ensure(&mut self, h: f64) -> bool {
        if self.y - h < BOTTOM {
            self.finish_page();
            return true;
        }
        false
    }

    fn paragraph(&mut self, s: &str, font: Font, size: f64, color: &str, x: f64, width: f64) {
        let lh = size * 1.35;
        for line in wrap(s, font, size, width) {
            self.ensure(lh);
            self.y -= lh;
            self.text(x, self.y + size * 0.25, &line, font, size, color);
        }
    }

    fn header(&mut self, title: &str, subtitle: &str) {
        let tl = wrap(title, Font::Bold, 17.0, CONTENT_W - 32.0);
        let sl = wrap(subtitle, Font::Regular, 9.5, CONTENT_W - 32.0);
        let h = 20.0 + tl.len() as f64 * 22.0 + sl.len() as f64 * 13.0 + 14.0;
        self.rect(MARGIN, self.y - h, CONTENT_W, h, DEEP);
        let mut y = self.y - 20.0;
        for l in &tl {
            y -= 17.0;
            self.text(MARGIN + 16.0, y, l, Font::Bold, 17.0, "#ffffff");
            y -= 5.0;
        }
        for l in &sl {
            y -= 13.0;
            self.text(MARGIN + 16.0, y, l, Font::Regular, 9.5, "#cfe8ee");
        }
        self.y -= h + 6.0;
    }

    fn notice(&mut self, s: &str) {
        let size = 9.0;
        let lines = wrap(s, Font::Regular, size, CONTENT_W - 24.0);
        let h = lines.len() as f64 * size * 1.35 + 12.0;
        self.ensure(h + 6.0);
        self.y -= 6.0;
        self.rect(MARGIN, self.y - h, CONTENT_W, h, "#fff7e6");
        self.rect(MARGIN, self.y - h, 3.0, h, "#f59e0b");
        let mut y = self.y - 6.0;
        for l in lines {
            y -= size * 1.35;
            self.text(MARGIN + 12.0, y + size * 0.3, &l, Font::Regular, size, TEXT);
        }
        self.y -= h;
    }

    fn key_values(&mut self, kv: &[(String, String)]) {
        let size = 9.0;
        let lh = size * 1.45;
        self.y -= 4.0;
        for (k, v) in kv {
            let key_w = CONTENT_W * 0.55;
            let val_lines = wrap(v, Font::Bold, size, CONTENT_W - key_w - 8.0);
            let key_lines = wrap(k, Font::Regular, size, key_w);
            let n = val_lines.len().max(key_lines.len());
            self.ensure(n as f64 * lh + 2.0);
            let top = self.y;
            for (i, l) in key_lines.iter().enumerate() {
                self.text(MARGIN, top - (i as f64 + 1.0) * lh + 3.0, l, Font::Regular, size, MUTED);
            }
            for (i, l) in val_lines.iter().enumerate() {
                let w = text_width(l, Font::Bold, size);
                self.text(PAGE_W - MARGIN - w, top - (i as f64 + 1.0) * lh + 3.0, l, Font::Bold, size, TEXT);
            }
            self.y -= n as f64 * lh + 2.0;
            self.hline(MARGIN, self.y + 1.0, CONTENT_W);
        }
    }

    fn table(&mut self, head: &[String], rows: &[Vec<String>], numeric: &[usize], mono: &[usize]) {
        let size = 8.0;
        let pad = 4.0;
        let font_of = |i: usize| if mono.contains(&i) { Font::Mono } else { Font::Regular };
        let size_of = |i: usize| if mono.contains(&i) { 6.6 } else { size };
        let cols = head.len();
        // Larguras naturais; se não couber, as colunas mais largas encolhem (e quebram linha).
        let mut natural: Vec<f64> = (0..cols)
            .map(|i| {
                let hw = text_width(&prepare(&head[i]), Font::Bold, size);
                let cw = rows
                    .iter()
                    .map(|r| text_width(&prepare(r.get(i).map_or("", String::as_str)), font_of(i), size_of(i)))
                    .fold(0.0, f64::max);
                // +1: folga contra arredondamento (senão o cabeçalho quebra por um fio).
                hw.max(cw) + 2.0 * pad + 1.0
            })
            .collect();
        let total: f64 = natural.iter().sum();
        if total > CONTENT_W {
            let mut budget = CONTENT_W;
            let mut open: Vec<usize> = (0..cols).collect();
            loop {
                let share = budget / open.len() as f64;
                let (small, big): (Vec<usize>, Vec<usize>) = open.iter().partition(|&&i| natural[i] <= share);
                if small.is_empty() {
                    for &i in &big {
                        natural[i] = share;
                    }
                    break;
                }
                budget -= small.iter().map(|&i| natural[i]).sum::<f64>();
                open = big;
                if open.is_empty() {
                    break;
                }
            }
        } else {
            // Sobra espaço: dividido entre as colunas.
            let extra = (CONTENT_W - total) / cols as f64;
            for w in &mut natural {
                *w += extra;
            }
        }
        let widths = natural;
        let lh = size * 1.3;

        let layout = |cells: &[String], bold: bool| -> (Vec<Vec<String>>, f64) {
            let lines: Vec<Vec<String>> = cells
                .iter()
                .enumerate()
                .map(|(i, c)| {
                    let f = if bold { Font::Bold } else { font_of(i) };
                    let sz = if bold { size } else { size_of(i) };
                    wrap(c, f, sz, widths[i] - 2.0 * pad)
                })
                .collect();
            let n = lines.iter().map(Vec::len).max().unwrap_or(1);
            (lines, n as f64 * lh + 2.0 * pad - 2.0)
        };
        // Desenha uma linha já medida (o espaço foi garantido antes).
        let draw = |w: &mut Writer, lines: &[Vec<String>], h: f64, bold: bool| {
            if bold {
                w.rect(MARGIN, w.y - h, CONTENT_W, h, HEAD_BG);
            }
            let mut x = MARGIN;
            for (i, cell) in lines.iter().enumerate() {
                let f = if bold { Font::Bold } else { font_of(i) };
                let sz = if bold { size } else { size_of(i) };
                let color = if bold { DEEP } else { TEXT };
                for (j, l) in cell.iter().enumerate() {
                    let ty = w.y - pad - (j as f64 + 1.0) * lh + 2.5;
                    let tx = if numeric.contains(&i) { x + widths[i] - pad - text_width(l, f, sz) } else { x + pad };
                    w.text(tx, ty, l, f, sz, color);
                }
                x += widths[i];
            }
            w.y -= h;
            w.hline(MARGIN, w.y, CONTENT_W);
        };

        let (head_lines, head_h) = layout(head, true);
        let mut first = true;
        for r in rows {
            let (lines, h) = layout(r, false);
            // Cabeçalho no início e repetido em cada página nova.
            if first || self.y - h < BOTTOM {
                if first {
                    self.y -= 4.0;
                }
                if self.y - head_h - h < BOTTOM {
                    self.finish_page();
                }
                draw(self, &head_lines, head_h, true);
                first = false;
            }
            draw(self, &lines, h, false);
        }
        if first {
            self.y -= 4.0;
            self.ensure(head_h);
            draw(self, &head_lines, head_h, true);
        }
    }

    fn bars(&mut self, items: &[(String, u64, &'static str)]) {
        let size = 9.0;
        let max = items.iter().map(|i| i.1).max().unwrap_or(0).max(1) as f64;
        let label_w = 150.0;
        let value_w = 70.0;
        let bar_w = CONTENT_W - label_w - value_w - 12.0;
        self.y -= 4.0;
        for (label, v, color) in items {
            self.ensure(18.0);
            self.y -= 18.0;
            self.text(MARGIN, self.y + 5.0, label, Font::Regular, size, TEXT);
            let x = MARGIN + label_w;
            self.rect(x, self.y + 3.0, bar_w, 9.0, LINE);
            let w = (*v as f64 / max * bar_w).max(if *v > 0 { 2.0 } else { 0.0 });
            self.rect(x, self.y + 3.0, w, 9.0, color);
            let value = crate::report::fmt_int(*v, self.lang);
            let vw = text_width(&value, Font::Bold, size);
            self.text(PAGE_W - MARGIN - vw, self.y + 5.0, &value, Font::Bold, size, TEXT);
        }
    }
}

/// Desenha o relatório em PDF.
pub fn render_pdf(doc: &ReportDoc) -> Vec<u8> {
    let mut w = Writer::new(doc.footer.clone(), doc.lang);
    w.header(&doc.title, &doc.subtitle);
    for b in &doc.blocks {
        match b {
            Block::Heading(t) => {
                w.ensure(40.0);
                w.y -= 10.0;
                w.paragraph(t, Font::Bold, 12.5, DEEP, MARGIN, CONTENT_W);
                w.y -= 2.0;
            }
            Block::Paragraph(t) => {
                w.y -= 3.0;
                w.paragraph(t, Font::Regular, 9.0, TEXT, MARGIN, CONTENT_W);
            }
            Block::Notice(t) => w.notice(t),
            Block::KeyValues(kv) => w.key_values(kv),
            Block::Table { head, rows, numeric, mono } => w.table(head, rows, numeric, mono),
            Block::Bars(items) => w.bars(items),
        }
    }
    w.finish_page();
    assemble(&w.pages, &doc.title)
}

fn assemble(pages: &[String], title: &str) -> Vec<u8> {
    let mut out: Vec<u8> = b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n".to_vec();
    let mut offsets: Vec<usize> = Vec::new();
    let n = pages.len();
    // Objetos: 1 catálogo, 2 páginas, 3-5 fontes, 6 info, depois (página, conteúdo) por página.
    let page_id = |i: usize| 7 + 2 * i;
    let mut obj = |out: &mut Vec<u8>, body: &[u8]| {
        offsets.push(out.len());
        let id = offsets.len();
        out.extend_from_slice(format!("{id} 0 obj\n").as_bytes());
        out.extend_from_slice(body);
        out.extend_from_slice(b"\nendobj\n");
    };
    obj(&mut out, b"<< /Type /Catalog /Pages 2 0 R >>");
    let kids: Vec<String> = (0..n).map(|i| format!("{} 0 R", page_id(i))).collect();
    obj(&mut out, format!("<< /Type /Pages /Count {n} /Kids [{}] >>", kids.join(" ")).as_bytes());
    for base in ["Helvetica", "Helvetica-Bold", "Courier"] {
        obj(
            &mut out,
            format!("<< /Type /Font /Subtype /Type1 /BaseFont /{base} /Encoding /WinAnsiEncoding >>").as_bytes(),
        );
    }
    obj(&mut out, format!("<< /Title {} /Producer (Genoz) >>", pdf_string(title)).as_bytes());
    for (i, content) in pages.iter().enumerate() {
        obj(
            &mut out,
            format!(
                "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {PAGE_W} {PAGE_H}] \
/Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents {} 0 R >>",
                page_id(i) + 1
            )
            .as_bytes(),
        );
        let mut z = ZlibEncoder::new(Vec::new(), Compression::default());
        z.write_all(content.as_bytes()).expect("memória");
        let data = z.finish().expect("memória");
        let mut body = format!("<< /Length {} /Filter /FlateDecode >>\nstream\n", data.len()).into_bytes();
        body.extend_from_slice(&data);
        body.extend_from_slice(b"\nendstream");
        obj(&mut out, &body);
    }
    let xref = out.len();
    let count = offsets.len() + 1;
    out.extend_from_slice(format!("xref\n0 {count}\n0000000000 65535 f \n").as_bytes());
    for o in &offsets {
        out.extend_from_slice(format!("{o:010} 00000 n \n").as_bytes());
    }
    out.extend_from_slice(
        format!("trailer\n<< /Size {count} /Root 1 0 R /Info 6 0 R >>\nstartxref\n{xref}\n%%EOF\n").as_bytes(),
    );
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::report::tests::sample_doc;

    fn find(hay: &[u8], needle: &[u8]) -> Option<usize> {
        hay.windows(needle.len()).position(|w| w == needle)
    }

    fn check_structure(pdf: &[u8]) -> usize {
        assert!(pdf.starts_with(b"%PDF-1.4"));
        assert!(pdf.ends_with(
            b"%%EOF
"
        ));
        let tail_at = pdf.len() - 64;
        let tail = String::from_utf8_lossy(&pdf[tail_at..]).into_owned();
        let startxref: usize = tail
            .rsplit(
                "startxref
",
            )
            .next()
            .unwrap()
            .lines()
            .next()
            .unwrap()
            .parse()
            .unwrap();
        let xref = String::from_utf8_lossy(&pdf[startxref..]).into_owned();
        assert!(xref.starts_with(
            "xref
0 "
        ));
        let entries: Vec<&str> = xref.lines().skip(3).take_while(|l| l.ends_with(" n ")).collect();
        assert!(entries.len() >= 7);
        for (i, e) in entries.iter().enumerate() {
            let off: usize = e[..10].parse().unwrap();
            assert!(pdf[off..].starts_with(format!("{} 0 obj", i + 1).as_bytes()), "objeto {}", i + 1);
        }
        let mut pages = 0;
        let mut rest = pdf;
        while let Some(p) = find(rest, b"/Type /Page ") {
            pages += 1;
            rest = &rest[p + 1..];
        }
        pages
    }

    #[test]
    fn valid_and_deterministic() {
        let pdf = render_pdf(&sample_doc(Lang::Pt));
        assert!(check_structure(&pdf) >= 1);
        assert_eq!(pdf, render_pdf(&sample_doc(Lang::Pt)));
        assert_ne!(pdf, render_pdf(&sample_doc(Lang::En)));
    }

    #[test]
    fn long_tables_paginate() {
        let mut doc = sample_doc(Lang::En);
        let rows: Vec<Vec<String>> = (0..300).map(|i| vec![format!("chr{i}"), i.to_string(), "x".repeat(64)]).collect();
        doc.blocks.push(Block::Table {
            head: vec!["a".into(), "b".into(), "c".into()],
            rows,
            numeric: vec![1],
            mono: vec![2],
        });
        assert!(check_structure(&render_pdf(&doc)) >= 5);
    }

    #[test]
    fn text_encoding_and_wrapping() {
        assert_eq!(pdf_string("Genótipo (A) \\ × ≥"), "(Gen\\363tipo \\(A\\) \\\\ \\327 >=)");
        assert_eq!(pdf_string("日本"), "(??)");
        let lines = wrap(&"a".repeat(64), Font::Mono, 6.6, 100.0);
        assert!(lines.len() > 1 && lines.iter().all(|l| text_width(l, Font::Mono, 6.6) <= 100.0));
        assert_eq!(wrap("", Font::Regular, 9.0, 100.0), vec![String::new()]);
    }
}

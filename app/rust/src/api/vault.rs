//! Módulo 11: relatórios e cofre `.genoz`. Só adapta `genoz_core::{report, pdf, pack, vault}`.
//!
//! Erros do cofre voltam como texto curto: `senha` (senha errada, arquivo alterado ou
//! truncado), `formato` (não é .genoz), `versao` (de um Genoz mais novo) ou a mensagem do núcleo.

use std::fs::File;
use std::io::{BufReader, BufWriter, Write};
use std::path::Path;

use genoz_core::pack::{read_pack, PackWriter};
use genoz_core::report::{build_report, render_html, Lang, ReportInput};
use genoz_core::vault::{is_auth_error, KdfParams, OpenReader, SealWriter};
use genoz_core::GenozError;

/// Relatório de uma análise: HTML autocontido (`pdf = false`) ou PDF.
/// JSONs vazios = ausentes (análises antigas sem estatísticas).
#[allow(clippy::too_many_arguments)]
pub fn analysis_report(
    summary_json: String,
    stats_a_json: String,
    stats_b_json: String,
    manifest_json: String,
    project: String,
    generated_at: String,
    lang: String,
    pdf: bool,
) -> Result<Vec<u8>, String> {
    let parse = |s: &str| -> Result<Option<serde_json::Value>, String> {
        if s.trim().is_empty() {
            Ok(None)
        } else {
            serde_json::from_str(s).map(Some).map_err(|e| format!("JSON inválido: {e}"))
        }
    };
    let summary = parse(&summary_json)?.ok_or("resumo ausente")?;
    let (a, b, m) = (parse(&stats_a_json)?, parse(&stats_b_json)?, parse(&manifest_json)?);
    let doc = build_report(&ReportInput {
        project: &project,
        generated_at: &generated_at,
        summary: &summary,
        stats_a: a.as_ref(),
        stats_b: b.as_ref(),
        manifest: m.as_ref(),
        lang: Lang::parse(&lang),
    });
    Ok(if pdf { genoz_core::pdf::render_pdf(&doc) } else { render_html(&doc).into_bytes() })
}

/// Um arquivo do disco que entra no pacote com o nome `path`.
pub struct PackFile {
    pub path: String,
    pub source_path: String,
}

/// Um arquivo na memória (Web, e o projeto.json).
pub struct PackBytes {
    pub path: String,
    pub data: Vec<u8>,
}

fn random32(random: &[u8]) -> Result<[u8; 32], String> {
    random.try_into().map_err(|_| "são necessários 32 bytes aleatórios".to_string())
}

fn vault_error(e: GenozError) -> String {
    match &e {
        GenozError::Io(io) if is_auth_error(io) => "senha".into(),
        GenozError::InvalidParam(m) if m.contains("versão mais nova") => "versao".into(),
        GenozError::InvalidParam(m) if m.contains("não é um arquivo .genoz") || m.contains("pacote do projeto") => {
            "formato".into()
        }
        _ => e.user_message(),
    }
}

/// Cifra arquivos do disco num `.genoz` (em fluxo). Grava em `<out>.parcial` e renomeia
/// no fim: um arquivo pela metade nunca fica com o nome final. Devolve o tamanho.
pub fn vault_seal_files(
    inline: Vec<PackBytes>,
    files: Vec<PackFile>,
    out_path: String,
    password: String,
    random: Vec<u8>,
) -> Result<u64, String> {
    let random = random32(&random)?;
    let partial = format!("{out_path}.parcial");
    let result = (|| -> Result<(), GenozError> {
        if let Some(parent) = Path::new(&out_path).parent() {
            std::fs::create_dir_all(parent)?;
        }
        let out = BufWriter::new(File::create(&partial)?);
        let sealer = SealWriter::new(out, &password, &random, KdfParams::default())?;
        let mut pack = PackWriter::new(sealer)?;
        for b in &inline {
            pack.add_bytes(&b.path, &b.data)?;
        }
        for f in &files {
            let file = File::open(&f.source_path)?;
            let size = file.metadata()?.len();
            pack.add(&f.path, size, &mut BufReader::new(file))?;
        }
        pack.finish()?.finish()?.flush()?;
        Ok(())
    })();
    if let Err(e) = result {
        let _ = std::fs::remove_file(&partial);
        return Err(vault_error(e));
    }
    std::fs::rename(&partial, &out_path).map_err(|e| e.to_string())?;
    Ok(std::fs::metadata(&out_path).map_err(|e| e.to_string())?.len())
}

/// Abre um `.genoz` e extrai tudo em `out_dir` (que é apagada se der erro: nada pela metade).
/// Devolve os caminhos extraídos, na ordem do pacote.
pub fn vault_open_to_dir(in_path: String, password: String, out_dir: String) -> Result<Vec<String>, String> {
    let out = Path::new(&out_dir);
    let mut paths = Vec::new();
    let result = (|| -> Result<(), GenozError> {
        let reader = OpenReader::new(BufReader::new(File::open(&in_path)?), &password)?;
        std::fs::create_dir_all(out)?;
        read_pack(reader, |path, _size, data| {
            let dest = out.join(path);
            if let Some(parent) = dest.parent() {
                std::fs::create_dir_all(parent)?;
            }
            let mut w = BufWriter::new(File::create(&dest)?);
            std::io::copy(data, &mut w)?;
            w.flush()?;
            paths.push(path.to_string());
            Ok(())
        })
    })();
    if let Err(e) = result {
        let _ = std::fs::remove_dir_all(out);
        return Err(vault_error(e));
    }
    Ok(paths)
}

/// Web: cifra arquivos na memória.
pub fn vault_seal_bytes(entries: Vec<PackBytes>, password: String, random: Vec<u8>) -> Result<Vec<u8>, String> {
    let random = random32(&random)?;
    (|| -> Result<Vec<u8>, GenozError> {
        let total: usize = entries.iter().map(|e| e.data.len()).sum();
        let sealer = SealWriter::new(Vec::with_capacity(total + total / 4096 + 256), &password, &random, KdfParams::default())?;
        let mut pack = PackWriter::new(sealer)?;
        for e in &entries {
            pack.add_bytes(&e.path, &e.data)?;
        }
        Ok(pack.finish()?.finish()?)
    })()
    .map_err(vault_error)
}

/// Web: abre um `.genoz` na memória.
pub fn vault_open_bytes(data: Vec<u8>, password: String) -> Result<Vec<PackBytes>, String> {
    (|| -> Result<Vec<PackBytes>, GenozError> {
        let reader = OpenReader::new(&data[..], &password)?;
        let mut out = Vec::new();
        read_pack(reader, |path, size, r| {
            let mut buf = Vec::with_capacity(size as usize);
            r.read_to_end(&mut buf)?;
            out.push(PackBytes { path: path.to_string(), data: buf });
            Ok(())
        })?;
        Ok(out)
    })()
    .map_err(vault_error)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disk_and_memory_agree_and_errors_are_coded() {
        let dir = std::env::temp_dir().join(format!("genoz_vault_test_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let src = dir.join("a.vcf");
        std::fs::write(&src, b"##fileformat=VCFv4.3\n").unwrap();
        let out = dir.join("p.genoz");
        let random = vec![3u8; 32];
        let inline = || vec![PackBytes { path: "projeto.json".into(), data: b"{}".to_vec() }];
        let files = vec![PackFile { path: "arquivos/f1".into(), source_path: src.to_string_lossy().into() }];
        let size =
            vault_seal_files(inline(), files, out.to_string_lossy().into(), "senha longa".into(), random.clone()).unwrap();
        let sealed = std::fs::read(&out).unwrap();
        assert_eq!(sealed.len() as u64, size);
        assert!(!dir.join("p.genoz.parcial").exists());

        // Mesmo conteúdo cifrado na memória = mesmos bytes (mesmo sal e nonce).
        let mem = vault_seal_bytes(
            vec![
                PackBytes { path: "projeto.json".into(), data: b"{}".to_vec() },
                PackBytes { path: "arquivos/f1".into(), data: b"##fileformat=VCFv4.3\n".to_vec() },
            ],
            "senha longa".into(),
            random,
        )
        .unwrap();
        assert_eq!(mem, sealed);

        let opened = vault_open_bytes(sealed.clone(), "senha longa".into()).unwrap();
        assert_eq!(opened.iter().map(|p| p.path.as_str()).collect::<Vec<_>>(), ["projeto.json", "arquivos/f1"]);
        let extracted = dir.join("x");
        let paths =
            vault_open_to_dir(out.to_string_lossy().into(), "senha longa".into(), extracted.to_string_lossy().into())
                .unwrap();
        assert_eq!(paths.len(), 2);
        assert_eq!(std::fs::read(extracted.join("arquivos/f1")).unwrap(), b"##fileformat=VCFv4.3\n");

        assert_eq!(vault_open_bytes(sealed.clone(), "errada".into()).err().unwrap(), "senha");
        let bad_dir = dir.join("y");
        assert_eq!(
            vault_open_to_dir(out.to_string_lossy().into(), "errada".into(), bad_dir.to_string_lossy().into()).err().unwrap(),
            "senha"
        );
        assert!(!bad_dir.exists(), "nada extraído pela metade");
        assert_eq!(vault_open_bytes(b"PK\x03\x04 nao".to_vec(), "x".into()).err().unwrap(), "formato");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn report_from_fixtures() {
        let read = |n: &str| {
            std::fs::read_to_string(std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../test/fixtures").join(n)).unwrap()
        };
        let html = analysis_report(
            read("compare_summary.json"),
            read("compare_stats_a.json"),
            String::new(),
            read("compare_manifest.json"),
            "P".into(),
            "agora".into(),
            "en".into(),
            false,
        )
        .unwrap();
        assert!(String::from_utf8(html).unwrap().contains("Genotype concordance"));
        let pdf = analysis_report(read("compare_summary.json"), String::new(), String::new(), String::new(), "P".into(), "x".into(), "pt".into(), true)
            .unwrap();
        assert!(pdf.starts_with(b"%PDF-1.4"));
        assert!(analysis_report(String::new(), String::new(), String::new(), String::new(), "P".into(), "x".into(), "pt".into(), true).is_err());
    }
}

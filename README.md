# Genoz

Plataforma genômica **local-first** para ensino e pesquisa — Web, Android e iOS.
Os dados genômicos são processados no próprio dispositivo; nada é enviado a servidores.

> Uso educacional e de pesquisa. **Não é ferramenta de diagnóstico.**

- Stack: Flutter/Dart (UI) · Rust (núcleo bioinformático) · WebAssembly (navegador)
- Especificação: [docs/especificacao/Genoz_especificacao_tecnica_v4.md](docs/especificacao/Genoz_especificacao_tecnica_v4.md)
- Plano de módulos até a 1.0 (APK + site): [docs/modulos/PLANO_DE_MODULOS.md](docs/modulos/PLANO_DE_MODULOS.md)
- Decisões de arquitetura: [docs/adr/](docs/adr/)
- Referências oficiais (VCF, BGZF, tabix, crypt4gh etc.): [docs/referencias/](docs/referencias/)

## Status

| Módulo | Situação |
|---|---|
| 1 — Núcleo Rust: leitura de VCF | concluído |
| 2 — Comparação, filtros e QC | próximo |

## Preparar o computador (Windows)

No PowerShell, dentro da pasta `Genoz`:

```powershell
.\tools\setup.ps1    # instala o que faltar (Rust, MinGW) — sem administrador
.\tools\doctor.ps1   # confere se está tudo pronto
```

## Experimentar o núcleo (Módulo 1)

```powershell
cd rust
cargo test --workspace                                   # roda todos os testes
cargo run --release -p genoz_cli -- synth --out demo.vcf.gz --samples 3
cargo run --release -p genoz_cli -- inspect demo.vcf.gz
cargo run --release -p genoz_cli -- inspect ..\test_fixtures\vcf\invalid_records.vcf
```

`inspect` mostra: validade, SHA-256, compressão, build (GRCh37/38), estilo dos cromossomos, contagens por tipo e cromossomo, genótipos por amostra e cada problema com o número da linha.

## Estrutura

```
rust/genoz_core   núcleo científico (compartilhado por Web, Android e iOS)
rust/genoz_cli    ferramenta de linha de comando para desenvolvimento
test_fixtures/    VCFs de teste (fictícios)
tools/            scripts de ambiente
docs/             especificação, módulos, ADRs, referências
```

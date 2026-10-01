# Genoz

Plataforma genômica **local-first** para ensino e pesquisa — Web, Android e iOS.
Os dados genômicos são processados no próprio dispositivo; nada é enviado a servidores.

> Uso educacional e de pesquisa. **Não é ferramenta de diagnóstico.**

- Stack: Flutter/Dart (UI) · Rust (núcleo bioinformático) · WebAssembly (navegador)
- Especificação: [docs/especificacao/Genoz_especificacao_tecnica_v4.md](docs/especificacao/Genoz_especificacao_tecnica_v4.md)
- Plano de módulos até a 1.0 (APK + site): [docs/modulos/PLANO_DE_MODULOS.md](docs/modulos/PLANO_DE_MODULOS.md)
- Decisões de arquitetura: [docs/adr/](docs/adr/)
- Guia de estilo (cores, logo, ícone): [docs/estilo/GUIA_DE_ESTILO.md](docs/estilo/GUIA_DE_ESTILO.md)
- Referências oficiais (VCF, BGZF, tabix, crypt4gh etc.): [docs/referencias/](docs/referencias/)

## Status

| Módulo | Situação |
|---|---|
| 1 — Núcleo Rust: leitura de VCF | concluído |
| 2 — Comparação, filtros e QC | concluído |
| 3 — App Flutter + ponte + persistência | concluído |
| 4 — Telas de análise (comparação, tabela, filtros, QC, exportação) | concluído |
| 5 — Estética e identidade visual | concluído |
| 6 — Web local-first (site de prévia) | concluído |
| 7 — Android completo (APK de prévia) | próximo |

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

Comparação A × B (Módulo 2):

```powershell
cargo run --release -p genoz_cli -- compare ..\test_fixtures\compare\pessoa_a.vcf ..\test_fixtures\compare\pessoa_b.vcf --out resultado --bed-b ..\test_fixtures\compare\pessoa_b_chamavel.bed
cargo run --release -p genoz_cli -- view resultado --category only_a,only_b
cargo run --release -p genoz_cli -- stats ..\test_fixtures\vcf\valid_small_grch38_chr.vcf
```

A pasta `resultado` recebe `rows.bgz` + `rows.idx` (tabela paginável), `summary.json`, `stats_a.json`, `stats_b.json` e `manifest.json` (reprodutibilidade).

`inspect` mostra: validade, SHA-256, compressão, build (GRCh37/38), estilo dos cromossomos, contagens por tipo e cromossomo, genótipos por amostra e cada problema com o número da linha.

## Rodar o app (Módulo 3)

Com o emulador Android aberto (ou um celular com depuração USB), no PowerShell:

```powershell
cd app
flutter run
```

Na primeira vez a compilação demora alguns minutos, porque o núcleo Rust é compilado para Android.
No app: **Novo projeto → Gerar exemplo sintético** (ou **Importar VCF**) → toque no arquivo para ver o relatório.

## Rodar o site (Módulo 6)

No PowerShell, dentro da pasta `Genoz`:

```powershell
.\tools\web.ps1
```

Depois abra http://127.0.0.1:8765/ no Chrome ou Edge. Tudo roda no navegador: os arquivos ficam
no armazenamento privado do navegador (OPFS), nada é enviado, e depois da primeira visita o site
funciona sem internet. A tela **Verificar privacidade** (menu ☰) mostra cada requisição feita.

## Estrutura

```
rust/genoz_core   núcleo científico (compartilhado por Web, Android e iOS)
rust/genoz_cli    ferramenta de linha de comando para desenvolvimento
app/              app Flutter (Android, iOS, Web)
app/rust          ponte Flutter ↔ núcleo (flutter_rust_bridge), sem lógica científica
test_fixtures/    VCFs de teste (fictícios)
tools/            scripts de ambiente
docs/             especificação, módulos, ADRs, referências
```

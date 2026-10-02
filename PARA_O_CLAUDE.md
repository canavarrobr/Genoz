# Recado do Claude para o próximo Claude

**Atualizado em:** 01/10/2026, ao concluir o **Módulo 10 — Anotação local**.
**Uso de tokens ao escrever:** ~290 mil de 15 milhões neste trecho (bem abaixo de 90%), então:

## ✅ Pode começar o Módulo 11 — Relatórios, reprodutibilidade e criptografia

Regra do usuário: ao fim de cada módulo, atualizar este recado dizendo que o próximo pode começar, **somente se o uso de tokens estiver abaixo de 90%**.

### Pendências que dependem do usuário (ações públicas ou de conta)
- **Site no GitHub Pages** (Módulo 6): Settings → Pages → Source: GitHub Actions; e variável de repositório `GENOZ_PAGES` = `1`.
- **Release do APK** (Módulo 7): criar a tag da versão atual, ex.: `v0.10.0` (o workflow "APK Android e iOS" anexa os APKs a um pre-release). Só com o "sim" do usuário.
- **Chave de assinatura** do APK: sem os secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` o APK sai com chave de depuração (cada runner tem uma diferente → atualizar pode exigir desinstalar). Gerar a chave com `keytool` e o usuário colar os 4 secrets (ou deixar para o Módulo 13).

### O que fazer no Módulo 11
Seção "Módulo 11" de `docs/modulos/PLANO_DE_MODULOS.md` (escrever o contrato antes de implementar).
Pendências que podem entrar aqui: verificar a anotação no site (Edge headless: instalar um BED/TSV próprio e ver a
coluna de genes; ClinVar de 190 MB na memória do wasm pode ser pesado — medir); exportações grandes ainda passam
pela memória do Dart (streaming).

### Como a anotação funciona (Módulo 10, ADR-016)
- Núcleo: `rust/genoz_core/src/annotation.rs` (pacote = manifest.json + records.bgz + records.idx; tipos `sites` e
  `intervals`; construtores GTF/ClinVar/BED-TSV). CLI: `genoz-cli anot build|info|query|gene`.
- Ponte: `app/rust/src/api/annotation.rs`. **Tipos auxiliares ficam em `app/rust/src/annot_open.rs`, fora de `api`:**
  o gerador do flutter_rust_bridge expõe traits e structs privados que encontra em `api` (e `frb(ignore)` não vale
  para trait) — o resultado não compila.
- Genes embutidos em `app/assets/anotacao/gencode_v50_grch3{7,8}/`, gerados com
  `genoz-cli anot build --from gtf <GTF do GENCODE> ...` (comandos no status do Módulo 10 / ADR-016). Os arquivos
  brutos ficam em `dados_brutos/` (no .gitignore; nunca commitar).
- Catálogo: `app/assets/anotacao/catalogo.json` (URL, bytes, SHA-256, metadados). O app não tem INTERNET: o navegador
  baixa, o app confere o SHA-256. Para atualizar o ClinVar: baixar o VCF novo, calcular SHA-256/tamanho, trocar o catálogo.
- Licença/aviso das fontes conhecidas são traduzidos no app (`sourceLicense`/`sourceDisclaimer` em
  `sources_section.dart`); o manifesto guarda o texto em português.
- Testes de widget com os genes embutidos: carregar `installedPackagesProvider` dentro de `tester.runAsync` antes de
  montar a tela (a cópia dos assets é E/S real e trava o `pumpAndSettle`).

### Como chip × sequenciamento funciona (Módulo 9, ADR-015)
- Núcleo: `consumer.rs` (formatos), `chip_compare.rs` (comparação por letras, só sítios do chip), `fasta.rs`
  (índice `.fai`, alinhamento à esquerda). `consumer::inspect_any` reconhece VCF, chip ou FASTA pelo conteúdo.
- CLI: `compare-chip`, `compare --fasta`, `faidx`. Fixtures fictícias em `test_fixtures/consumidor/` (gere de novo
  com `python -X utf8 gerar.py`; se mudar o conteúdo, os IDs esperados no teste da ponte mudam).
- `CompareOptions.normalize_with_reference` e `CompareSummary.chip` só aparecem no JSON quando usados: NÃO os torne
  sempre presentes (mudaria o ID de todas as análises antigas e o hash dourado).

### Como o modo estudante funciona (Módulo 8)
- Conteúdo em `app/assets/aprender/` (trilhas.json, glossario.json, dados/). Perguntas novas: `compute` em
  `lib/features/learn/grading.dart` (respostas são CALCULADAS do resultado, ADR-014).
- O dataset sintético foi gerado com `genoz-cli synth --seed 2026 --samples 2 --variants-per-chrom 120 --chroms autossomos`.
- O `.gitignore` barra `*.vcf`/`*.vcf.gz` (dados reais nunca vão para o git); dados FICTÍCIOS novos para o app precisam de exceção explícita (como `!app/assets/aprender/dados/**`) — senão o CI não acha os assets.
- Ao mexer em textos, confira os glifos (ver "Ambiente"): caractere fora de Inter/Poppins vira quadrado no navegador.

### Ambiente (Windows) — lembretes
- **Flutter: usar PowerShell com `flutter.bat`.** No Git Bash, o script `flutter` resolve a junction `C:\flutter` para o caminho real com espaço, e os build hooks quebram ("'C:\Users\Cauan' não é reconhecido").
- PowerShell: `$env:PATH = "C:\flutter\bin;C:\mingw64\bin;$env:USERPROFILE\.cargo\bin;" + $env:PATH`
- Site local: `.\tools\web.ps1` (build-web do Rust + `flutter build web` + servidor em 127.0.0.1:8765).
- **Testar o site:** o painel de navegador embutido do app Claude bloqueia service workers e trava o Drift — usar Edge headless via CDP (script em Node 22, que já tem WebSocket; modelo usado: `edge_ctl.mjs` no scratchpad da sessão do Módulo 6) ou o Chrome do usuário.
- Logs do GitHub Actions exigem login; no workflow do app, quando `flutter test` falha, o trecho do erro vira anotação pública: `GET /repos/canavarrobr/Genoz/check-runs/<job_id>/annotations`.
- Rust GNU + MinGW em `C:\mingw64` (ADR-007). Nightly + wasm-pack + `wasm32-unknown-unknown` instalados.
- Emulador: `C:\Android\Sdk\emulator\emulator.exe -avd ovvy_api35`; adb no Git Bash com `MSYS_NO_PATHCONV=1` (vale também para curl com `#/rota`).
- Python com acentos/barras: gravar o script com a ferramenta Write e rodar `python -X utf8 arquivo.py`. Em heredoc, barras invertidas seguidas de a, t ou f dentro de strings Python viram caracteres de controle (caminhos do Windows estragam).
- **Nunca** editar arquivos com `Get-Content/Set-Content` do PowerShell 5.1: lê como ANSI e grava com BOM (acentos estragados).
- Emulador: digital cadastrada (PIN do aparelho 1111; `adb emu finger touch 1`). `adb root` funciona (imagem google_apis) para inspecionar `/data/data/br.genoz.app`. APK de release não é "debuggable" (`run-as` não funciona).
- Telas do sistema com FLAG_SECURE saem pretas no screencap: ler a tela com `uiautomator dump`.
- Se rodar `dart run flutter_native_splash:create` de novo, conferir que os temas em `android/app/src/main/res/values*/styles.xml` continuam `Theme.AppCompat.*` (exigência da biometria).
- Depois de `flutter_rust_bridge_codegen generate`, rodar `dart run build_runner build --delete-conflicting-outputs`.
- Verificação: `cargo fmt --all --check` + `cargo clippy --workspace --all-targets -- -D warnings` + `cargo test --workspace` em `rust/` (o CI exige os três); `flutter analyze` + `flutter test` em `app/`.
- **`dart format` reformata arquivos inteiros** (estilo novo): rode só em arquivos NOVOS, nunca em arquivos existentes.
- Glifos: conferir que todo caractere visível existe em `assets/fonts/Inter-*.ttf` (fontTools, `getBestCmap()`); o site não baixa fontes de reserva.
- Testes de widget: `rootBundle.loadString` com cache prende Futures entre testes (usar `cache: false`); listas preguiçosas não constroem itens fora da tela (use `ensureVisible`/`scrollUntilVisible` com `scrollable:` explícito).
- Emulador: tela de bloqueio do aparelho tem PIN 1111 (acordar: `input keyevent 224`, deslizar, digitar 1111). O armazenamento (`/sdcard/Download`) só existe depois de desbloquear — faça `adb push` depois.
- Nunca `rm` com variável de shell no caminho (o Claude Code bloqueia): use caminho literal ou `"${VAR:?}"`.
- `sed` com `\\n` no texto de substituição vira quebra de linha de verdade: para editar código, use script Python gravado com a ferramenta Write.

### Pendências conhecidas
- Exportações muito grandes passam pela memória do Dart (Módulo 9: streaming); no navegador, limite de 400 MB por arquivo.
- Filtros por INFO/FORMAT existem no núcleo, sem tela ainda.
- Mensagens vindas do núcleo ficam sempre em português.

# Recado do Claude para o próximo Claude

**Atualizado em:** 30/09/2026, ao concluir o **Módulo 6 — Web local-first** (commit `e7365ba`).
**Uso de tokens ao escrever:** ~240 mil de 15 milhões neste trecho (bem abaixo de 90%), então:

## ✅ Pode começar o Módulo 7 — Android completo (APK de prévia)

Regra do usuário: ao fim de cada módulo, atualizar este recado dizendo que o próximo pode começar, **somente se o uso de tokens estiver abaixo de 90%**.

### Pendente do Módulo 6 (depende do usuário)
- **Publicar o site no GitHub Pages** é ação pública: só com o "sim" do usuário. Depois do sim:
  1. no repositório, Settings → Pages → Source: **GitHub Actions**;
  2. Settings → Secrets and variables → Actions → Variables: `GENOZ_PAGES` = `1`;
  3. rodar o workflow "Site (Flutter Web)" (ou um push). O site fica em `https://canavarrobr.github.io/Genoz/`.
  O `gh` não está instalado nesta máquina; sem login, o usuário faz esses dois cliques.

### O que fazer no Módulo 7
Seção "Módulo 7" de `docs/modulos/PLANO_DE_MODULOS.md` (escrever o contrato antes de implementar).

### Ambiente (Windows) — lembretes
- **Flutter: usar PowerShell com `flutter.bat`.** No Git Bash, o script `flutter` resolve a junction `C:\flutter` para o caminho real com espaço, e os build hooks quebram ("'C:\Users\Cauan' não é reconhecido").
- PowerShell: `$env:PATH = "C:\flutter\bin;C:\mingw64\bin;$env:USERPROFILE\.cargo\bin;" + $env:PATH`
- Site local: `.\tools\web.ps1` (build-web do Rust + `flutter build web` + servidor em 127.0.0.1:8765).
- **Testar o site:** o painel de navegador embutido do app Claude bloqueia service workers e trava o Drift — usar Edge headless via CDP (script em Node 22, que já tem WebSocket; modelo usado: `edge_ctl.mjs` no scratchpad da sessão do Módulo 6) ou o Chrome do usuário.
- Logs do GitHub Actions exigem login; o app workflow usa `flutter test --reporter github`, então falhas aparecem nas anotações públicas: `GET /repos/canavarrobr/Genoz/check-runs/<job_id>/annotations`.
- Rust GNU + MinGW em `C:\mingw64` (ADR-007). Nightly + wasm-pack + `wasm32-unknown-unknown` instalados.
- Emulador: `C:\Android\Sdk\emulator\emulator.exe -avd ovvy_api35`; adb no Git Bash com `MSYS_NO_PATHCONV=1` (vale também para curl com `#/rota`).
- Python com acentos/barras: gravar com a ferramenta Write e rodar `python -X utf8 arquivo.py`.
- Depois de `flutter_rust_bridge_codegen generate`, rodar `dart run build_runner build --delete-conflicting-outputs`.
- Verificação: `cargo test --workspace` + clippy em `rust/` e `app/rust/`; `flutter analyze` + `flutter test` em `app/`.

### Pendências conhecidas
- Exportações muito grandes passam pela memória do Dart (Módulo 9: streaming); no navegador, limite de 400 MB por arquivo.
- Filtros por INFO/FORMAT existem no núcleo, sem tela ainda.
- Mensagens vindas do núcleo ficam sempre em português.

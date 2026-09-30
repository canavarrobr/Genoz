# Recado do Claude para o próximo Claude

**Atualizado em:** 30/09/2026, ao concluir o **Módulo 5 — Estética** (commit `4c92afd`, CI verde).
**Uso de tokens ao escrever:** ~80 mil de 15 milhões neste trecho (bem abaixo de 90%), então:

## ✅ Pode começar o Módulo 6 — Web local-first (site de prévia)

Regra do usuário: ao fim de cada módulo, atualizar este recado dizendo que o próximo pode começar, **somente se o uso de tokens estiver abaixo de 90%**.

### O que fazer no Módulo 6
Seção "Módulo 6" de `docs/modulos/PLANO_DE_MODULOS.md` (escrever o contrato antes de implementar):
- núcleo Rust em WASM rodando em Web Worker (flutter_rust_bridge 2.13 tem suporte Web: `flutter_rust_bridge_codegen build-web`; conferir a documentação oficial antes);
- arquivos no navegador: OPFS; banco: Drift já está configurado para Web (`sqlite3.wasm` + `drift_worker.js` em `GenozDatabase.open()`, precisam ser copiados para `app/web/`);
- **atenção:** a ponte hoje recebe CAMINHOS de arquivo (`import_vcf`, `compare_files`, `result_page`, `export_rows`). No navegador não há caminhos — será preciso uma variante que receba bytes/`Blob`/OPFS (o núcleo já trabalha sobre `Read`, ADR-008);
- **atenção 2:** threads WASM exigem cabeçalhos COOP/COEP, e o GitHub Pages não permite configurá-los — avaliar modo sem threads ou `coi-serviceworker`;
- PWA offline, CSP estrita (`connect-src 'self'`), fontes já embutidas (Módulo 5);
- cliente HTTP auditado + tela "Verificar privacidade" com medição real;
- publicação automática no GitHub Pages (GitHub Actions) — confirmar com o usuário antes de ativar o Pages no repositório (ação pública).

### Ambiente (Windows) — lembretes
- PowerShell: `$env:PATH = "C:\flutter\bin;C:\mingw64\bin;$env:USERPROFILE\.cargo\bin;" + $env:PATH`
- `C:\flutter` = junction do SDK (sem espaço). Rust GNU + MinGW em `C:\mingw64` (ADR-007). Alvo `wasm32-unknown-unknown` já instalado.
- Emulador: `C:\Android\Sdk\emulator\emulator.exe -avd ovvy_api35`; adb no Git Bash com `MSYS_NO_PATHCONV=1`.
- Python com acentos/barras: gravar com a ferramenta Write e rodar `python -X utf8 arquivo.py` (heredoc do Bash quebra `\n`, `\t` e acentos).
- Marca: editar `tools/marca/gerar_marca.py` → rodar → `dart run flutter_launcher_icons` e `dart run flutter_native_splash:create` em `app/`.
- Verificação: `cargo test --workspace` + clippy em `rust/` e `app/rust/`; `flutter analyze` + `flutter test` em `app/`.

### Pendências conhecidas
- Exportações muito grandes passam pela memória do Dart (Módulo 9: streaming).
- Filtros por INFO/FORMAT existem no núcleo, sem tela ainda.
- Mensagens vindas do núcleo ficam sempre em português.

# Recado do Claude para o próximo Claude

**Atualizado em:** 30/09/2026, ao concluir o **Módulo 4** (commit `19bd495`, CI verde).
**Uso de tokens na sessão ao escrever:** ~218 mil de 15 milhões (~1,5%) — abaixo de 90%, então:

## ✅ Pode começar o Módulo 5 — Estética e identidade visual

Pedido do usuário: ao fim de cada módulo, escrever este recado dizendo que o próximo pode começar, **somente se o uso de tokens estiver abaixo de 90%**. Mantenha essa regra e atualize este arquivo ao terminar cada módulo.

### O que fazer no Módulo 5
- Base: `docs/estilo/GUIA_DE_ESTILO.md` + recortes em `docs/estilo/recortes/` (logo, ícone, menu lateral, tela de resultados, abertura, pilares).
- Contrato e entregas: seção "Módulo 5" em `docs/modulos/PLANO_DE_MODULOS.md` (escrever o contrato detalhado antes de implementar, como nos outros módulos).
- Os tokens de cor já existem em `app/lib/ui/theme.dart` (`GenozColors`, `GenozPalette`). Falta: logo/símbolo em SVG, ícone do app (Android adaptativo, iOS, favicon/PWA), splash em azul profundo, menu lateral no estilo da referência, tipografia embutida (licença livre, sem download), teste automático de contraste WCAG AA, tela "Sobre".
- Regra do guia: nada de "Impacto Alto/Moderado" como classificação própria (não é diagnóstico).

### Ambiente (Windows) — lembretes
- PowerShell: `$env:PATH = "C:\flutter\bin;C:\mingw64\bin;$env:USERPROFILE\.cargo\bin;" + $env:PATH`
- `C:\flutter` é uma junction para o SDK (caminho sem espaço). Rust GNU + MinGW em `C:\mingw64` (ADR-007).
- Emulador: `C:\Android\Sdk\emulator\emulator.exe -avd ovvy_api35`; no Git Bash use `MSYS_NO_PATHCONV=1` com o adb. Os VCFs de teste já estão em `/sdcard/Download` do emulador.
- Scripts Python com acentos: gravar com a ferramenta Write e rodar `python -X utf8 arquivo.py` (heredoc do Bash corrompe acentos e `\t`).
- Verificação completa: `cargo test --workspace` + clippy em `rust/` e `app/rust/`; `flutter analyze` + `flutter test` em `app/`; `flutter build apk --debug --target-platform android-x64`.

### Pendências conhecidas (não bloqueiam o Módulo 5)
- Exportações muito grandes passam pela memória do Dart antes do "Salvar como" (streaming no Módulo 8).
- Filtros por campos INFO/FORMAT existem no núcleo, mas ainda sem tela.
- Mensagens vindas do núcleo (ex.: evidências do build) ficam sempre em português.

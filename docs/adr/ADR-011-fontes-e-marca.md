# ADR-011 — Fontes embutidas e marca gerada por script

**Status:** aceita (30/09/2026, Módulo 5)

## Contexto
- O guia de estilo pede uma sans-serif geométrica no logotipo e uma neutra na interface.
- No Flutter Web, sem fonte embutida o app baixa a Roboto de `fonts.gstatic.com` — um recurso de terceiros que viola a política local-first (especificação, seção 5).
- O Flutter não lê `woff2`, e o suporte a fontes variáveis não aplica o peso automaticamente em todos os widgets.
- O símbolo existia só como imagem de referência (raster pequeno); ícones e telas precisam de vetor e de várias resoluções.

## Decisão
- **Poppins** (títulos e logotipo) e **Inter** (texto), ambas OFL, embutidas em `app/assets/fonts/` em pesos estáticos 400/500/600/700.
  - Poppins: arquivos estáticos do repositório oficial `google/fonts`.
  - Inter: instâncias estáticas geradas com `fontTools` a partir da fonte variável oficial (`wght` 400–700, `opsz` 14).
  - Licenças (`OFL-*.txt`) embutidas e registradas na tela de licenças do app.
- **Símbolo** redesenhado como curvas de Bézier em `tools/marca/gerar_marca.py`, que gera:
  - `simbolo.svg` (fundo claro) e `simbolo_escuro.svg` (fundo escuro, fitas mais claras para manter contraste);
  - PNGs para ícone (1024), primeiro plano do ícone adaptativo, abertura e prévias.
- Ícones de Android/iOS/Web e abertura gerados por `flutter_launcher_icons` e `flutter_native_splash` a partir desses PNGs.
- O cabeçalho com texto branco usa o gradiente azul profundo → petróleo, com o ciano só na borda direita (branco sobre ciano tem contraste 2,3:1).

## Consequências
- Mudou o desenho? Edite o script, rode `python -X utf8 tools/marca/gerar_marca.py`, depois `dart run flutter_launcher_icons` e `dart run flutter_native_splash:create` em `app/`.
- Cerca de 2 MB de fontes no app; nenhum download em tempo de execução.
- Contraste do tema é verificado por teste (`app/test/contrast_test.dart`).

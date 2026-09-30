# ADR-008 — Núcleo trabalha sobre `Read`, não sobre caminhos

**Status:** aceita (29/09/2026, Módulo 1)

## Contexto
No navegador (WASM) não existe sistema de arquivos comum: os dados chegam de `File`/OPFS em blocos. No Android, arquivos escolhidos pelo usuário chegam como *streams* do seletor.

## Decisão
Toda função científica do `genoz_core` recebe `impl std::io::Read` (ou `BufRead`). Funções com caminho (`inspect_path`) são apenas atalhos para a CLI e testes.
A detecção de compressão (texto, gzip, BGZF) é feita pelos primeiros bytes, nunca pela extensão.

## Consequências
- O mesmo código roda em Android, iOS, Web e PC.
- O SHA-256 é calculado numa passada separada sobre os bytes brutos; no Web e no Android a interface fará a leitura em paralelo à importação (Módulos 3 e 5).

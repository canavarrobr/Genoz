# ADR-012 — Web: isolamento de origem por service worker, arquivos no OPFS

**Status:** aceito · **Módulo:** 6 · **Data:** 30/09/2026

## Contexto

O núcleo Rust roda no navegador como WebAssembly com threads (flutter_rust_bridge
`build-web`). Threads WASM precisam de `SharedArrayBuffer`, que o navegador só
libera em páginas com **isolamento de origem** — cabeçalhos
`Cross-Origin-Opener-Policy: same-origin` e `Cross-Origin-Embedder-Policy: require-corp`.
O site é publicado no GitHub Pages, que **não permite configurar cabeçalhos**.

No navegador também não existem caminhos de arquivo: o que o usuário escolhe chega
como bytes, e o app precisa de um lugar privado e persistente para guardar cópias e
resultados.

## Decisão

1. **Service worker próprio** (`app/web/genoz_sw.js`) acrescenta COOP/COEP (e CORP)
   a todas as respostas do próprio site e guarda tudo em cache (rede primeiro, cache
   como reserva → funciona offline). `genoz_start.js` registra o service worker e,
   na primeira visita, recarrega a página **uma vez** para que ela já nasça isolada.
   Se mesmo assim não houver isolamento, o app mostra "navegador sem suporte" — nunca
   cai para um servidor.
2. O service worker do Flutter não é usado (`flutter_bootstrap.js` próprio).
3. **CSP na própria página:** `connect-src 'self' blob:` — a página não consegue abrir
   conexão com nenhum outro endereço. `blob:` é necessário porque o seletor de
   arquivos entrega o arquivo escolhido como URL `blob:` local. `'unsafe-eval'` é
   exigido pelo código gerado do wasm-bindgen (criação dos workers); não abre rede.
4. **Arquivos no OPFS** (Origin Private File System) atrás da interface `BlobStore`;
   banco Drift em `sqlite3.wasm` (também no OPFS). A ponte ganhou funções por bytes
   (`compare_bytes`, `result_load`, …) com a mesma lógica das funções por caminho.
5. Limite de 400 MB por arquivo no navegador, avisado antes de processar.

## Consequências

- O mesmo par de arquivos gera o mesmo ID de análise no PC, no Android e no navegador
  (verificado: `c7e0bc9d-f41f-8309-b678-5e20bea871b2` para pessoa_a × pessoa_b).
- A primeira visita tem um recarregamento rápido e invisível.
- Navegadores embutidos que bloqueiam service workers (ex.: o painel de navegador do
  app Claude) não conseguem rodar o site publicado; Chrome, Edge e Firefox atuais sim.
- Arquivos maiores que 400 MB ficam para o app Android.

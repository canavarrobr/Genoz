# ADR-017 — Relatórios pelo núcleo, reexecução pelo manifesto e cofre `.genoz` com senha

**Status:** aceito · **Módulo:** 11 · **Data:** 02/10/2026

## Contexto

O Módulo 11 pede relatório HTML/PDF, prova de reprodutibilidade e criptografia
opcional de projeto, sem servidor e sem nuvem. Até aqui, um projeto só existia
em claro no armazenamento do app, e mover dados entre aparelhos dependia de
reimportar os VCFs um por um.

## Decisão

1. **Relatório = um modelo, dois desenhos.** `genoz_core::report` monta blocos
   (títulos, avisos, tabelas, barras) a partir do JSON gravado (summary, stats,
   manifest). Assim funciona também com análises antigas. O HTML é um arquivo
   só, sem script e sem recurso externo, com CSP `default-src 'none'`. O PDF
   (`genoz_core::pdf`) é um escritor mínimo próprio: fontes padrão do PDF com
   WinAnsi (os acentos cabem), conteúdo Flate e nenhuma dependência nova.
   Os dois são determinísticos: a data de geração vem de quem chama. Português
   e inglês.
2. **Reprodutibilidade verificável.**
   - `verify` confere os SHA-256 das saídas contra o manifesto.
   - `rerun` (CLI) e "Verificar reprodutibilidade" (app) conferem os SHA-256
     das entradas e refazem a análise numa pasta temporária, com os parâmetros
     do manifesto (`parameters_from_manifest`). Depois comparam saída por saída.
   - Entrada ausente ou alterada → não reexecuta ("não provaria nada").
3. **Cofre `.genoz`.**
   - **Pacote:** `GNZPACK1`, em fluxo. Leva `projeto.json` (linhas do banco)
     mais os arquivos e os resultados. Caminhos são validados (nada de `..`
     ou absoluto).
   - **Cifra:** Argon2id (64 MiB, 3 passadas, p=1, por causa do navegador) →
     XChaCha20-Poly1305 em segmentos de 64 KiB, o desenho do crypt4gh.
   - **Segmentos:** cada um autentica o cabeçalho, o próprio índice e a marca
     de "último". Assim reordenar, truncar, acrescentar ou mexer nos parâmetros
     é detectado. O nonce é `prefixo || índice`.
   - **Aleatoriedade:** sal e prefixo vêm de quem chama (`Random.secure`). O
     núcleo não depende de `getrandom` e segue compilando para wasm32.
   - **Compatibilidade:** não é compatível com crypt4gh, que exige chaves
     X25519; a senha é o requisito do produto.
   - **Escrita:** grava em `.parcial` e renomeia. Erro na leitura apaga o que foi
     extraído: nada fica pela metade.
4. **Proteger projeto = cofre local.**
   - O projeto vira `cofres/<id>.genoz`. As linhas e os arquivos em claro são
     apagados, e depois vem `VACUUM` (sem ele, nomes de amostra e resumos ficam
     nas páginas livres do SQLite; visto no emulador).
   - Só o nome do projeto continua visível.
   - Abrir restaura com os mesmos IDs e apaga o cofre. Para cifrar de novo,
     protege-se outra vez.
   - Senha perdida = dados perdidos. O app avisa e exige confirmação.
5. **Exportar/importar** usam o mesmo cofre.
   - A importação vira um projeto novo, com IDs de projeto, arquivo e análise
     novos. O ID de análise derivado do conteúdo (`contentId`) não muda.
   - Exportar um projeto protegido copia o cofre.
   - No Android, o "Salvar como" copia o arquivo em fluxo
     (`ACTION_CREATE_DOCUMENT`, canal `genoz/arquivos`).

## Consequências

- Um projeto feito no Android abre no navegador e no PC (`genoz-cli unpack`),
  e a reexecução dá as mesmas saídas byte a byte nos três.
- Enquanto um projeto está aberto, os dados ficam em claro na área privada do app,
  como os demais. A proteção vale quando o projeto está trancado.
- Abrir ou proteger exige reescrever o cofre inteiro (custo proporcional ao tamanho).
- O navegador continua limitado a 400 MB por arquivo (cofre na memória do wasm).
- As exportações da tabela (CSV/TSV/JSON/VCF) ainda passam pela memória do Dart.

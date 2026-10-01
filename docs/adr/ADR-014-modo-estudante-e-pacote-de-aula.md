# ADR-014 — Modo estudante: respostas calculadas e pacote de aula `.genozaula`

**Status:** aceito · **Módulo:** 8 · **Data:** 01/10/2026

## Contexto

O modo estudante precisa de exercícios com correção automática e de um jeito de o
professor distribuir uma aula própria (seus arquivos e perguntas) — sem servidor,
sem contas, sem rede.

## Decisão

1. **Respostas calculadas, não gabaritos.** Cada pergunta numérica/textual declara
   *como* a resposta sai do resultado (`count:only_a`, `percent:concordance`,
   `top_chrom:only_a`, `gt:b:1:2000`…). A resposta é calculada na hora, no aparelho, a
   partir da análise real (resumo, densidade, linhas). Assim a mesma pergunta serve
   para qualquer par de arquivos e não há gabarito para vazar nem para errar.
   Só as perguntas conceituais de múltipla escolha guardam o índice da alternativa certa.
2. **Tolerâncias explícitas:** contagens exatas (aceitando `1.234`/`1,234`);
   porcentagens com ±0,05 ponto e vírgula ou ponto decimal; cromossomo com ou sem `chr`,
   empate aceita qualquer vencedor; genótipo sem ordem nem fase (`1|0` = `0/1`).
3. **Pacote `.genozaula`** = ZIP com `aula.json` (schema 1: título, instruções, quem é
   A e quem é B, perguntas, lista de arquivos com SHA-256) + `arquivos/<nome>`.
   Na importação: schema mais novo é recusado com mensagem; cada arquivo é conferido
   pelo SHA-256; nomes perdem qualquer pasta (`../`); limite de 400 MB; nada é gravado
   se algo falhar antes da importação. Depois: projeto + arquivos + comparação + aula na
   lista "Aprender", sempre com um passo para abrir a comparação.
4. **Dados didáticos embutidos e fictícios:** `pessoa_a/pessoa_b` (fixtures do projeto) e
   `sintetico_aula.vcf.gz`, gerado pelo próprio núcleo:
   `genoz-cli synth --seed 2026 --samples 2 --variants-per-chrom 120 --chroms autossomos`
   (SHA-256 `549c97bc…cf49a0`). Mesmo conteúdo em qualquer aparelho.
5. Progresso e aulas importadas ficam em `aprender/` no armazenamento privado e são
   apagados por "Apagar todos os dados".

## Consequências

- Um aluno pode abrir o `aula.json` e ver as perguntas, mas não as respostas calculadas
  (elas dependem de rodar a comparação). As de múltipla escolha ficam visíveis — aceitável
  para fins didáticos.
- O professor deve usar dados fictícios ou autorizados: o pacote leva cópias dos VCFs
  (a tela avisa).
- Novos tipos de pergunta exigem só um novo `compute` em `grading.dart` (e teste).

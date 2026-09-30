# ADR-009 — Convenção de divisão de multialélicos

**Status:** aceita (29/09/2026, Módulo 1)

## Contexto
A chave do comparador é `CHROM + POS + REF + ALT`. Um registro com `ALT=G,T` precisa virar dois registros bialélicos para que A×B compare alelo a alelo. Existem convenções diferentes para reescrever o genótipo.

## Decisão
Mesma convenção do `bcftools norm -m-`:
- no registro do ALT *i*, o alelo *i* vira `1`, a referência continua `0` e **os outros ALTs viram `0`** (ex.: `1/2` → `1/0` e `0/1`);
- campos `Number=A` e `Number=R` (INFO e FORMAT) são recortados;
- `Number=G` é recortado para ploidia 1 e 2; para outras ploidias vira `.`;
- depois da divisão, bases redundantes são aparadas mantendo uma base âncora (`TCA/TCACA` → `T/TCA`), o que não exige o genoma de referência;
- cada registro guarda `split = {alt_index, n_alts}` para o comparador saber a origem.

## Consequências
- Em `1/2`, o registro do ALT 1 mostra `1/0` (heterozigoto) — correto para "a amostra tem o alelo G?", mas perde a informação de que o outro alelo era T. Por isso `split` marca a origem, e a interface deve mostrar o registro original ao lado quando `n_alts > 1`.
- O alinhamento à esquerda (left-align) exige FASTA e fica para o Módulo 8.

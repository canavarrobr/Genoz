# ADR-010 — Ausência de registro não é genótipo de referência

**Status:** aceita (29/09/2026, Módulo 2)

## Contexto
Um VCF comum só lista posições onde algo foi chamado. Se A tem uma variante em `chr1:3000` e B não tem registro ali, isso pode significar que B é referência (0/0) **ou** que a posição não foi sequenciada ou não passou nos filtros em B. Classificar tudo como "somente em A" superestima diferenças, principalmente entre exoma e genoma, ou entre painéis diferentes.

## Decisão
Cada lado de cada linha recebe um estado que registra **por que** concluímos algo:

| Estado | Significado | Confiança na ausência |
|---|---|---|
| `explicit_ref` | GT 0/0 no próprio arquivo | alta |
| `absent_ref_block` | bloco de referência gVCF cobre a posição | alta |
| `absent_callable` | sem registro, dentro do BED chamável informado | alta |
| `absent_unknown` | sem registro, sem informação de cobertura | **baixa** (mas conta como "somente em") |
| `not_assessed` | sem registro, fora do BED chamável | nenhuma → categoria *não avaliada* |
| `missing` | GT `./.` | nenhuma → categoria *incerta* |
| `low_quality` | carrega o alelo, mas não passou no portão de qualidade | nenhuma → categoria *incerta* |

- O **portão de qualidade** (`CallFilter`) nunca apaga chamadas: quem é reprovado vira `low_quality`, e a linha fica "incerta", não "somente no outro".
- A interface (Módulo 4) mostra o estado de cada lado e destaca `absent_unknown`, sugerindo informar um BED ou usar gVCF.

## Consequências
- Com BED ou gVCF, "somente em A/B" passa a ser confiável; sem eles, o usuário vê que a conclusão é fraca.
- As métricas de benchmark (precisão/sensibilidade) ignoram linhas incertas e não avaliadas, como fazem as ferramentas de benchmark usadas na área.

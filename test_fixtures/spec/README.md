# Fixtures de conformidade (exemplos das especificações oficiais)

Exemplos copiados das especificações VCF em `docs/referencias/hts-specs/` e usados em
`rust/genoz_core/tests/spec_conformance.rs`.

| Arquivo | Origem | Ajustes feitos |
|---|---|---|
| `exemplo_principal_v4.1.vcf` … `v4.5.vcf` | Seção 1.1 "An example" de VCFv4.1, 4.2, 4.3 e 4.5 (texto idêntico entre versões) | Espaços do PDF → TAB. A versão 4.4 usa o mesmo exemplo com `##fileformat=VCFv4.4` (não temos o PDF 4.4 separado). |
| `v45_fase_psl_literal.vcf` | VCFv4.5, 1.6.2, exemplo do campo PSL | Cabeçalho mínimo acrescentado. **O exemplo oficial é inconsistente:** usa o alelo 3 com 2 ALT e `1\|2` com 1 ALT; o Genoz aponta 2 erros, corretamente. |
| `v45_fase_psl_corrigido.vcf` | Idem | ALTs completados (`T,G,C` e `C,T`) para testar a leitura da fase com prefixo (`\|0/1`, `\|1/2\|3`). |
| `v45_estruturais.vcf` | VCFv4.5, seção 5 (mesma deleção em várias notações, `<DUP>`, `<INS>`, breakend simples) | Cabeçalho acrescentado com INFO usados. |
| `v45_breakends.vcf` | VCFv4.5, 5.4 (breakends e telômero com POS 0) | IDs `bnd W` → `bnd_W` e espaços dentro de `13 : 123456` removidos (artefatos do PDF). |
| `v45_blocos_referencia.vcf` | VCFv4.5, 5.5 (blocos `<*>` com `FORMAT/LEN` e `INFO/END`) | `MIN DP` → `MIN_DP`; `;14` → `:14` (erro de digitação no PDF); nas linhas 4389 e 4396 o FORMAT ficou `GT:DP:GQ:PL`, pois o exemplo lista 6 chaves e só 4 valores. |
| `v45_normalizacao.vcf` | VCFv4.5, representação de alelos sobrepostos (`TC>TG,T` e `TCG>TG,T,TCAG`) | Cabeçalho acrescentado. |
| `v44_repeticoes_tandem.vcf` | VCFv4.5, repetições em tandem `<CNV:TR>` (introduzidas na 4.4) | Cabeçalho acrescentado. |

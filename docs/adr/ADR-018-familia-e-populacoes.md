# ADR-018 — Família e populações a partir de VCF com chamada conjunta

**Status:** aceito · **Módulo:** 12 · **Data:** 02/10/2026

## Contexto

O Módulo 12 pede quatro coisas:
- parentesco (KING-robust e IBS0);
- runs of homozygosity (ROH);
- herança num trio;
- uma matriz de N amostras.

Todas dependem de saber **quem é homozigoto de referência** em cada SNP. Num VCF
de uma pessoa só, a ausência de registro não prova referência (ADR-010): o IBS0
(AA × aa) e as contagens de heterozigotos ficariam viesados.

## Decisão

1. **Entrada: um VCF multiamostra com chamada conjunta**, que é o formato de trios
   e coortes. Entram de 2 a 32 amostras escolhidas. Para VCFs de uma pessoa só, o
   caminho continua sendo a comparação A × B, e a tela diz isso.
2. **Só autossomos e SNVs bialélicos.**
   - Multialélicos, indels e X/Y ficam de fora. O sexo é desconhecido, então
     X/Y ficam fora para não inventar erros mendelianos; a saída avisa.
   - Chamada reprovada no portão de qualidade = ausente.
   - Uma passada só, com memória proporcional a N² contadores.
3. **Parentesco: KING-robust, eq. 9.**
   - φ = (N_Aa,Aa − 2·N_AA,aa) / (N_Aa(i) + N_Aa(j)), só com SNPs genotipados
     nos dois. Não usa frequências alélicas, por isso resiste a estrutura de
     população.
   - Classes pela Tabela 1, em potências de 2:
     | φ | Classe |
     |---|---|
     | > 2^-1,5 | mesma pessoa ou gêmeos idênticos |
     | > 2^-2,5 | 1º grau |
     | > 2^-3,5 | 2º grau |
     | > 2^-4,5 | 3º grau |
     | abaixo | sem parentesco próximo |
   - Abaixo de 100 SNPs: "dados insuficientes".
4. **Pai/mãe–filho × irmãos** (dentro do 1º grau), a partir de 3 amostras:
   - π̂0 pela eq. 2, com as frequências da própria amostra. Com poucas pessoas
     essas frequências são grosseiras.
   - Mesmo assim a separação funciona, porque a diferença é grande: em
     pai/mãe–filho o IBS0 é ≈ 0 qualquer que seja a frequência; em irmãos,
     π0 ≈ 1/4.
   - O IBS0 bruto é sempre mostrado.
   - O plano inicial pedia ≥ 8 amostras. A família sintética mostrou que, só com
     o trio, a separação já é clara (IBS0 0–2 em pai/mãe–filho contra 226 em irmãos).
5. **ROH: algoritmo simplificado, inspirado no `plink --homozyg`.**
   - Trecho válido: ≥ 1000 kb, ≥ 100 SNPs, ≤ 1 heterozigoto, ≤ 5 ausentes,
     lacuna ≤ 1000 kb, ≤ 50 kb por SNP.
   - Mede F_ROH sobre a extensão autossômica coberta.
   - Não é idêntico ao PLINK, que usa janela deslizante; isso está documentado.
   - VCF fora de ordem → ROH não calculado (aviso).
6. **Trio.**
   - Classifica cada sítio em: consistente; candidata a de novo (filho(a) 0/1,
     pais 0/0); ou outro erro mendeliano.
   - Origem do alelo alternativo do(a) filho(a) heterozigoto(a): pai, mãe ou
     ambígua.
   - A lista de eventos é limitada a 5000; as contagens são completas.
7. **Interseções estilo UpSet**: as 20 combinações de portadores mais frequentes.
8. **Reprodutível.** `familia.json` + manifesto (`analysis_type: family`, parâmetros
   = opções do núcleo); `rerun` na CLI; "Verificar reprodutibilidade" no app.
9. **Dados fictícios.** `synth --family` (e o botão "Gerar família fictícia") gera:
   - avô, pai, mãe, dois filhos, um vizinho e uma duplicata;
   - plantados: 3 de novo, 1 erro mendeliano e 12 Mb de ROH no vizinho.
   Os testes conferem os valores teóricos.

## Consequências

- Os resultados batem com a teoria na família sintética:
  | Par | φ obtido |
  |---|---|
  | Pai/mãe–filho | 0,24–0,25 |
  | Irmãos | 0,248 |
  | Avô–neto | 0,12–0,13 |
  | Duplicata | 0,4995 |
  | Sem parentesco | ≈ 0 |

  O vizinho, com 12 Mb de ROH, tem φ ≈ −0,05 com todos: consanguinidade puxa o
  KING-robust para baixo. Isso é esperado e está explicado na tela.
- Sem PCA nem referências populacionais: dependem de painéis externos (ex.: 1000
  Genomes), o que seria um pacote de dados à parte.
- Textos obrigatórios em todas as abas: "estimativa estatística, sujeita a erro;
  não é teste de paternidade com valor legal nem diagnóstico".

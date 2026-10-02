# ADR-015 — Chip × sequenciamento por letras; FASTA local para normalizar

**Status:** aceito · **Módulo:** 9 · **Data:** 01/10/2026

## Contexto

Arquivos brutos de testes de consumidor (23andMe, AncestryDNA, MyHeritage,
FamilyTreeDNA) listam genótipos em letras (`AG`) em ~600 mil posições escolhidas
pelo fabricante, sem dizer qual é a base de referência. O motor de comparação
VCF × VCF casa registros por (cromossomo, posição, REF, ALT) — chave que um chip
não tem. Normalizar indels (alinhar à esquerda) exige a sequência de referência.

## Decisão

1. **Formatos reconhecidos pelo conteúdo** (`consumer::sniff`), nunca pela extensão;
   `.zip` dos fornecedores é aberto no aparelho (Dart) e o arquivo de dentro importado.
   O relatório de chip usa o mesmo formato do relatório de VCF + bloco `chip`.
2. **Comparação própria (`chip_compare`), restrita aos sítios do chip**, produzindo as
   mesmas linhas/resumo da comparação comum (tabela, mapa, exportação e aulas funcionam):
   - genótipos comparados como **conjunto de letras** (ordem e fase não importam;
     multialélicos divididos recombinados pela dosagem de cada ALT; haploide `A` = `A/A`);
   - VCF sem registro só é referência com bloco gVCF ou região avaliada (ADR-010);
   - sem FASTA, homozigotos do chip sem registro no VCF **não são julgados** (contados);
   - alelos complementares não palindrômicos → "possível troca de fita" (aviso);
   - variantes do VCF fora do chip só são contadas; Jaccard não se aplica (`null`);
   - concordância também sem os sítios referência × referência (o chip é dominado por eles).
3. **Builds:** chips são GRCh37 (declarado ou presumido com aviso); VCF GRCh38 com
   confiança alta → recusado (sem liftover local); GRCh36 → inválido.
4. **FASTA local** (`fasta.rs`): índice `.fai` idêntico ao do `samtools faidx` (lido ou
   criado; o app grava ao lado do arquivo importado), busca por posição, alinhamento à
   esquerda (VT normalize). VCF × VCF com FASTA: os dois lados são normalizados em memória
   (posições mudam → reordena) e o REF é conferido. `CompareOptions.normalize_with_reference`
   só aparece no JSON quando ligado, e o FASTA entra no manifesto como entrada `reference`:
   análises sem FASTA mantêm o mesmo ID de antes.
5. Mesma lógica na CLI (`compare-chip`, `compare --fasta`, `faidx`), na ponte por caminho
   e por memória (Web): mesmo ID de análise (testado).

## Consequências

- A comparação com chip carrega os sítios do chip em memória (~600 mil, dezenas de MB) e
  lê o VCF uma vez; a normalização VCF × VCF com FASTA carrega os dois VCFs em memória.
- FASTA compactado (`.fa.gz`) é recusado com mensagem (precisa de busca por posição).
- No navegador vale o limite de 400 MB por arquivo: FASTA só por cromossomo.
- Chips de indel (`I`/`D`) são ignorados (sem posição de base comparável).

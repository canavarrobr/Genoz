# ADR-016 — Anotação local em pacotes próprios; "online controlado" sem permissão de internet

**Status:** aceito · **Módulo:** 10 · **Data:** 01/10/2026

## Contexto

Comparar duas pessoas diz *onde* elas diferem, mas não *o que* há naquele lugar:
qual gene, o que bancos públicos como o ClinVar registram sobre a variante. As
fontes são grandes (ClinVar ~190 MB comprimido por build; GENCODE ~80–100 MB de
GTF), mudam todo mês, e o app promete não enviar nada e não ter permissão de
internet. Consultar um serviço online por variante quebraria a promessa.

## Decisão

1. **Formato de pacote próprio**, construído no aparelho (ou pela CLI):
   `manifest.json` (fonte, URL, versão, data, licença, citação, aviso, campos,
   SHA-256 da entrada e dos dados), `records.bgz` (registros ordenados, BGZF) e
   `records.idx` (JSON com blocos de 256 registros: cromossomo, menor início,
   maior fim, deslocamento virtual, quantidade). Dois tipos: `sites`
   (posição + REF/ALT, ex.: ClinVar) e `intervals` (ex.: genes). Consulta por
   região lê só os blocos que se sobrepõem; o maior fim por bloco torna correta a
   sobreposição de intervalos longos. Manifesto de versão futura é recusado.
2. **Genes GENCODE v50 embutidos** no app (GRCh38 e GRCh37 — o lift37 oficial do
   GENCODE), gerados por `genoz-cli anot build --from gtf`. A busca por gene
   funciona sem baixar nada.
3. **"Online controlado":** o APK **continua sem `INTERNET`** (o CI confere).
   O catálogo (`assets/anotacao/catalogo.json`) traz URL oficial, tamanho, licença,
   citação e **SHA-256 esperado**. O botão abre o *navegador do sistema*; o usuário
   baixa e importa o arquivo; o app só o aceita se o SHA-256 conferir. Atualizar o
   ClinVar = nova versão do app com um catálogo novo (hash fixo, auditável).
4. **Mesmo build ou nada:** pacotes só anotam análises do mesmo build (sem liftover
   local). Anotação nunca muda categoria, contagem ou o ID da análise.
5. **Atribuição sempre:** textos clínicos aparecem como "o que as fontes dizem",
   com fonte + versão + data e o aviso de cada fonte; o Genoz não classifica
   variantes nem dá conclusão.
6. **Fora deste módulo:** dbSNP completo e gnomAD (dezenas de GB; gnomAD sob ODbL
   com compartilhamento pela mesma licença) exigiriam hospedar subconjuntos — ação
   pública que depende do "sim" do usuário. rsIDs já vêm nos VCFs, chips e no ClinVar.

## Consequências

- Instalar o ClinVar leva ~30 s no PC (4,5 milhões de registros → pacote de ~80 MB);
  no celular, mais. O arquivo baixado pode ser apagado depois.
- O APK cresce com os genes embutidos (dois pacotes de poucos MB).
- "Apagar todos os dados" remove os pacotes baixados; os embutidos são copiados de novo.
- Na Web, os pacotes ficam no OPFS e são abertos da memória (`annot_load`).

## Licenças

- GENCODE: acesso aberto; EMBL-EBI não impõe restrições e pede atribuição
  (Mudge JM et al., GENCODE 2025, Nucleic Acids Res. 2025).
- ClinVar: redistribuição livre com atribuição (Landrum MJ et al., 2018, PMID 29165669);
  "não destinado a uso diagnóstico direto" — o aviso aparece no app.

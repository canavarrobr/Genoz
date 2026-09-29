# Genoz — Especificação Técnica v4.0

**Plataforma genômica local-first — Web + Android + iOS (+ Desktop)**

Versão 4.0 — 29/09/2026. Evolução da v3.0 ("Plataforma Genômica Local-First"). O produto passa a se chamar **Genoz**.
Documento-base para desenvolvimento modular assistido por Claude. Projeto acadêmico de baixo orçamento.

> **Legenda:** itens marcados com **[v4]** são novos ou alterados nesta versão. O restante vem da v3 e continua valendo.

**Princípio central:** o fluxo genômico funciona 100% no dispositivo. Web e Mobile nunca exigem upload do genoma para comparar, filtrar, visualizar, anotar ou gerar estatísticas.

**Stack:** Flutter/Dart (Android, iOS, Web e, opcionalmente, Windows/macOS/Linux) · Rust como núcleo bioinformático compartilhado · WebAssembly para o núcleo no navegador.

**Persistência:** o desenvolvedor não administra banco de dados nem escreve SQL. Claude escolhe, implementa, migra e testa toda a persistência.

---

## 1. Visão do produto

O Genoz permite importar dados genômicos, comparar amostras, visualizar diferenças, filtrar variantes, consultar genes/posições, gerar estatísticas de qualidade e produzir análises reprodutíveis. O foco é **ensino e pesquisa, não diagnóstico**.

**[v4] Público-alvo:**

| Perfil | O que busca no Genoz |
|---|---|
| Estudante de graduação/pós | Aprender VCF, variantes, genótipos e estatísticas com dados sintéticos e guias. |
| Pesquisador/bioinformata | Comparação rápida, QC, filtros e relatórios reprodutíveis sem montar pipeline. |
| Pessoa curiosa com arquivo de teste genético (23andMe, AncestryDNA, MyHeritage etc.) | Explorar os próprios dados sem enviá-los a terceiros. |
| Professor | Montar aulas com datasets didáticos e exercícios. |

## 2. Arquitetura

```
Flutter/Dart  (UI comum)
 ├── Android ─┐
 ├── iOS ─────┼── bindings nativos (flutter_rust_bridge) ──┐
 ├── Desktop ─┘                                            │
 └── Web ────── WebAssembly em Web Worker ─────────────────┤
                                                           ▼
Rust Core (genoz_core)
 ├── io: VCF/VCF.GZ/BCF, BGZF, tabix/CSI, BED, FASTA(.fai), consumidor
 ├── normalize: split multialélico, left-align, nomes de cromossomos
 ├── compare: A×B e N amostras
 ├── filters: motor de expressões
 ├── stats: QC, Ti/Tv, het/hom, ROH, parentesco
 ├── annotate: pacotes de anotação locais
 ├── crypto: hashes, criptografia de projeto/exportação
 ├── project / manifest / reports
 └── synth: gerador de datasets sintéticos
```

**[v4] Regras de arquitetura:**

- Toda lógica científica fica em Rust. Dart só orquestra, exibe e persiste metadados.
- **[v4]** No Web, o núcleo WASM roda em **Web Worker**: a interface nunca congela e toda operação longa tem progresso e botão cancelar.
- **[v4]** Processamento em **streaming** (linha a linha / bloco BGZF a bloco): o arquivo inteiro nunca precisa caber na memória.
- **[v4]** Todo resultado grande (tabela de comparação) é gravado como arquivo de resultado paginável; a UI lê só a página visível.

## 3. Tecnologias e persistência

| Camada | Escolha | Regra |
|---|---|---|
| UI | Flutter + Dart | Android, iOS, Web; Desktop opcional. |
| Estado/rotas **[v4]** | Riverpod + go_router | Padrão único em todo o app. |
| Núcleo | Rust (crate `genoz_core`) | Lógica científica compartilhada. |
| Ponte **[v4]** | flutter_rust_bridge v2 | Mesmo código Dart chama Rust nativo ou WASM. |
| Web | WebAssembly + Web Worker | Execução local no navegador. |
| Arquivos genômicos | Filesystem nativo / **OPFS** no Web **[v4]** | Arquivos grandes permanecem como arquivos. |
| Metadados do app **[v4]** | **SQLite via Drift** (nativo: sqlite3 embutido; Web: sqlite3.wasm sobre OPFS, com fallback para IndexedDB) | Decisão de Claude, ver ADR-002. |
| Resultados de análise **[v4]** | Arquivos binários colunares versionados gerados pelo Rust | Paginação rápida, sem inchar o banco. |
| SQL | Nenhuma intervenção do desenvolvedor | Claude cria esquema, migrações, queries e testes. |
| Python | Opcional | Só se uma biblioteca específica for indispensável; nunca no caminho principal. |

**Regra para Claude:** o usuário não escreve SQL, não configura banco, não executa migração manual e não administra infraestrutura. Toda a complexidade fica atrás da interface `persistence/`.

### 3.1 [v4] Decisões de arquitetura (ADRs) já tomadas

| ADR | Decisão | Motivo |
|---|---|---|
| ADR-001 | Rust + flutter_rust_bridge v2 | Um único núcleo para nativo e WASM; geração automática da ponte. |
| ADR-002 | Drift (SQLite) para metadados em todas as plataformas | Tipado, migrações automáticas versionadas, funciona no Web via WASM. O usuário nunca vê SQL. |
| ADR-003 | Genomas e resultados como arquivos (não no banco) | Tamanho; streaming; exportação simples. |
| ADR-004 | OPFS no navegador | Única API web com desempenho adequado para arquivos grandes locais. |
| ADR-005 | Nenhum servidor próprio no MVP | O site é só hospedagem estática (ex.: GitHub Pages). Zero banco externo. |
| ADR-006 | Criptografia opcional com primitivas modernas (Argon2id + XChaCha20-Poly1305; exportação alinhada ao padrão GA4GH crypt4gh) | Proteção local sem depender de serviço externo. |

Cada ADR fica em `docs/adr/` e pode ser revista, mas mudanças exigem justificativa escrita.

## 4. Princípio de armazenamento

Arquivos genômicos grandes permanecem como arquivos. Metadados, índices, projetos, histórico, notas, filtros salvos e resultados pequenos usam o banco escolhido por Claude. O critério não é "não usar banco"; é **não exigir trabalho de banco do desenvolvedor** e não guardar genomas grandes no banco sem motivo técnico.

**[v4] Modos de importação:**

- **Referenciar** (Desktop/Android com permissão persistente): o Genoz guarda só o caminho + SHA-256 e verifica a integridade ao reabrir.
- **Copiar para o projeto** (padrão no Web e iOS): o arquivo é copiado para o armazenamento privado do app (OPFS no Web).
- **[v4] Cota e limpeza:** tela "Armazenamento" mostra o espaço usado por projeto, caches e pacotes de anotação, com botão para liberar espaço.

## 5. Local-first no Web

Fluxo: `arquivo local → File API → OPFS → Flutter Web → Web Worker (Rust/WASM) → resultado local → exportação`.

O servidor apenas entrega o código estático do site. O processamento genômico nunca envia arquivos.

**[v4] Adições Web:**

- **PWA instalável e 100% offline** após o primeiro carregamento (service worker com cache de todos os assets).
- **Content-Security-Policy estrita:** `connect-src 'self'` no modo privado; sem fontes, scripts ou analytics de terceiros; todos os assets auto-hospedados.
- **Detecção de capacidade:** memória disponível, suporte a OPFS e threads WASM; o app informa limites **antes** de começar a importação.

## 6. O site é imune a vazamentos?

Não. Nenhum aplicativo Web é imune. O objetivo é impedir a transmissão dos dados genômicos no modo local e reduzir a superfície de exposição.

| Risco | Mitigação |
|---|---|
| Upload acidental | Modo privado sem qualquer rota de upload. |
| Telemetria | Nenhuma telemetria no MVP. |
| Crash reporting | Relatórios de erro locais; nunca anexam arquivos ou genótipos. |
| Chamadas externas | Política de rede por módulo + **[v4]** registro de auditoria de rede. |
| Dependências | Auditoria (`cargo audit`, `cargo deny`, `flutter pub outdated`) no CI. |
| Extensões/navegador comprometido | Não eliminável pelo app; documentado. |
| Malware no dispositivo | Não eliminável pelo app; documentado. |
| Backup em nuvem do sistema | Aviso explícito; **[v4]** opção de excluir a pasta do app do backup (Android `allowBackup=false` para dados genômicos; iOS `isExcludedFromBackup`). |
| **[v4]** Acesso físico ao aparelho | Bloqueio do app (PIN/biometria) e criptografia opcional do projeto. |
| **[v4]** Compartilhamento acidental de exportações | Exportações podem ser criptografadas com senha; aviso ao exportar genótipos brutos. |

Formulação correta: "No modo privado, as funções locais são projetadas para não transmitir dados genômicos." Nunca usar "imune a vazamento".

## 7. Modos de privacidade

| Modo | Rede | Objetivo |
|---|---|---|
| Privado | Nenhuma conexão | Padrão. Toda análise. |
| Online controlado | Somente downloads explicitamente autorizados, um a um | Baixar pacotes de anotação, datasets públicos, atualizações. **Nunca envia dados do usuário.** |
| Servidor | Dados podem sair do dispositivo | Não existe no MVP. Futuro, opt-in, módulo separado. |

**[v4]** No modo Online controlado, cada download mostra: URL, tamanho, licença e hash esperado, e o app confere o SHA-256 depois de baixar.

## 8. Indicador e verificação de privacidade

Indicador sempre visível: "🔒 Modo privado — processamento local".

**[v4] Tela "Verificar privacidade" baseada em medição real, não em texto fixo:** toda chamada de rede do app passa por um único cliente HTTP interceptado, que registra destino, horário, módulo e bytes. A tela mostra:

- arquivo genômico enviado: NÃO (conferido pelo registro)
- conexões externas durante a última análise: 0
- lista das últimas conexões (ex.: download de pacote X em tal data)
- botão "Exportar relatório de auditoria" (JSON)

**[v4] Modo avião recomendado:** botão "Analisar em modo avião" que orienta o usuário a desligar a rede e mostra que o app continua funcionando.

## 9. [v4] Nota sobre LGPD e dados sensíveis

Dados genéticos são dados pessoais sensíveis (LGPD, art. 5º, II). A arquitetura local-first **simplifica muito** a situação: o Genoz não possui servidor, conta de usuário, telemetria nem coleta de dados, portanto o projeto não recebe nem trata dados pessoais de terceiros. Mesmo assim, o app:

- não cria contas nem pede e-mail;
- permite apagar tudo (projeto, caches, índices, notas) com um botão "Apagar todos os dados do Genoz";
- informa claramente, em linguagem simples, onde os dados ficam guardados;
- trata datasets de terceiros (ex.: amostras de familiares) com aviso de que a pessoa deve ter consentimento do dono dos dados.

Nenhuma tarefa jurídica ou de infraestrutura é exigida do desenvolvedor para o MVP.

## 10. MVP

- Criar/abrir projeto local.
- Importar e validar VCF/VCF.GZ (v4.1 a v4.5), com relatório de validação legível.
- **[v4]** Importar arquivos de teste genético de consumidor (23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA) com conversão para o modelo interno.
- **[v4]** VCF multi-amostra: escolher qual amostra usar como A ou B.
- Calcular SHA-256.
- **[v4]** Detectar build de referência (GRCh37/GRCh38) e harmonizar nomes de cromossomos (`chr1` ↔ `1`, `chrM` ↔ `MT`).
- **[v4]** Normalização mínima: dividir variantes multialélicas.
- Comparar A × B.
- Shared / Only A / Only B / diferenças de genótipo / não comparável.
- Filtros por cromossomo, posição, tipo, QUAL, FILTER, DP, GQ e campos INFO/FORMAT disponíveis.
- **[v4]** Filtros salvos e construtor visual de filtros.
- Busca por posição/ID (rsID) e gene quando houver anotação.
- Estatísticas **[v4]** de QC (Ti/Tv, het/hom, SNV/indel, por cromossomo).
- Tabela virtualizada.
- Exportação (CSV/TSV, VCF de subconjunto, JSON).
- Manifesto de reprodutibilidade.
- Modo offline/privado.
- Web: comparação via WASM sem upload.
- Mobile: comparação local.
- Persistência automática sem SQL do desenvolvedor.
- **[v4]** Dataset sintético embutido para testar o app sem arquivo real.

## 11. Comparador

Chave inicial: `CHROM + POS + REF + ALT` (após harmonização de cromossomos e divisão de multialélicos). Genótipo é tratado separadamente.

| Resultado | Definição |
|---|---|
| Shared | Variante presente nas duas amostras com mesmo genótipo. |
| Only A | Somente em A. |
| Only B | Somente em B. |
| Genotype difference | Mesma variante, genótipos diferentes (ex.: 0/1 × 1/1). |
| Missing/uncertain | Dados ausentes (`./.`), filtrados ou não comparáveis. |
| **[v4]** Not assessed | A posição não foi avaliada em uma das amostras (fora das regiões chamáveis, fora do chip de genotipagem ou fora do BED informado). |

**[v4] Cuidado científico essencial:** em VCF comum, "variante ausente" **não** significa "genótipo referência". O comparador:

- aceita um **BED de regiões chamáveis** por amostra; fora dele o resultado é "Not assessed";
- entende **gVCF** (blocos de referência) quando disponível, distinguindo "referência confirmada" de "sem dados";
- ao comparar chip de consumidor × VCF de sequenciamento, restringe automaticamente aos sítios avaliados pelo chip;
- recusa comparar builds diferentes (GRCh37 × GRCh38) e explica por quê; liftover fica para fase posterior.

**[v4] Métricas de concordância:** taxa de concordância de genótipos, Jaccard de sítios, e — quando uma amostra é marcada como "verdade" — precisão, sensibilidade e F1 (útil para aulas sobre benchmark de variant calling).

**[v4] Comparação de N amostras:** matriz de similaridade N×N e gráfico de interseções (estilo UpSet) para até ~10 amostras.

## 12. Privacidade e segurança

- Não enviar VCF/BAM/CRAM/genótipos para servidor.
- Não registrar sequências ou genótipos em logs.
- Não anexar arquivos em relatórios de erro.
- Sem telemetria.
- Menor privilégio (permissões de sistema apenas quando necessárias).
- Hashes para integridade e rastreabilidade.
- Exibir claramente qualquer operação online.
- Sem fallback silencioso para servidor quando WASM ou processamento local falhar.
- **[v4]** Bloqueio do app com PIN/biometria (mobile) — opcional.
- **[v4]** Criptografia opcional de projeto com senha (Argon2id + XChaCha20-Poly1305). Aviso claro: senha perdida = dados irrecuperáveis.
- **[v4]** Exportação criptografada `.genoz` (pacote com manifesto, hashes e dados) para mover projetos entre dispositivos **sem nuvem** (via cabo, pendrive, AirDrop, Bluetooth etc.). Formato de arquivos genômicos cifrados alinhado ao padrão GA4GH **crypt4gh**.
- **[v4]** "Apagar projeto" remove também caches, índices, miniaturas e resultados derivados.
- **[v4]** Bloquear capturas de tela nas telas de genótipo (Android `FLAG_SECURE`) — opcional nas configurações.

## 13. [v4] Controle de qualidade (QC) e estatísticas

Painel de QC por amostra, todo calculado localmente:

| Métrica | Para que serve |
|---|---|
| Nº de SNVs, indels, MNVs, multialélicos | Visão geral. |
| Razão Ti/Tv | ~2,0–2,1 em genoma, ~3,0 em exoma; fora disso sugere falsos positivos. |
| Razão het/hom-alt | Indicador de qualidade e de ancestralidade/consanguinidade. |
| Distribuições de QUAL, DP, GQ | Escolher limiares de filtro. |
| Taxa de chamada e missingness | Qualidade do dataset. |
| Variantes por cromossomo e densidade por janela | Detectar anomalias. |
| Heterozigosidade no X (educacional) | Checagem de consistência do sexo cromossômico informado. **Não** é determinação de sexo ou identidade de gênero. |
| **[v4]** Runs of homozygosity (ROH) | Trechos longos de homozigose; ensino de genética de populações e consanguinidade, sempre com texto educativo e não clínico. |

## 14. [v4] Parentesco entre amostras (fase Trio/família)

Estimativa local de relacionamento entre duas amostras usando o método **KING-robust** (Manichaikul et al., 2010 — PDF em `docs/referencias/artigos/`): coeficiente de parentesco e IBS0, classificando em "mesma pessoa/gêmeos", 1º grau, 2º grau, 3º grau ou não aparentados.

- Uso principal: checagem de consistência de trios e detecção de troca de amostras.
- Texto obrigatório: estimativa estatística, sujeita a erro; não é teste de paternidade com valor legal.

## 15. [v4] Visualização

- **Ideograma cromossômico** com a posição das variantes e das diferenças A×B.
- **Mapa de densidade** por janela (1 Mb) ao longo do genoma.
- **Visualizador de região** leve: régua de posições, variantes e genes (quando houver anotação), com zoom por gesto.
- **Gráficos de QC** (histogramas, barras por cromossomo) e diagrama de interseções.
- Tema claro/escuro, paleta acessível para daltonismo, textos em pt-BR e inglês.

## 16. Genomas Brasil / Genomas SUS

| Tema | Aplicação futura |
|---|---|
| Diversidade brasileira | Conjuntos populacionais/referências brasileiras quando legitimamente disponíveis. |
| Referência brasileira | Comparação com referência autorizada. |
| Pangenoma | Arquitetura preparada; fora do MVP. |
| Capacitação | Modo estudante e datasets didáticos. |
| Pesquisa | Análises locais e relatórios reprodutíveis. |
| Privacidade | Local-first e rede opt-in. |
| Interoperabilidade | Formatos/padrões consolidados (VCF, BED, crypt4gh, GA4GH). |

Não declarar integração oficial nem incorporar bases restritas sem autorização, licença e governança.

## 17. Anotação

Anotação é módulo separado. Pode incluir gene, transcrito, consequência, frequência populacional, identificadores e classificações. Sempre guardar fonte, versão, data e licença.

**[v4] Pacotes de anotação locais:**

- Baixados uma única vez no modo Online controlado, com hash verificado; depois tudo roda offline.
- Pacotes previstos (sujeitos à verificação de licença antes da implementação): coordenadas de genes (GENCODE/RefSeq), rsIDs (dbSNP, subconjunto), ClinVar, frequências populacionais (gnomAD, subconjunto por sítio), e, quando disponíveis legitimamente, frequências brasileiras.
- O Genoz constrói índices próprios compactos para consulta rápida no celular.
- **[v4] Pacote personalizado:** o usuário pode importar seu próprio BED/TSV como anotação (ex.: lista de genes de uma disciplina).

**Classificações clínicas (ex.: ClinVar)** aparecem apenas como "o que a fonte X diz, versão Y", com link para a fonte e texto explicativo. A referência ACMG/AMP 2015 (em `docs/referencias/artigos/`) é usada somente para **explicar** as categorias ao estudante — o Genoz **não** classifica variantes por conta própria.

IA pode explicar e organizar evidências com fontes, mas não transforma evidência em diagnóstico.

## 18. [v4] Modo estudante

- **Datasets sintéticos embutidos**, gerados de forma determinística (semente fixa) pelo módulo `synth` do Rust: trio fictício, amostras com erros propositais, VCF malformado para aula de validação.
- **Trilhas guiadas:** "O que é um VCF", "Lendo um genótipo", "Por que Ti/Tv importa", "Comparando duas amostras", "Filtrando por qualidade", "O que é ROH".
- **Glossário** integrado: tocar em qualquer termo (QUAL, GQ, DP, het, hom, multialélico) abre a explicação.
- **Exercícios** com respostas verificadas automaticamente pelo núcleo (ex.: "quantas variantes somente em B passam em DP≥10?").
- **Modo professor:** exportar um pacote de aula (`.genoz` sem criptografia) com dataset, filtros e perguntas.

## 19. [v4] Organização do trabalho do usuário

- **Notas e tags** em variantes, regiões e projetos ("revisar", "interessante", "artefato provável").
- **Favoritos** de variantes.
- **Diário do projeto:** histórico automático de cada importação, filtro e análise, com data e parâmetros (alimenta o manifesto).
- **Filtros salvos** e reutilizáveis entre projetos.
- **Busca global** por rsID, posição (`chr7:117559590`), faixa (`chr7:117.5M-117.6M`) ou gene.

## 20. Reprodutibilidade

```json
{
  "analysis_id": "uuid",
  "app_version": "...",
  "core_version": "...",
  "platform": "web|android|ios|windows|macos|linux",
  "inputs": [{"name": "...", "sha256": "...", "build": "GRCh38"}],
  "parameters": {},
  "filters": [],
  "annotation_sources": [{"name": "...", "version": "...", "sha256": "...", "license": "..."}],
  "outputs": [{"name": "...", "sha256": "..."}],
  "created_at": "...",
  "status": "completed"
}
```

**[v4]** Botão **"Reexecutar a partir do manifesto"**: refaz a análise e confirma que o SHA-256 dos resultados é idêntico — prova de reprodutibilidade entre Web, Android e Desktop.

**[v4] Relatórios:** HTML autocontido (abre offline em qualquer navegador) e PDF, contendo resumo, QC, gráficos, parâmetros, manifesto e o aviso "uso educacional/pesquisa — não diagnóstico".

## 21. Testes

- Unitários: parser, normalização, comparação, filtros, estatísticas, hashes.
- Integração: importação → comparação → resultado → relatório.
- Privacidade: ausência de chamadas de rede no modo privado (teste automatizado sobre o cliente HTTP interceptado).
- WASM: equivalência bit-a-bit com o núcleo nativo (mesmos hashes de saída).
- Android/iOS: arquivos locais.
- Regressão: datasets sintéticos versionados.
- Arquivos malformados/corrompidos/truncados.
- **[v4]** Testes de propriedade (fuzzing leve) no parser VCF.
- **[v4]** Conformidade com exemplos das especificações oficiais VCF v4.1–4.5.
- Benchmarks Web, Android e iOS.
- Persistência: instalação, atualização, migração e recuperação automáticas.

## 22. Roadmap

| Fase | Entrega |
|---|---|
| 0 | Flutter + Rust + WASM; ponte; CI; gerador de datasets sintéticos. |
| 1 | Projeto local, importação, validação, hash, harmonização e comparação A×B. |
| 2 | Tabela, filtros (com filtros salvos), QC/estatísticas e exportação. |
| 3 | WASM em Web Worker + OPFS + PWA offline + limites. |
| 4 | Android/iOS, UX mobile, bloqueio do app. |
| 5 | Visualização cromossômica, modo estudante, importação de arquivos de consumidor. |
| 6 | Anotação local (pacotes) + busca por gene. |
| 7 | Relatórios HTML/PDF, reprodutibilidade verificável, exportação `.genoz` criptografada. |
| 8 | Trio/família, parentesco KING, ROH, comparação de N amostras. |
| 9 | Referências e dados populacionais brasileiros. |
| 10 | Pangenoma/múltiplas referências; liftover GRCh37↔GRCh38. |
| 11 | Integrações externas opt-in. |

## 23. Estrutura de código

```
Genoz/
  app/                      # Flutter
    lib/
      ui/                   # widgets e tema
      features/             # project, import, compare, filters, stats, viz, student, annotate, reports, settings
      services/             # ponte com Rust, rede auditada, arquivos
      models/
      persistence/          # Drift; interface estável; migrações automáticas
    test/
  rust/
    genoz_core/
      src/ io/ normalize/ compare/ filters/ stats/ annotate/ crypto/ project/ reports/ synth/
    genoz_bridge/           # API exposta ao Flutter (flutter_rust_bridge)
  test_fixtures/            # VCFs sintéticos e malformados versionados
  tools/                    # scripts de setup e build (PowerShell)
  docs/
    especificacao/
    adr/
    referencias/            # PDFs oficiais (hts-specs, artigos)
```

A camada `persistence/` esconde totalmente a tecnologia escolhida.

## 24. Instruções específicas para Claude

- Escolher e implementar a persistência (já definida em ADR-002), com esquema, migrações, índices e testes.
- Não pedir ao desenvolvedor para escrever SQL, configurar banco ou servidor.
- Não guardar genomas grandes no banco.
- Encapsular persistência atrás de interface estável; migrações automáticas.
- Não implementar tudo de uma vez. Antes de cada módulo: entradas, saídas, invariantes, erros e testes.
- Não criar servidor sem autorização explícita.
- Não duplicar lógica científica em Dart e Rust.
- Testar WASM cedo.
- Testes em todo módulo; datasets sintéticos versionados.
- Documentar decisões em ADRs.
- Não transformar resultados em diagnóstico.
- **[v4]** Consultar as especificações em `docs/referencias/` antes de implementar parsers e índices.
- **[v4]** Automatizar o ambiente: scripts `tools/setup.ps1` (verifica/instala Flutter, Rust, alvos WASM) e `tools/doctor.ps1` (diagnóstico com mensagens em português).
- **[v4]** Explicar ao desenvolvedor, em linguagem simples, o que cada etapa faz e qual comando rodar; o desenvolvedor não precisa conhecer bioinformática de baixo nível nem banco de dados.
- **[v4]** Verificar licença de todo dado externo antes de incluí-lo.

## 25. [v4] O que o desenvolvedor precisa fazer

| Tarefa | Frequência | Dificuldade |
|---|---|---|
| Instalar Flutter e Rust (script guiado) | Uma vez | Baixa |
| Rodar `tools/doctor.ps1` se algo quebrar | Quando necessário | Baixa |
| Executar o app (`flutter run -d chrome` / emulador) | Sempre que testar | Baixa |
| Testar com arquivos reais próprios e reportar problemas | Contínua | Baixa |
| Publicar o site estático (GitHub Pages) | Fase 3 | Baixa, com passo a passo |
| Banco de dados, SQL, migrações, servidor | **Nunca** | — |

## 26. Primeiro sprint

- Inicializar Flutter para Android/iOS/Web (+ Windows para testes rápidos no PC do desenvolvedor).
- Criar `genoz_core` em Rust e `genoz_bridge`.
- Configurar flutter_rust_bridge (nativo + WASM).
- Criar camada de persistência (Drift) e o modelo Project.
- Gerador de dataset sintético pequeno.
- Importar/validar VCF pequeno; calcular hash.
- Harmonizar cromossomos e dividir multialélicos.
- Comparar A×B; expor resultado ao Flutter; tabela.
- Compilar comparação para WASM e executar no navegador sem rede.
- Testar em Android com arquivo local.
- Documentar limites.

## 27. Critérios de aceite

- O mesmo algoritmo funciona em Web e Mobile, com hashes de saída idênticos.
- Web compara sem enviar arquivos; a tela de auditoria registra 0 conexões.
- Android/iOS comparam localmente.
- Filtros, QC e estatísticas funcionam.
- Há exportação, relatório e manifesto reexecutável.
- O desenvolvedor não escreve SQL nem administra banco.
- A persistência sobrevive a reinício e atualização; migrações são automáticas.
- Não há upload automático.
- Há testes automatizados rodando no CI.
- **[v4]** O app funciona offline após instalado (PWA / app nativo).

## 28. Limites e governança

A promessa correta é local-first, não "imune a vazamentos". Arquivos muito grandes (BAM/CRAM de genoma completo) e análises intensivas podem exceder recursos do navegador/celular. O sistema informa a limitação e nunca envia dados silenciosamente. **[v4]** No MVP, BAM/CRAM ficam fora do escopo; o foco é VCF/BCF e genotipagem de consumidor.

Servidor, colaboração ou nuvem podem existir futuramente como módulos separados, opt-in e sujeitos a segurança e governança.

## 29. Referências

**[v4] Documentos baixados em `docs/referencias/`:**

| Arquivo | Uso no Genoz |
|---|---|
| `hts-specs/VCFv4.5.pdf` | Especificação VCF atual (e BCFv2.2). Parser principal. |
| `hts-specs/VCFv4.3.pdf`, `VCFv4.2.pdf` | Compatibilidade com arquivos antigos (muito comuns). |
| `hts-specs/BCFv2_qref.pdf` | Referência rápida do BCF binário. |
| `hts-specs/SAMv1.pdf` | Seção BGZF (compressão de `.vcf.gz`). |
| `hts-specs/tabix.pdf`, `CSIv1.pdf` | Índices para acesso aleatório por região. |
| `hts-specs/BEDv1.pdf` | Regiões chamáveis, anotação personalizada. |
| `hts-specs/crypt4gh.pdf` | Padrão GA4GH de criptografia de arquivos genômicos (exportação `.genoz`). |
| `artigos/KING_Manichaikul2010_relacionamento.pdf` | Algoritmo de parentesco KING-robust. |
| `artigos/ACMG_AMP_Richards2015_classificacao_variantes.pdf` | Contexto educacional das categorias de classificação (sem classificação automática). |

A especificação foi construída em alinhamento conceitual com Genomas Brasil/Genomas SUS e padrões GA4GH. Antes de integrações, consultar documentação oficial atual, versões, licenças e requisitos.

Este documento é especificação de projeto acadêmico e não constitui documento oficial do Ministério da Saúde, Genomas Brasil, Genomas SUS ou GA4GH.

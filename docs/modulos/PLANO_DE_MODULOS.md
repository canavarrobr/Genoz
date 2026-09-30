# Genoz — Plano de módulos até a versão 1.0

Base: [especificação técnica v4](../especificacao/Genoz_especificacao_tecnica_v4.md).
Cada módulo termina com testes automáticos passando, commit no GitHub e uma demonstração que você mesmo consegue executar.

**Meta final (Módulo 12):** um **APK Android** instalável e um **site** público (PWA, funciona offline), ambos com as mesmas funções e processando tudo localmente.

Um APK e um site de prévia aparecem já nos Módulos 5 e 6, para você testar cedo em aparelhos reais.

---

## Visão geral

| # | Módulo | Resultado que você vê | Plataforma |
|---|---|---|---|
| 1 ✅ | Núcleo Rust: leitura de VCF | Ferramenta de linha de comando que valida um VCF, calcula SHA-256 e mostra um resumo | PC |
| 2 ✅ | Núcleo Rust: comparação, filtros e QC | Mesma ferramenta compara A×B, filtra e gera estatísticas | PC |
| 3 | App Flutter + ponte + persistência | App abre, cria projetos e importa VCF usando o núcleo Rust | Android (emulador) |
| 4 | Telas de análise | Comparação, tabela, filtros, QC, exportação e manifesto no app | Android (emulador) |
| 5 | Web local-first | **Site de prévia** (GitHub Pages) comparando VCF no navegador sem upload | Web |
| 6 | Android completo | **APK de prévia** para instalar no celular; bloqueio do app; privacidade | Android |
| 7 | Visualização + modo estudante | Ideograma, densidade, visualizador de região, trilhas guiadas, dados sintéticos | Web + Android |
| 8 | Arquivos de consumidor + multiamostra | Importa 23andMe/AncestryDNA/MyHeritage; escolhe amostra em VCF multi-amostra | Web + Android |
| 9 | Anotação local | Pacotes (genes, rsID, ClinVar, frequências) baixados uma vez; busca por gene | Web + Android |
| 10 | Relatórios, reprodutibilidade e criptografia | Relatório HTML/PDF, "reexecutar manifesto", exportação `.genoz` cifrada | Web + Android |
| 11 | Família e populações | Trio, parentesco KING, ROH, comparação de N amostras | Web + Android |
| 12 | **Lançamento 1.0** | **APK release assinado + site 1.0 publicado**, manual, desempenho, acessibilidade | Web + Android |

Pós-1.0 (fora deste plano): referências brasileiras, liftover GRCh37↔GRCh38, pangenoma, iOS publicado na App Store, integrações opt-in.

---

## Módulo 1 — Núcleo Rust: leitura de VCF

**Objetivo:** base científica sólida, testada e independente de interface.

Entregas:
- Workspace Rust `rust/` com o crate `genoz_core` e a ferramenta `genoz-cli` (para desenvolvimento e testes).
- Leitor de VCF texto e `.vcf.gz` (BGZF/gzip) em streaming, v4.1–v4.5.
- Validação com relatório legível (erros e avisos com número da linha).
- SHA-256 do arquivo em streaming.
- Harmonização de cromossomos (`chr1`↔`1`, `chrM`↔`MT`) e detecção de build (GRCh37/GRCh38) pelos comprimentos de contig.
- Divisão de variantes multialélicas em bialélicas (com genótipo reescrito).
- Classificação do tipo de variante (SNV, indel, MNV, outro).
- Gerador de datasets sintéticos determinísticos (semente fixa).
- Fixtures versionados em `test_fixtures/` (válidos e malformados).
- Script `tools/doctor.ps1` que verifica o ambiente.

Aceite: `cargo test` verde; `genoz-cli inspect arquivo.vcf.gz` mostra hash, build, amostras, contagens e problemas.

## Módulo 2 — Núcleo Rust: comparação, filtros e QC

- Comparador A×B: Shared, Only A, Only B, Genotype difference, Missing/uncertain, Not assessed (BED de regiões chamáveis, blocos gVCF).
- Recusa de comparação entre builds diferentes, com explicação.
- Métricas: concordância, Jaccard, precisão/sensibilidade/F1 quando uma amostra é "verdade".
- Motor de filtros (cromossomo, faixa, tipo, QUAL, FILTER, DP, GQ, INFO/FORMAT) com expressões serializáveis.
- Estatísticas de QC: contagens, Ti/Tv, het/hom, distribuições, missingness, densidade por janela.
- Arquivo de resultado colunar paginável.
- Manifesto de reprodutibilidade (JSON) com hashes de entrada e saída.

Aceite: `genoz-cli compare a.vcf b.vcf` gera resultado, estatísticas e manifesto; hashes estáveis entre execuções.

## Módulo 3 — App Flutter + ponte + persistência

- Projeto Flutter em `app/` (Android, iOS, Web).
- flutter_rust_bridge v2 conectando o app ao `genoz_core`.
- Persistência com Drift (SQLite) atrás da interface `persistence/`, migrações automáticas.
- Projetos locais: criar, abrir, renomear, apagar (com limpeza total).
- Importação de VCF com progresso, cancelamento e relatório de validação.
- Tema, pt-BR/inglês, indicador "Modo privado".

Aceite: no emulador, criar projeto → importar dois VCFs → ver resumo; dados persistem após reiniciar.

## Módulo 4 — Telas de análise

- Tela de comparação com resumo por categoria.
- Tabela virtualizada paginada (milhões de linhas sem travar).
- Construtor visual de filtros + filtros salvos.
- Painel de QC com gráficos.
- Exportação CSV/TSV/VCF-subconjunto/JSON + manifesto.
- Busca por posição, faixa e rsID.
- Notas, tags, favoritos e diário do projeto.

## Módulo 5 — Web local-first (site de prévia)

- Núcleo compilado para WASM rodando em Web Worker.
- Arquivos em OPFS; SQLite via sqlite3.wasm.
- PWA instalável e 100% offline; CSP estrita; nenhum asset de terceiros.
- Cliente HTTP único auditado + tela "Verificar privacidade" com medição real.
- Teste automático: nenhuma requisição de rede durante a análise.
- Publicação automática no GitHub Pages pelo GitHub Actions.

Aceite: site público compara dois VCFs com a rede desligada; resultados idênticos (hash) aos do Android.

## Módulo 6 — Android completo (APK de prévia)

- UX mobile (gestos, tamanhos de tela, modo escuro).
- Seletor de arquivos e permissões mínimas.
- Bloqueio por PIN/biometria; `FLAG_SECURE` opcional; exclusão de backup em nuvem.
- Tela "Apagar todos os dados".
- APK gerado automaticamente pelo GitHub Actions (anexado ao release).
- Configuração iOS pronta (compilação sem publicação).

## Módulo 7 — Visualização e modo estudante

- Ideograma cromossômico, mapa de densidade, visualizador de região.
- Diagrama de interseções.
- Datasets didáticos embutidos, trilhas guiadas, glossário, exercícios com correção automática, pacote de aula do professor.

## Módulo 8 — Arquivos de consumidor e multiamostra

- Importadores 23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA.
- Comparação chip × sequenciamento restrita aos sítios avaliados.
- VCF multi-amostra: seleção de amostra.
- Normalização completa opcional (left-align) com FASTA de referência local.

## Módulo 9 — Anotação local

- Formato de pacote com manifesto, licença e SHA-256.
- Download controlado (modo Online controlado), um a um, com confirmação.
- Pacotes: genes, rsIDs, ClinVar, frequências populacionais (após checagem de licença).
- Pacote personalizado (BED/TSV do usuário).
- Busca por gene; colunas de anotação na tabela; textos "o que a fonte diz" sem classificação própria.

## Módulo 10 — Relatórios, reprodutibilidade e criptografia

- Relatório HTML autocontido e PDF.
- "Reexecutar a partir do manifesto" com verificação de hash.
- Criptografia opcional de projeto (Argon2id + XChaCha20-Poly1305).
- Exportação/importação `.genoz` cifrada entre aparelhos, sem nuvem.

## Módulo 11 — Família e populações

- Trio: padrões compatíveis com herança materna/paterna e aparentemente de novo.
- Parentesco KING-robust e IBS0.
- Runs of homozygosity.
- Comparação de N amostras (matriz de similaridade).

## Módulo 12 — Lançamento 1.0

- Revisão de desempenho (benchmarks Web e Android) e limites documentados.
- Acessibilidade, traduções finais, onboarding.
- Auditoria de dependências e de privacidade.
- **APK release assinado** (chave gerada e guardada localmente, instruções simples).
- **Site 1.0** publicado no GitHub Pages (endereço `canavarrobr.github.io/Genoz`).
- Manual do usuário (PDF) e página "Sobre / Privacidade / Não é diagnóstico".
- Tag `v1.0.0` no GitHub com APK anexado.

---

## Contrato do Módulo 1 (antes de implementar)

**Entradas:** caminho de arquivo `.vcf` ou `.vcf.gz`; opcionalmente semente e parâmetros do gerador sintético.

**Saídas:**
- `FileDigest { sha256, bytes }`
- `VcfHeaderInfo { file_format, samples, contigs, build_guess, info/format definidos }`
- iterador de `Record` normalizados (cromossomo canônico, alelos, genótipos por amostra)
- `ValidationReport { errors[], warnings[], records_read, stats }`
- `InspectSummary` (contagens por tipo, por cromossomo, multialélicos divididos)

**Invariantes:**
- Streaming: memória não cresce com o tamanho do arquivo (exceto contagens agregadas).
- Mesma entrada → mesma saída, byte a byte, em qualquer plataforma.
- Nenhum acesso à rede. Nenhum dado de genótipo em logs.
- Posições 1-based como no VCF; REF nunca vazio.
- Divisão de multialélico preserva o número de amostras e reescreve GT (alelo ≠ alvo → `0`... conforme regras documentadas no código).

**Erros:** arquivo inexistente/ilegível; gzip corrompido/truncado; cabeçalho ausente ou sem `#CHROM`; linha com colunas insuficientes; POS não numérico; REF/ALT inválidos; GT inconsistente com o número de alelos; nº de amostras divergente. Erros fatais param; problemas por linha viram entradas no relatório (com limite configurável).

**Testes:** unitários de parser, GT, tipo de variante, harmonização, build, split multialélico, hash; integração com fixtures; arquivos malformados; gzip truncado; determinismo do gerador sintético; propriedade (proptest) "parse→serializa→parse" estável.

**Status:** concluído em 29/09/2026 (43 testes; CI verde em Linux, Windows, macOS e wasm32).

**Revisão (29/09/2026, antes do Módulo 3):** duas lacunas encontradas e fechadas:
1. *Conformidade com as especificações oficiais* — os exemplos das especificações VCF 4.1, 4.2, 4.3, 4.4 e 4.5 viraram fixtures (`test_fixtures/spec`, origem e ajustes documentados no README de lá). Os testes revelaram e corrigiram: breakend simples (`.CCCG`) classificado como indel; `FORMAT/LEN` (4.5) ignorado nos blocos `<*>`; `Number=P` (4.4) não reconhecido. Também revelaram erros nos próprios exemplos oficiais (alelos inexistentes no exemplo de PSL; END e LEN inconsistentes), que o Genoz agora aponta.
2. *Validação dos campos contra o cabeçalho* — INFO/FORMAT/FILTER não declarados, tipo errado (ex.: `Integer` com `abc`), número de valores errado para `Number=1/A/R/G/P`, Flag com valor, END × LEN. Tudo como aviso, uma vez por campo.

---

## Contrato do Módulo 2 (antes de implementar)

**Entradas:**
- dois VCFs (A e B), cada um com: seletor de amostra (primeira, índice ou nome), BED opcional de regiões chamáveis;
- `CallFilter` (portão de qualidade): somente PASS, QUAL/DP/GQ mínimos, condições sobre campos INFO/FORMAT;
- amostra "verdade" opcional (A ou B) para métricas de benchmark.

**Saídas:**
- linhas de comparação `ComparisonRow` (chave `CHROM:POS:REF:ALT` normalizada + categoria + visão de cada lado);
- `CompareSummary`: contagens por categoria, por tipo e por cromossomo; concordância de genótipos, Jaccard; precisão/sensibilidade/F1 (se houver verdade), separados para SNV e indel;
- `SampleStats` de cada amostra (QC): Ti/Tv, het/hom, histogramas de QUAL/DP/GQ, comprimento de indels, densidade por 1 Mb, heterozigosidade do X fora das PAR;
- pacote de resultado: `rows.bgz` (BGZF) + `rows.idx` (índice a cada 1024 linhas, paginação rápida) + `summary.json` + `stats_a.json` + `stats_b.json` + `manifest.json`.

**Categorias:**

| Categoria | Regra |
|---|---|
| Shared | as duas amostras carregam o alelo, com o mesmo genótipo |
| GenotypeDifference | as duas carregam o alelo, com genótipos diferentes (ex.: 0/1 × 1/1) |
| OnlyA / OnlyB | só um lado carrega; o outro tem 0/0 explícito, bloco de referência gVCF, está dentro do BED chamável, ou simplesmente não tem o registro (evidência "ausente" registrada) |
| MissingUncertain | um lado carrega e o outro tem genótipo ausente (`./.`) ou não passou no portão de qualidade; ou só há chamadas de baixa qualidade |
| NotAssessed | um lado carrega e a posição está fora do BED chamável do outro |

**Invariantes:**
- builds diferentes (GRCh37 × GRCh38 com confiança) → comparação recusada com explicação;
- `chr1` e `1` são o mesmo cromossomo; multialélicos são divididos e aparados antes da comparação;
- modo streaming quando os dois arquivos estão ordenados de forma compatível (memória constante); caso contrário, modo em memória, informado no resumo;
- mesmas entradas + parâmetros → mesmos bytes em `rows.bgz`, `rows.idx` e `summary.json` (o horário fica só no manifesto);
- ID da análise derivado do conteúdo (hash das entradas + parâmetros), para reprodutibilidade.

**Erros:** build incompatível; amostra inexistente (lista as disponíveis); BED malformado (linha e motivo); falhas de leitura.

**Testes:** cada categoria com fixtures A/B feitos à mão; gVCF; BED; ordenação incompatível (modo memória = modo streaming); build incompatível; filtros; estatísticas (Ti/Tv etc.) em casos calculados à mão; paginação; determinismo dos hashes; identidade A×A (tudo Shared).

**Status:** concluído em 29/09/2026 (69 testes; resultado byte a byte idêntico entre execuções; ~600 mil × 600 mil variantes em ~10 s no PC, memória constante).

# Genoz — Plano de módulos até a versão 1.0

Base: [especificação técnica v4](../especificacao/Genoz_especificacao_tecnica_v4.md).
Cada módulo termina com testes automáticos passando, commit no GitHub e uma demonstração que você mesmo consegue executar.

**Meta final (Módulo 13):** um **APK Android** instalável e um **site** público (PWA, funciona offline), ambos com as mesmas funções e processando tudo localmente.

Um APK e um site de prévia aparecem já nos Módulos 6 e 7 (depois do módulo de estética), para você testar cedo em aparelhos reais.

---

## Visão geral

| # | Módulo | Resultado que você vê | Plataforma |
|---|---|---|---|
| 1 ✅ | Núcleo Rust: leitura de VCF | Ferramenta de linha de comando que valida um VCF, calcula SHA-256 e mostra um resumo | PC |
| 2 ✅ | Núcleo Rust: comparação, filtros e QC | Mesma ferramenta compara A×B, filtra e gera estatísticas | PC |
| 3 ✅ | App Flutter + ponte + persistência | App abre, cria projetos e importa VCF usando o núcleo Rust | Android (emulador) |
| 4 ✅ | Telas de análise | Comparação, tabela, filtros, QC, exportação e manifesto no app | Android (emulador) |
| 5 ✅ | **Estética e identidade visual** | Logo, ícone, abertura, paleta, tipografia e componentes do [guia de estilo](../estilo/GUIA_DE_ESTILO.md) aplicados em todo o app | Web + Android |
| 6 ✅ | Web local-first | **Site de prévia** (GitHub Pages) comparando VCF no navegador sem upload | Web |
| 7 | Android completo | **APK de prévia** para instalar no celular; bloqueio do app; privacidade | Android |
| 8 | Visualização + modo estudante | Ideograma, densidade, visualizador de região, trilhas guiadas, dados sintéticos | Web + Android |
| 9 | Arquivos de consumidor + multiamostra | Importa 23andMe/AncestryDNA/MyHeritage; escolhe amostra em VCF multi-amostra | Web + Android |
| 10 | Anotação local | Pacotes (genes, rsID, ClinVar, frequências) baixados uma vez; busca por gene | Web + Android |
| 11 | Relatórios, reprodutibilidade e criptografia | Relatório HTML/PDF, "reexecutar manifesto", exportação `.genoz` cifrada | Web + Android |
| 12 | Família e populações | Trio, parentesco KING, ROH, comparação de N amostras | Web + Android |
| 13 | **Lançamento 1.0** | **APK release assinado + site 1.0 publicado**, manual, desempenho, acessibilidade | Web + Android |

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

## Módulo 5 — Estética e identidade visual

Base: [guia de estilo](../estilo/GUIA_DE_ESTILO.md) e recortes em `docs/estilo/recortes/`.

- Tokens de cor, tipografia, espaçamento e raios num único arquivo de tema (claro e escuro).
- Logo e símbolo redesenhados em vetor (SVG), fiéis à referência; ícone do app para Android (adaptativo), iOS e Web (favicon/PWA).
- Tela de abertura (splash) em azul profundo com símbolo e "Análise genômica local e privada".
- Menu lateral/navegação no estilo da referência (fundo azul profundo, item ativo em azul-petróleo).
- Componentes: cards, chips de categoria, barras de frequência, cabeçalho com gradiente principal, estados vazios ilustrados.
- Fontes embutidas no app (licença livre), sem download da internet.
- Acessibilidade: contraste mínimo WCAG AA verificado por teste automático; cores de estado sempre com ícone e texto.
- Tela "Sobre" com assinatura, slogan e pilares (Ciência · Privacidade · Desempenho · Multiplataforma).

Aceite: todas as telas seguem o guia; teste de contraste passando; ícone e abertura aparecem no emulador e no navegador.

## Módulo 6 — Web local-first (site de prévia)

- Núcleo compilado para WASM rodando em Web Worker.
- Arquivos em OPFS; SQLite via sqlite3.wasm.
- PWA instalável e 100% offline; CSP estrita; nenhum asset de terceiros.
- Cliente HTTP único auditado + tela "Verificar privacidade" com medição real.
- Teste automático: nenhuma requisição de rede durante a análise.
- Publicação automática no GitHub Pages pelo GitHub Actions.

Aceite: site público compara dois VCFs com a rede desligada; resultados idênticos (hash) aos do Android.

## Módulo 7 — Android completo (APK de prévia)

- UX mobile (gestos, tamanhos de tela, modo escuro).
- Seletor de arquivos e permissões mínimas.
- Bloqueio por PIN/biometria; `FLAG_SECURE` opcional; exclusão de backup em nuvem.
- Tela "Apagar todos os dados".
- APK gerado automaticamente pelo GitHub Actions (anexado ao release).
- Configuração iOS pronta (compilação sem publicação).

## Módulo 8 — Visualização e modo estudante

- Ideograma cromossômico, mapa de densidade, visualizador de região.
- Diagrama de interseções.
- Datasets didáticos embutidos, trilhas guiadas, glossário, exercícios com correção automática, pacote de aula do professor.

## Módulo 9 — Arquivos de consumidor e multiamostra

- Importadores 23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA.
- Comparação chip × sequenciamento restrita aos sítios avaliados.
- VCF multi-amostra: seleção de amostra.
- Normalização completa opcional (left-align) com FASTA de referência local.

## Módulo 10 — Anotação local

- Formato de pacote com manifesto, licença e SHA-256.
- Download controlado (modo Online controlado), um a um, com confirmação.
- Pacotes: genes, rsIDs, ClinVar, frequências populacionais (após checagem de licença).
- Pacote personalizado (BED/TSV do usuário).
- Busca por gene; colunas de anotação na tabela; textos "o que a fonte diz" sem classificação própria.

## Módulo 11 — Relatórios, reprodutibilidade e criptografia

- Relatório HTML autocontido e PDF.
- "Reexecutar a partir do manifesto" com verificação de hash.
- Criptografia opcional de projeto (Argon2id + XChaCha20-Poly1305).
- Exportação/importação `.genoz` cifrada entre aparelhos, sem nuvem.

## Módulo 12 — Família e populações

- Trio: padrões compatíveis com herança materna/paterna e aparentemente de novo.
- Parentesco KING-robust e IBS0.
- Runs of homozygosity.
- Comparação de N amostras (matriz de similaridade).

## Módulo 13 — Lançamento 1.0

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

---

## Contrato do Módulo 3 (antes de implementar)

**Entradas:** ações do usuário no app (criar/abrir/renomear/apagar projeto; importar VCF pelo seletor de arquivos; gerar dataset sintético de exemplo).

**Saídas:**
- projetos e arquivos importados persistidos localmente (sobrevivem a fechar o app e a atualizações);
- cada arquivo importado com: nome, SHA-256, tamanho, compressão, versão VCF, build, amostras, veredito e relatório de validação completo;
- tela de resumo por arquivo (veredito, build, amostras com contagens, tipos, problemas por linha).

**Arquitetura:**
- `app/` Flutter (Riverpod, go_router, gen-l10n pt-BR/en, Material 3 claro/escuro);
- `app/rust/` crate `genoz_bridge` (flutter_rust_bridge v2) que só adapta o `genoz_core` — nenhuma lógica científica nova;
- `app/lib/persistence/` Drift (SQLite) atrás de repositórios; migrações automáticas por versão de esquema;
- arquivos genômicos copiados para a pasta privada do app (`projetos/<id>/arquivos/`), nunca para o banco;
- interface `GenozCore` em Dart com implementação Rust e implementação falsa para testes.

**Invariantes:**
- nenhuma chamada de rede; nenhum genótipo em logs;
- importação com progresso e cancelamento; a interface não congela;
- apagar projeto remove banco + arquivos + resultados;
- o banco guarda metadados; o genoma continua arquivo.

**Erros:** arquivo que não é VCF (mensagem do núcleo em português); cancelamento pelo usuário; falta de espaço; arquivo ilegível.

**Testes:** repositórios (Drift em memória) com migração; importação com núcleo falso; widgets principais; teste de integração no emulador: criar projeto → importar 2 VCFs → ver resumo → reiniciar → dados continuam.

**Status:** concluído em 29/09/2026. Verificado no emulador Android (API 35): criar projeto → gerar exemplo sintético (Rust) → importar VCF pelo seletor do sistema → relatório → fechar à força e reabrir (dados mantidos) → apagar projeto (arquivos removidos). SHA-256 no Android idêntico ao do PC. 11 testes Dart + 80 Rust.
Limitações conhecidas (tratadas nos próximos módulos): mensagens vindas do núcleo (ex.: evidências do build) ficam sempre em português; no Android, arquivos `content://` são copiados pelo Dart antes da validação (Módulo 6 pode otimizar); o controlador de importação é único para o app todo.

---

## Contrato do Módulo 4 (antes de implementar)

**Entradas:** dois arquivos já importados (ou o mesmo arquivo multiamostra com amostras diferentes), amostra de cada lado, portão de qualidade (PASS, QUAL/DP/GQ mínimos), amostra "verdade" opcional; na tabela: filtros, busca e página.

**Saídas:**
- análise gravada: pasta `projetos/<id>/analises/<analise>/` com `rows.bgz`, `rows.idx`, `summary.json`, `stats_a.json`, `stats_b.json`, `manifest.json` + registro no banco;
- tela de resultado com 3 abas: **Resumo** (categorias, concordância, Jaccard, benchmark, avisos), **Tabela** (rolagem de milhões de linhas, filtros, busca por posição/faixa/ID, detalhe da variante) e **QC** (Ti/Tv, het/hom, histogramas de A e B lado a lado);
- exportação CSV, TSV, JSON e VCF (2 amostras) do resultado filtrado, sempre acompanhada do manifesto;
- filtros salvos (reutilizáveis entre análises), notas/etiquetas/favoritos por variante e diário automático do projeto.

**Arquitetura:**
- ponte Rust: `compare_files` (progresso + cancelamento), `result_page`, `result_filtered_page` (índice de linhas filtradas em cache), `export_rows`, `parse_region`;
- núcleo: `ResultReader::matching_rows` / `rows_at` e exportadores em `results.rs` (lógica científica continua no Rust);
- banco: esquema v2 com migração automática (análises, filtros salvos, notas, diário);
- cores já seguem o guia de estilo (tokens), refinadas no Módulo 5.

**Invariantes:** nenhuma rede; a interface nunca carrega o resultado inteiro na memória do Dart (só a página visível); exportações reproduzíveis (mesmo filtro → mesmo arquivo); apagar projeto apaga análises e exportações.

**Erros:** builds incompatíveis (mensagem do núcleo), amostra inexistente, região inválida na busca, falta de espaço, cancelamento.

**Testes:** Rust (linhas filtradas, acesso por índice, exportadores com hash fixo); Dart (migração v1→v2, repositórios de análises/filtros/notas/diário, controlador de comparação com núcleo falso); emulador: comparar pessoa_a × pessoa_b e conferir as mesmas contagens da CLI (5/1/4/1/1).

**Status:** concluído em 30/09/2026. Verificado no emulador Android: importar pessoa_a e pessoa_b → comparar → Resumo com 5/1/4/1/1 (igual à CLI), concordância 83,3%, Jaccard 54,5% → Tabela com filtro "Somente em A" (4 linhas) → detalhe da variante com nota e favorita → QC lado a lado → exportação CSV + manifesto para Downloads → diário completo. **O resultado no Android é byte a byte idêntico ao do PC** (rows.bgz, rows.idx, summary.json) e o ID da análise é o mesmo (parâmetros do manifesto agora montados num único lugar do núcleo). 19 testes Dart + 82 Rust.
Pendências conhecidas: exportações muito grandes passam pela memória do Dart antes do "Salvar como" (streaming no Módulo 8); filtros por campos INFO/FORMAT existem no núcleo mas ainda não têm tela (Módulo 5/8).

---

## Contrato do Módulo 5 — Estética (antes de implementar)

**Entradas:** guia de estilo (`docs/estilo/`), tokens de cor já em `app/lib/ui/theme.dart`.

**Saídas:**
- **Marca em vetor:** símbolo (dupla hélice em "S") gerado por script reproduzível `tools/marca/gerar_marca.py` → `app/assets/marca/simbolo.svg` + PNGs derivados (ícone 1024, primeiro plano do ícone adaptativo, imagem da abertura, ícones web/PWA, favicon);
- **Ícone do app** para Android (adaptativo + legado), iOS e Web, e **abertura (splash)** em azul profundo, gerados a partir desses PNGs;
- **Tipografia embutida** (licença OFL): Poppins no logotipo e títulos, Inter no texto; nada é baixado da internet (inclusive na Web);
- **Componentes:** cabeçalho com gradiente principal e slogan, menu lateral no estilo da referência (fundo azul profundo, item ativo em azul-petróleo), estados vazios com o símbolo, cards e chips com raios e sombras do guia;
- **Tela "Sobre":** assinatura, slogan, pilares (Ciência · Privacidade · Desempenho · Multiplataforma), versão do app e do núcleo, licenças (fontes incluídas);
- **Tema escuro** derivado do azul profundo.

**Invariantes:** todas as cores vêm dos tokens; nenhum recurso visual externo; cores de estado sempre com ícone e texto.

**Testes:** contraste WCAG (texto ≥ 4,5:1, elementos grandes/ícones ≥ 3:1) calculado automaticamente para os pares de cores do tema claro e escuro; teste de tela da "Sobre" e do menu; captura no emulador (ícone, abertura, telas principais em claro e escuro).

**Decisão registrada:** ADR-011 (fontes e geração da marca).

**Status:** concluído em 30/09/2026. Símbolo redesenhado em vetor por script (versões clara e escura), ícone adaptativo Android + iOS + Web, abertura em azul profundo, Poppins + Inter embutidas (sem download), cabeçalho com gradiente, menu lateral, estados vazios, tela "Sobre" com pilares e licenças, tema escuro. Contraste WCAG verificado por 39 testes automáticos (61 testes Dart no total). Capturas em `docs/estilo/capturas/`.

---

## Contrato do Módulo 6 — Web local-first (antes de implementar)

**Entradas:** o mesmo app Flutter, compilado para Web; arquivos escolhidos pelo navegador (sem caminhos).

**Saídas:**
- site estático (pasta `app/build/web`) que importa, valida, compara, filtra e exporta VCF **sem enviar nada**;
- núcleo Rust em WASM com threads (flutter_rust_bridge build-web), rodando em Web Workers;
- armazenamento: arquivos no **OPFS** do navegador; banco Drift em sqlite3.wasm;
- **service worker próprio** (`genoz_sw.js`): cache offline de todo o app (PWA) + cabeçalhos COOP/COEP exigidos pelas threads WASM (o GitHub Pages não permite configurá-los no servidor);
- **CSP estrita**: `connect-src 'self'`, nenhum script/fonte/estilo de terceiros;
- **auditoria de rede real**: todas as requisições do app são observadas (Web: `PerformanceObserver`; nativo: `HttpOverrides`) e a tela "Verificar privacidade" mostra a contagem e a lista;
- workflow do GitHub Actions que compila e publica no GitHub Pages (ativação do Pages confirmada pelo usuário).

**Arquitetura:**
- `BlobStore` (Dart): interface única de arquivos; implementação `dart:io` (nativo) e OPFS (Web), escolhida por import condicional — nenhuma tela usa `dart:io` diretamente;
- ponte: além das funções por caminho (nativo, streaming), funções por bytes (`inspect_bytes`, `compare_bytes`, `result_load`/`result_page_loaded`, `export_loaded`, `synthetic_bytes`) — mesma lógica do núcleo;
- `GenozCore` Web usa as funções por bytes; nativo continua com caminhos.

**Invariantes:** nenhuma requisição de rede durante análises (só o carregamento do próprio site); mesmo arquivo → mesmos hashes e mesmo ID de análise que no Android e no PC; limite de tamanho por arquivo no navegador informado antes de processar (nunca fallback para servidor).

**Erros:** navegador sem OPFS/WASM threads (mensagem clara); arquivo acima do limite; cota de armazenamento esgotada.

**Testes:** Rust (funções por bytes = funções por caminho, mesmos hashes); Dart (BlobStore em memória, auditoria de rede); verificação manual no navegador embutido: comparação pessoa_a × pessoa_b com lista de requisições de rede registrada e mesmo ID de análise do PC.

**Status:** concluído em 30/09/2026 (site pronto; publicação no GitHub Pages aguarda confirmação do usuário — variável `GENOZ_PAGES=1`). Verificado no Edge (headless, servidor estático **sem** cabeçalhos, como o GitHub Pages): o service worker deu isolamento de origem após um recarregamento → criar projeto → importar pessoa_a e pessoa_b pelo seletor → comparar → ID de análise `c7e0bc9d-f41f-8309-b678-5e20bea871b2`, idêntico ao do PC e do Android → "Verificar privacidade": 0 requisições externas → recarregar com o servidor desligado: app abre offline com os dados. 62 testes Dart. Decisões em [ADR-012](../adr/ADR-012-web-isolamento-por-service-worker.md).
Limitações conhecidas: o painel de navegador embutido do app Claude bloqueia service workers (usar Chrome/Edge/Firefox); limite de 400 MB por arquivo no navegador; o CSP precisa de `'unsafe-eval'` por causa do código gerado do wasm-bindgen.

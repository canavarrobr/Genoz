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
| 7 ✅ | Android completo | **APK de prévia** para instalar no celular; bloqueio do app; privacidade | Android |
| 8 ✅ | Visualização + modo estudante | Ideograma, densidade, visualizador de região, trilhas guiadas, dados sintéticos | Web + Android |
| 9 ✅ | Arquivos de consumidor + multiamostra | Importa 23andMe/AncestryDNA/MyHeritage; escolhe amostra em VCF multi-amostra | Web + Android |
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

---

## Contrato do Módulo 7 — Android completo (antes de implementar)

**Entradas:** o app dos Módulos 3–6; aparelho Android (emulador API 35) e o navegador para as opções que fazem sentido na Web.

**Saídas:**
- tela **Ajustes** (menu ☰): tema (sistema/claro/escuro), idioma (sistema/português/inglês), bloqueio do app, proteção de tela, apagar todos os dados;
- **bloqueio por PIN** (4–8 dígitos; guardado só como hash PBKDF2-SHA256 com sal; tentativas erradas geram espera crescente) e **biometria** opcional (impressão digital/rosto do sistema). O app bloqueia ao abrir e ao voltar depois de um tempo escolhido (1, 5 ou 15 min) em segundo plano;
- **proteção de tela** (`FLAG_SECURE`): impede capturas e esconde o conteúdo na lista de apps recentes (Android);
- **Apagar todos os dados**: projetos, arquivos, resultados, diário, ajustes e PIN — confirmação digitando uma palavra;
- APK de release **sem a permissão INTERNET** (nem nenhuma de armazenamento: o seletor do sistema dá acesso só ao arquivo escolhido); backup em nuvem e transferência entre aparelhos continuam excluídos;
- workflow do GitHub Actions que gera o APK a cada push (artefato) e, numa tag `v*`, o anexa a um release (criar release é ação pública: só com confirmação do usuário);
- configuração iOS pronta: o workflow compila para iOS sem assinatura.

**Invariantes:** o bloqueio não é criptografia (os arquivos continuam legíveis por quem tiver acesso de root ao aparelho; criptografia é o Módulo 11) — a tela diz isso; o PIN nunca é guardado em texto; esquecer o PIN só tem uma saída: apagar todos os dados; nada disso usa rede.

**Erros:** biometria indisponível ou não cadastrada (opção desabilitada com explicação); PIN e confirmação diferentes; muitas tentativas erradas (espera).

**Testes:** ajustes persistem e são reaplicados; hash do PIN (mesmo PIN confere, outro não, sal diferente a cada definição); espera crescente; bloqueio aparece ao iniciar e depois do tempo em segundo plano; apagar tudo deixa banco e pasta vazios; telas principais sem estouro de layout em tela pequena (320×568) com fonte 130%; verificação no emulador: permissões do APK (`aapt dump permissions`), bloqueio por PIN e por digital (`adb emu finger touch`), `FLAG_SECURE`.

**Status:** concluído em 01/10/2026 (APK gerado pelo CI; release no GitHub aguarda confirmação do usuário — tag `v*`). Verificado no emulador Android (API 35), com o APK de release:
- `aapt dump permissions`: só `USE_BIOMETRIC`/`USE_FINGERPRINT` — **sem INTERNET, sem armazenamento**; o CI falha se alguma aparecer.
- ajustes de idioma e tema aplicados na hora e mantidos depois de fechar o app; PIN definido (duas vezes) → app reaberto bloqueado → PIN errado recusado, certo aceito;
- digital cadastrada no emulador (`adb emu finger touch`) → biometria ligada e usada no desbloqueio;
- 10 s em segundo plano não bloqueia; 65 s bloqueia (prazo de 1 min);
- `FLAG_SECURE`: captura sai preta e a flag volta depois de reiniciar o app;
- "Esqueci o PIN" → digitar APAGAR → app vazio, desbloqueado, ajustes padrão; nenhum arquivo de projeto, nem as cópias do seletor de arquivos em `cache/file_picker`, nem o nome do projeto antigo dentro do `genoz.sqlite` (VACUUM).

Achados corrigidos no caminho: o seletor de arquivos deixava cópias dos VCF no cache do app (agora apagadas após cada importação e em "Apagar todos os dados"); linhas apagadas do SQLite ficavam nas páginas livres (VACUUM); o logo com assinatura e as linhas da tabela estouravam em tela de 320 px com fonte 130% (novo teste cobre todas as telas principais).
77 testes Dart. Decisões em [ADR-013](../adr/ADR-013-bloqueio-do-app.md).
Limitações: o bloqueio não criptografa os arquivos (Módulo 11); a assinatura definitiva do APK depende de secrets no repositório (até lá, chave de depuração — instalar uma versão nova pode exigir desinstalar a anterior).

---

## Contrato do Módulo 8 — Visualização e modo estudante (antes de implementar)

**Entradas:** resultados de comparação dos Módulos 2–4 (`rows.bgz` + índice, resumo); dados didáticos fictícios embutidos no app.

**Saídas — visualização (aba "Mapa" da análise e Resumo):**
- **núcleo:** `density` — contagem de variantes por cromossomo, faixa (bin) de tamanho fixo e categoria, respeitando o filtro de linhas; disponível no CLI (`genoz-cli density`), na ponte por caminho (Android/iOS) e por memória (Web);
- **ideograma:** cromossomos 1–22, X e Y em escala, com o centrômero marcado (posição aproximada, só para orientação), pintados pela densidade da categoria escolhida; cromossomo sem variantes aparece vazio, nunca omitido;
- **visualizador de região:** trilha horizontal com as variantes de um trecho (cor **e** forma por categoria), zoom e arraste, região digitável (`chr1:1.000.000-2.000.000`), lista do trecho abaixo e ficha da variante ao tocar;
- **diagrama de interseções** (A × B) no Resumo: só em A, compartilhadas (iguais / genótipo diferente) e só em B, com as não avaliadas/incertas ao lado — áreas proporcionais só quando não enganam (rótulos com números sempre).

**Saídas — modo estudante (menu ☰ → Aprender):**
- **datasets didáticos embutidos** (fictícios): par pequeno "Pessoa A × Pessoa B" e um par sintético maior (todas as autossomas) gerado pelo núcleo com semente fixa — mesmo conteúdo em qualquer aparelho;
- **trilhas guiadas** (pt/en): passos com texto, termos do glossário e botões que abrem o dataset já comparado na tela certa (Resumo, Tabela, Mapa, QC);
- **exercícios com correção automática**: as respostas são **calculadas do resultado real** (contagens por categoria, concordância, cromossomo com mais variantes, genótipo numa posição), mais perguntas conceituais de múltipla escolha; correção imediata com explicação; progresso salvo no aparelho;
- **glossário** pt/en pesquisável (VCF, alelo, genótipo, SNV, indel, QUAL/DP/GQ, FILTER, build, regiões avaliadas, concordância, Jaccard…);
- **pacote de aula do professor** (`.genozaula`): um projeto vira um arquivo (VCFs + `aula.json` com título, instruções e perguntas escolhidas); ao importar, o aluno ganha o projeto e a aula. Perguntas calculadas não levam gabarito no pacote (a resposta é calculada no aparelho do aluno).

**Invariantes:** tudo local (nenhum dado didático é baixado); dados didáticos marcados como fictícios; cor nunca é a única pista (forma/rótulo também); números do ideograma/diagrama batem com o resumo da análise; nada disso é diagnóstico.

**Erros:** build desconhecido (ideograma usa o maior posicionamento visto como comprimento e avisa); pacote de aula inválido ou de versão futura (mensagem clara, nada é importado pela metade); região inválida.

**Testes:** Rust (densidade = contagem direta das linhas; filtro respeitado; caminho = memória); Dart (ideograma/visualizador/diagrama renderizam e batem com o resumo; respostas calculadas corretas para pessoa_a × pessoa_b; pacote de aula ida e volta; glossário pt/en com os mesmos termos); verificação no emulador e no navegador.

**Status:** concluído em 01/10/2026. Verificado no emulador Android (API 35, APK de release) e no Edge (site, servidor sem cabeçalhos como o GitHub Pages):
- Aprender → "O genoma inteiro no mapa" → Abrir Mapa: o app importa o dataset sintético embutido, compara SINT_1 × SINT_2 e abre o ideograma (22 cromossomos em escala, densidade, centrômero); mesmos números no Android e no navegador;
- visualizador de região: faixas por categoria com cor e forma, zoom, régua em Mb; ficha da variante ao tocar (Web);
- exercício "cromossomo com mais variantes só em A": resposta errada → explicação → "Ver resposta: 9"; conferido com `genoz-cli density --category only_a` (cromossomo 9, 29 variantes);
- professor: "Criar pacote de aula" → `.genozaula` salvo pelo seletor do sistema (73,5 KB: `aula.json` + o VCF, SHA-256 igual ao original, sem respostas) → Aprender → Importar → aula aberta e resposta 428 calculada no aparelho do "aluno"; cache do seletor limpo;
- Resumo: diagrama de interseções com legenda; nenhuma requisição externa no site.

Achados corrigidos no caminho: tabela de comprimentos do núcleo só tinha 8 cromossomos (completada; MT não conta como evidência de build); régua do visualizador com rótulos sobrepostos e marcadores cortados nas pontas; textos do diagrama apertados dentro dos círculos (viraram legenda); dicas dos campos de resposta pareciam respostas ("0", "83.3"); aula importada sem instruções não tinha botão para abrir a comparação; o "▾" da legenda não existe nas fontes embutidas (no navegador virava um quadrado); `rootBundle.loadString` com cache prendia o carregamento entre testes.
92 testes Dart + Rust (densidade, ponte memória = arquivo). Decisões em [ADR-014](../adr/ADR-014-modo-estudante-e-pacote-de-aula.md).
Limitações: perguntas de múltipla escolha levam a alternativa certa no pacote (visível para quem abrir o ZIP); o professor escolhe entre perguntas prontas (calculadas) — perguntas livres ficam para depois.

---

## Contrato do Módulo 9 — Arquivos de consumidor e multiamostra (antes de implementar)

**Entradas:** arquivos brutos de testes de consumidor (23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA); VCFs com várias amostras; opcionalmente um FASTA de referência local.

**Saídas — núcleo (`genoz_core`), CLI e ponte:**
- `consumer`: detecção do formato pelo conteúdo (não pela extensão) e leitura linha a linha → chamadas de chip (`rsid`, cromossomo canônico, posição, alelos em letras; sem chamada = `--`/`0`; inserções/deleções `I`/`D` contadas e ignoradas); cromossomos 23/24/25/26 da AncestryDNA = X/Y/X(PAR)/MT; relatório de inspeção próprio (fornecedor, build declarado ou presumido, sítios, chamados, sem chamada, het/hom/haploides, por cromossomo, problemas com número da linha, veredito);
- `chip_compare`: **comparação chip × sequenciamento restrita aos sítios do chip** (A = chip, B = VCF de uma amostra escolhida). Para cada sítio do chip: genótipos comparados como **conjunto de letras** (ordem e fase não importam; multialélicos divididos são recombinados); VCF sem registro só vira "referência" se houver bloco de referência (gVCF) ou região avaliada (BED) — senão o sítio fica "só no chip" (se o chip mostra variante) ou fora da conta (ADR-010). Sem FASTA a base de referência de um sítio sem registro no VCF é desconhecida: homozigotos do chip nesses sítios não são julgados (contados à parte). Possível troca de fita (alelos complementares, não palindrômicos) é sinalizada. Variantes do VCF fora do chip não viram linhas (só contagem). Mesmo formato de resultado (`rows.bgz`, resumo, manifesto), então tabela, mapa, exportação e aulas funcionam;
- `fasta`: leitura de FASTA de referência local com índice `.fai` (lido ou criado), busca de trechos; **normalização completa** (alinhamento à esquerda + aparo) de indels; conferência do REF do VCF contra o FASTA (REF diferente = build errado → aviso). Na comparação, opção "normalizar com FASTA" (o SHA-256 do FASTA entra no manifesto) e, no chip × VCF, o FASTA permite julgar os homozigotos sem registro no VCF;
- **multiamostra:** escolher a amostra de A e de B (já existe) também no chip × VCF; relatório mostra contagens por amostra.

**App:** importar arquivos de consumidor pelo mesmo botão (o app reconhece sozinho); relatório próprio; "Comparar chip × sequenciamento" com escolha da amostra do VCF; FASTA importável como "referência" do projeto (aviso de tamanho; no navegador vale o limite de 400 MB, então só FASTA por cromossomo).

**Invariantes:** nada de imputação nem de "adivinhar" referência; build do chip presumido GRCh37 só com aviso (os quatro fornecedores publicam em GRCh37) e comparação com VCF GRCh38 recusada (sem liftover local); todos os números do resumo vêm das linhas; dados de consumidor tratados como dados genômicos (nunca saem do aparelho); nada é diagnóstico.

**Erros:** arquivo de consumidor truncado ou com colunas trocadas (problemas por linha, veredito parcial/inválido); build GRCh36 (recusado com explicação); FASTA sem o cromossomo pedido; FASTA que não confere com o VCF.

**Testes:** fixtures fictícias dos quatro formatos (detecção, cromossomos 23–26, sem chamada, indels, haploides, build); chip × VCF com casos de cada categoria (incluindo multialélico, fase, troca de fita, bloco gVCF, sem registro); FASTA (índice criado = `samtools faidx`, busca, alinhamento à esquerda com casos de repetição); ponte por caminho = por memória; app: importação e relatório do chip, tela de comparação chip × VCF.

**Status:** concluído em 01/10/2026. Verificado no emulador Android (API 35, APK de release), com dados fictícios (`test_fixtures/consumidor/`, gerados por `gerar.py`):
- importar o `.zip` do 23andMe pelo seletor do sistema → o app abre o zip e reconhece "chip 23andMe · GRCh37 · 14 sítios"; o VCF GRCh37 e o FASTA ("FASTA de referência", build desconhecido por ser um trecho) também;
- tela de comparação: o chip vai sozinho para A, B só oferece VCF, "verdade" some, aparece o seletor de referência;
- chip × VCF com FASTA: 6 compartilhadas, 3 genótipo diferente, 1 só no chip, 1 incerta, 1 homozigoto de referência sem registro no VCF — os mesmos números do `genoz-cli compare-chip --fasta`; tabela com genótipos em letras dos dois lados.
- os quatro formatos (23andMe, AncestryDNA, MyHeritage, FamilyTreeDNA) da mesma pessoa dão exatamente as mesmas linhas (teste no núcleo); ponte em memória (Web) dá o mesmo ID de análise da CLI, com e sem FASTA (teste na ponte).

Achados corrigidos no caminho: `ZipDecoder` aceita qualquer lixo como ZIP vazio (agora confere a assinatura PK); fixtures geradas em Windows saíam com CRLF (gerador força LF); `.fai` do FASTA ficava órfão ao apagar o arquivo.
Núcleo: 73 testes (+ 32 de CLI/integração); ponte: 3; app: 100. Decisões em [ADR-015](../adr/ADR-015-chip-x-sequenciamento-e-fasta.md).
Limitações: chips de indel ignorados; sem liftover (chip GRCh37 × VCF GRCh38 é recusado); normalização VCF × VCF com FASTA carrega os dois VCFs em memória; exportações grandes ainda passam pela memória do Dart (fica para depois).

---

## Contrato do Módulo 10 — Anotação local (antes de implementar)

**Entradas:** resultados de comparação (linhas com cromossomo/posição/REF/ALT); arquivos de anotação: GENCODE (genes), ClinVar (VCF mensal oficial do NCBI), BED/TSV do usuário.

**Licenças verificadas (01/10/2026):** GENCODE — acesso aberto, EMBL-EBI não impõe restrições e pede atribuição; ClinVar — redistribuição livre com atribuição (PMID 29165669), e aviso de que não é para uso diagnóstico direto. **Ficam fora deste módulo:** dbSNP completo (~25 GB) e gnomAD (dezenas de GB, licença ODbL com compartilhamento pela mesma licença) — exigem hospedar subconjuntos (ação pública, só com o "sim" do usuário). rsIDs já vêm nos VCFs, nos chips e no próprio ClinVar.

**Decisão de rede ("online controlado"):** o app **continua sem permissão de internet**. Um item do catálogo mostra URL, tamanho, licença e SHA-256 esperado; o botão abre o navegador do sistema; o usuário baixa e importa o arquivo; o app confere o SHA-256 antes de usar. Nada é enviado; o arquivo nunca é baixado sem o usuário.

**Saídas — núcleo, CLI e ponte:**
- formato de **pacote de anotação** próprio, compacto e indexado: `manifest.json` (id, nome, tipo `sites` ou `intervals`, build, fonte, URL, versão, data, licença, citação, campos, SHA-256 da entrada e dos dados), `records.bgz` (registros ordenados em BGZF) e `records.idx` (blocos com faixa de posições e deslocamento virtual) + índice de nomes (genes);
- construtores: GTF (genes), VCF (ClinVar: significado clínico, status de revisão, condição, gene, rsID), BED/TSV do usuário;
- consultas: por região (sobreposição), por sítio (posição + REF/ALT), por nome de gene; anotação de uma página de linhas de resultado;
- CLI: `anot build|info|query|gene`.

**App:**
- tela **Anotações** (menu ☰): pacotes instalados com fonte, versão, data, licença e citação; catálogo (ClinVar GRCh38/GRCh37 do mês, com URL/tamanho/SHA-256); importar BED/TSV próprio; remover pacote;
- **genes GENCODE v50 embutidos** (GRCh38 e GRCh37), já instalados — busca por gene funciona sem nada baixar;
- **tabela:** gene e o que o ClinVar diz em cada linha (quando houver pacote do mesmo build); **busca por gene** na caixa de busca (ex.: `BRCA2`) vira filtro de região;
- **ficha da variante:** seção "O que as fontes dizem", com fonte + versão + data e o aviso de que o Genoz não classifica variantes.

**Invariantes:** pacote só é usado com análise do mesmo build; anotação nunca muda categoria nem contagem de comparação; textos clínicos sempre atribuídos à fonte ("o ClinVar, versão X, diz…"), nunca como conclusão do Genoz; nada é diagnóstico; APK sem INTERNET (o CI confere); "Apagar todos os dados" remove os pacotes baixados (os embutidos voltam a ser instalados).

**Erros:** arquivo importado com SHA-256 diferente do catálogo (recusado, nada instalado); build do pacote diferente da análise (pacote ignorado com aviso); BED/TSV malformado (problemas por linha); pacote de versão futura.

**Testes:** núcleo (construtores com fixtures pequenas de GTF/VCF/BED; consulta por região e sítio = busca linear; índice com muitos blocos; nome de gene); CLI; ponte caminho = memória; app (tela de anotações, catálogo com hash errado recusado, coluna/ficha na tabela, busca por gene); verificação no emulador e no navegador com o ClinVar real do mês.

**Status:** concluído em 01/10/2026. Verificado no emulador Android (API 35, APK de release, sem permissão INTERNET):
genes GENCODE v50 GRCh38 (78.733) e GRCh37 (80.315, lift37 oficial) embutidos e instalados sozinhos (1,5 MB cada);
"Baixar no navegador" abre o Chrome; arquivo errado importado para o ClinVar GRCh37 → recusado (SHA-256 diferente),
nada instalado; ClinVar 2026-09-05 GRCh38 real (193 MB) importado e conferido → pacote com 4.467.926 registros em
~70 s; dois VCFs fictícios com sítios reais do ClinVar → tabela com "BRCA2 · ClinVar: Pathogenic/Benign" e "CFTR";
ficha da variante com GENCODE e ClinVar (fonte, versão, data, campos e aviso do ClinVar); busca `cftr` → só a linha
do gene; atualizar o app manteve o ClinVar instalado e acrescentou o pacote GRCh37. Licença e aviso das fontes
conhecidas aparecem no idioma do app. 106 testes Dart, 111 Rust (núcleo e CLI) + 4 da ponte. Decisões em
[ADR-016](../adr/ADR-016-anotacao-local-e-online-controlado.md). No navegador, o mesmo código roda com os pacotes no
OPFS (`annot_load`); a verificação manual no site ficou para o Módulo 11 (o CI compila a versão Web).

## Contrato do Módulo 11 — Relatórios, reprodutibilidade e criptografia (antes de implementar)

**Entradas:** resultados de comparação (summary.json, stats_a/b.json, manifest.json, rows); projetos do app (banco + arquivos); senha digitada pelo usuário.

**Saídas — núcleo e CLI:**
- **Relatório HTML autocontido** (um arquivo, sem script, sem fonte ou imagem externa; abre offline em qualquer navegador): projeto, amostras, contagens por categoria com gráfico (SVG embutido), concordância/Jaccard/benchmark, por cromossomo, QC lado a lado (Ti/Tv, het/hom, missing, histogramas), parâmetros, manifesto (entradas e saídas com SHA-256) e o aviso "uso educacional e de pesquisa — não é diagnóstico". Português ou inglês. Mesma entrada → mesmos bytes (a data de geração vem de quem chama).
- **Relatório PDF** com o mesmo conteúdo, gerado pelo próprio núcleo (escritor de PDF mínimo, fontes padrão do PDF, sem dependência externa), determinístico.
- **Verificação de reprodutibilidade:** `verify` confere os SHA-256 das saídas de uma pasta de resultado contra o manifesto; `rerun` confere as entradas (SHA-256), refaz a análise com os parâmetros do manifesto e compara saída por saída.
- **Cofre `.genoz`** (ADR-017): pacote do projeto (projeto.json + arquivos + resultados) cifrado com senha — Argon2id (64 MiB, 3 passadas) → XChaCha20-Poly1305 em segmentos de 64 KiB (desenho de segmentos do GA4GH crypt4gh, com índice e marca de fim autenticados: reordenar ou truncar é detectado). Leitura e escrita em fluxo (arquivos de vários GB não passam inteiros pela memória no celular/PC). O núcleo não sorteia nada: sal e nonce vêm de quem chama (gerador seguro do sistema).
- CLI: `report`, `verify`, `rerun`, `unpack` (abre um `.genoz` no PC com a senha).

**App:**
- análise → **Relatório HTML** e **Relatório PDF** (salvar como / download);
- análise → **Verificar reprodutibilidade**: confere os SHA-256 das entradas, refaz a análise numa pasta temporária e mostra "N de N saídas idênticas" ou quais diferem;
- projeto → **Exportar projeto (.genoz)** com senha; Projetos → **Importar .genoz** (vira projeto novo, IDs novos; IDs de análise, que vêm do conteúdo, continuam iguais);
- projeto → **Proteger com senha**: o projeto vira um cofre `.genoz` no armazenamento do app e os dados em claro são apagados; na lista ele aparece com cadeado (só o nome); **Abrir** pede a senha e restaura; **Trancar de novo** volta a cifrar;
- aviso claro e repetido: **senha perdida = dados irrecuperáveis** (não há "esqueci a senha");
- Android: salvar arquivos grandes copiando em fluxo para o destino escolhido (sem carregar tudo na memória) — resolve também a pendência das exportações grandes.

**Invariantes:** nada sai do aparelho; senha nunca é gravada (nem em log); texto em claro nunca é gravado em disco fora da área do app; relatório não muda o resultado nem o ID; reexecução usa pasta temporária e não altera a análise; "Apagar tudo" apaga os cofres; banco migra para v3 sem perder dados.

**Erros:** senha errada ou arquivo corrompido/truncado (mensagem única, nada importado); `.genoz` de versão futura; entrada da reexecução ausente ou com SHA-256 diferente; espaço insuficiente (importação desfeita).

**Testes:** núcleo (relatório determinístico e com os números do resumo; PDF válido com xref correto; cofre ida e volta, senha errada, segmento trocado, truncado, tamanho múltiplo exato de 64 KiB, vazio; pacote; verify/rerun detectam saída alterada); CLI; ponte; app (relatórios, verificação, exportar/importar, proteger/abrir, migração v3); emulador e navegador (incluindo a anotação, pendente do Módulo 10).

**Status:** concluído em 02/10/2026. Verificado no emulador Android (API 35, APK de release, sem INTERNET) e no Edge (site com isolamento de origem):
- **Android:**
  - atualizar o app migrou o banco v2 → v3 com os dados;
  - "Verificar reprodutibilidade" deu mesmo ID e 5 de 5 saídas idênticas;
  - relatório PDF salvo em Downloads; o mesmo ID (`7091d2bc…`) e os mesmos SHA-256 saem no PC;
  - exportar `.genoz` com senha (salvo em fluxo); o arquivo abre no PC com `genoz-cli unpack`, e com a senha errada nada é extraído;
  - proteger o projeto deixa só o cofre; um `grep` no banco achou 0 vestígios do conteúdo depois do `VACUUM` (sem ele, achava 3, falha corrigida);
  - senha errada é recusada; a certa restaura arquivos e análise;
  - importar o `.genoz` cria um projeto novo que também se reproduz.
- **Navegador:**
  - o `.genoz` feito no Android abre (senha errada recusada);
  - a análise do Android reexecutada no navegador deu 5 de 5 saídas idênticas;
  - genes GENCODE e ClinVar (193 MB, 4.467.926 registros, instalado no navegador) aparecem na tabela, o que fecha a pendência do Módulo 10;
  - 96 requisições, todas para `127.0.0.1` ou `blob:`.

Testes: 113 Dart, 126 Rust (núcleo e CLI) + 6 da ponte. Decisões em [ADR-017](../adr/ADR-017-relatorios-reexecucao-e-cofre-genoz.md).


## Contrato do Módulo 12 — Família e populações (antes de implementar)

**Entrada:** um VCF **multiamostra com chamada conjunta** (2 a 32 amostras escolhidas), o formato de trios e coortes (ex.: 1000 Genomes). Motivo (ADR-010): parentesco, ROH e herança precisam saber quem é homozigoto de referência; em VCFs de uma pessoa só, ausência não é referência — para esses, a comparação A × B continua sendo o caminho, e o app explica por quê. Portão de qualidade igual ao da comparação (chamada reprovada = ausente). Só autossomos e SNVs bialélicos (multialélicos divididos ficam de fora do parentesco e do ROH; X/Y ficam de fora por não sabermos o sexo — explicado).

**Saídas — núcleo e CLI (`genoz-cli family`), numa só passada, memória proporcional a N²:**
- **Parentesco KING-robust** (Manichaikul et al., 2010, eq. 9) para cada par: φ = (N_Aa,Aa − 2·N_AA,aa) / (N_Aa(i) + N_Aa(j)), só SNPs com genótipo nos dois; IBS0 (N_AA,aa) e sua proporção; concordância de genótipos; M (SNPs usados). Classes pela Tabela 1 do artigo (potências de 2): > 2^-1,5 mesma pessoa/gêmeos idênticos; 2^-2,5 a 2^-1,5 1º grau; 2^-3,5 a 2^-2,5 2º grau; 2^-4,5 a 2^-3,5 3º grau; abaixo, sem parentesco próximo. Pai/mãe–filho × irmãos (dentro do 1º grau): π̂0 pela eq. 2 com as frequências da própria amostra (≥ 3 amostras) — grosseiro com poucas pessoas, mas a diferença é grande (≈ 0 × ≈ 1/4); com 2 amostras, "1º grau" + IBS0 explicado. O IBS0 bruto é sempre mostrado.
- **Matriz N × N** (parentesco e concordância) e **interseções estilo UpSet** (quais amostras carregam cada variante; as combinações mais frequentes).
- **Runs of homozygosity** por amostra (algoritmo simplificado inspirado no `plink --homozyg`: ≥ 1000 kb, ≥ 100 SNPs, ≤ 1 heterozigoto e ≤ 5 ausentes por trecho, lacuna ≤ 1000 kb, densidade ≥ 1 SNP/50 kb): trechos, total em Mb e F_ROH. Texto educativo, nunca clínico.
- **Trio** (filho(a), pai, mãe escolhidos): sítios com os três genotipados; consistência mendeliana; **candidatas a de novo** (filho(a) portador(a), pais 0/0); outros erros mendelianos; alelos atribuíveis ao pai ou à mãe (sítios informativos); lista de eventos com genótipos e QUAL/DP/GQ (limitada, com contagens completas).
- Resultado em `familia.json` + manifesto (ID pelo conteúdo, reexecutável). Dados fictícios: `synth --family` gera uma família (pai, mãe, dois filhos, uma pessoa sem parentesco e uma duplicata) com de novo e um trecho de ROH plantados — valores esperados conhecidos.

**App:** no projeto, **Família e populações** para um VCF com 2+ amostras: escolher amostras e, opcionalmente, o trio → tela com abas **Parentesco** (pares + matriz), **ROH**, **Trio**, **Interseções**; análises salvas no banco (v4), incluídas no cofre `.genoz`; reprodutibilidade verificável; aviso obrigatório: estimativa estatística, sujeita a erro, **não é teste de paternidade com valor legal** e não é diagnóstico.

**Invariantes:** ausência nunca vira referência; mesmo arquivo + mesmas escolhas = mesmo resultado byte a byte; nada sai do aparelho.

**Erros:** VCF com menos de 2 amostras; mais de 32 amostras escolhidas; trio com amostra repetida; poucos SNPs utilizáveis (aviso: estimativa instável abaixo de ~1000).

**Testes:** fórmula KING em casos calculados à mão; família sintética (φ ≈ 0,25 pai/mãe–filho e irmãos, ≈ 0,5 duplicata, ≈ 0 sem parentesco; de novo plantadas encontradas; ROH plantado encontrado); bordas do ROH; trio com erro mendeliano; determinismo; ponte caminho = memória; app (tela, salvar, cofre, migração v4); emulador e navegador.

**Status:** concluído em 02/10/2026. Verificado no emulador Android (API 35, APK de release) e no Edge (site com isolamento de origem):
- **Android:**
  - a atualização migrou o banco v3 → v4 com os projetos protegidos intactos;
  - "Gerar família fictícia" → 7 amostras, 9.781 variantes;
  - Família e populações com trio FILHO/PAI/MAE → matriz com duplicata 0,50, pai/mãe–filho e irmãos 0,25, avô–neto 0,12–0,13 e o vizinho ≈ 0;
  - pares classificados como mesma pessoa, pai/mãe–filho, irmãos, 2º grau e sem parentesco;
  - ROH: 12,0 Mb no VIZINHO (F_ROH 0,074), nada nos outros;
  - trio: 9.706 sítios, 3 candidatas a de novo, 1 erro mendeliano, 1.760 alelos do pai e 1.764 da mãe;
  - "Verificar reprodutibilidade" deu 1 de 1 idêntica.
- **Navegador:** os mesmos números nas abas Parentesco, Trio e Interseções; reprodutibilidade 1 de 1; 85 requisições, todas para `127.0.0.1` ou `blob:`.
- **CLI:** `family` e `rerun` de família (1 de 1 idêntica).
- **Mudança em relação ao contrato:** o π̂0 separa pai/mãe–filho de irmãos já a partir de 3 amostras (ver ADR-018).

Testes: 118 Dart, 134 Rust (núcleo e CLI) + 7 da ponte. Decisões em [ADR-018](../adr/ADR-018-familia-e-populacoes.md).


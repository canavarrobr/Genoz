# Genoz

Plataforma genômica **local-first** para ensino e pesquisa — Web, Android e iOS.
Os dados genômicos são processados no próprio dispositivo; nada é enviado a servidores.

> Uso educacional e de pesquisa. **Não é ferramenta de diagnóstico.**

- Stack: Flutter/Dart (UI) · Rust (núcleo bioinformático) · WebAssembly (navegador)
- Especificação: [docs/especificacao/Genoz_especificacao_tecnica_v4.md](docs/especificacao/Genoz_especificacao_tecnica_v4.md)
- Plano de módulos até a 1.0 (APK + site): [docs/modulos/PLANO_DE_MODULOS.md](docs/modulos/PLANO_DE_MODULOS.md)
- Decisões de arquitetura: [docs/adr/](docs/adr/)
- Guia de estilo (cores, logo, ícone): [docs/estilo/GUIA_DE_ESTILO.md](docs/estilo/GUIA_DE_ESTILO.md)
- Referências oficiais (VCF, BGZF, tabix, crypt4gh etc.): [docs/referencias/](docs/referencias/)

## Status

| Módulo | Situação |
|---|---|
| 1 — Núcleo Rust: leitura de VCF | concluído |
| 2 — Comparação, filtros e QC | concluído |
| 3 — App Flutter + ponte + persistência | concluído |
| 4 — Telas de análise (comparação, tabela, filtros, QC, exportação) | concluído |
| 5 — Estética e identidade visual | concluído |
| 6 — Web local-first (site de prévia) | concluído |
| 7 — Android completo (APK de prévia) | concluído |
| 8 — Visualização e modo estudante | concluído |
| 9 — Arquivos de consumidor e multiamostra | concluído |
| 10 — Anotação local | concluído |
| 11 — Relatórios, reprodutibilidade e criptografia | concluído |
| 12 — Família e populações | próximo |

## Preparar o computador (Windows)

No PowerShell, dentro da pasta `Genoz`:

```powershell
.\tools\setup.ps1    # instala o que faltar (Rust, MinGW) — sem administrador
.\tools\doctor.ps1   # confere se está tudo pronto
```

## Experimentar o núcleo (Módulo 1)

```powershell
cd rust
cargo test --workspace                                   # roda todos os testes
cargo run --release -p genoz_cli -- synth --out demo.vcf.gz --samples 3
cargo run --release -p genoz_cli -- inspect demo.vcf.gz
cargo run --release -p genoz_cli -- inspect ..\test_fixtures\vcf\invalid_records.vcf
```

Comparação A × B (Módulo 2):

```powershell
cargo run --release -p genoz_cli -- compare ..\test_fixtures\compare\pessoa_a.vcf ..\test_fixtures\compare\pessoa_b.vcf --out resultado --bed-b ..\test_fixtures\compare\pessoa_b_chamavel.bed
cargo run --release -p genoz_cli -- view resultado --category only_a,only_b
cargo run --release -p genoz_cli -- stats ..\test_fixtures\vcf\valid_small_grch38_chr.vcf
```

A pasta `resultado` recebe `rows.bgz` + `rows.idx` (tabela paginável), `summary.json`, `stats_a.json`, `stats_b.json` e `manifest.json` (reprodutibilidade).

`inspect` mostra: validade, SHA-256, compressão, build (GRCh37/38), estilo dos cromossomos, contagens por tipo e cromossomo, genótipos por amostra e cada problema com o número da linha.

## Rodar o app (Módulo 3)

Com o emulador Android aberto (ou um celular com depuração USB), no PowerShell:

```powershell
cd app
flutter run
```

Na primeira vez a compilação demora alguns minutos, porque o núcleo Rust é compilado para Android.
No app: **Novo projeto → Gerar exemplo sintético** (ou **Importar VCF**) → toque no arquivo para ver o relatório.

## Relatórios, reprodutibilidade e projetos cifrados (Módulo 11)

Numa análise, o botão de exportar também gera o **relatório HTML** (um arquivo que abre offline em qualquer
navegador) e o **relatório PDF**, e oferece **Verificar reprodutibilidade**: o app confere os SHA-256 dos arquivos,
refaz a análise numa pasta temporária e compara cada saída com o manifesto.
No menu ⋮ de um projeto: **Exportar projeto (.genoz)** — um arquivo cifrado com senha (Argon2id +
XChaCha20-Poly1305) para levar a outro aparelho sem nuvem — e **Proteger com senha**, que cifra o projeto no
próprio aparelho. **Senha perdida = dados perdidos.** Pela linha de comando:

```powershell
genoz-cli report resultado --out relatorio.pdf --lang pt
genoz-cli verify resultado
genoz-cli rerun resultado --a pessoa_a.vcf --b pessoa_b.vcf
genoz-cli unpack projeto.genoz --out pasta   # senha pedida no terminal ou em GENOZ_SENHA
```

## Anotação local (Módulo 10)

Menu ☰ → **Anotações**. Os genes do **GENCODE v50** (GRCh38 e GRCh37) já vêm no app: na tabela de uma análise,
cada linha mostra o gene, e a busca aceita o nome do gene (ex.: `BRCA2`). O **ClinVar** do mês está no catálogo:
o app **não tem permissão de internet**, então o botão abre o navegador para baixar o arquivo oficial do NCBI;
depois é só importá-lo — o app confere o SHA-256 antes de aceitar. Na ficha da variante, "O que as fontes dizem"
mostra o que o ClinVar registra, sempre com fonte, versão e data (o Genoz não classifica variantes).
Também dá para importar um BED/TSV próprio. Pela linha de comando:

```powershell
genoz-cli anot build --from clinvar clinvar_20260905.vcf.gz --out clinvar38 --id clinvar38 --name ClinVar --build GRCh38 --version 20260905 --date 2026-09-05
genoz-cli anot query clinvar38 13:32315086-32400268
```

## Arquivos de testes de consumidor (Módulo 9)

O botão **Importar** também aceita os arquivos brutos da 23andMe, AncestryDNA, MyHeritage e FamilyTreeDNA
(inclusive o `.zip` que elas enviam) e um FASTA de referência. Com um chip e um VCF da mesma pessoa no projeto,
**Comparar A × B** faz a comparação chip × sequenciamento, só nos sítios que o chip mede. Pela linha de comando:

```powershell
genoz-cli compare-chip chip.txt sequenciamento.vcf --out resultado --fasta referencia.fa
```

Arquivos fictícios para testar ficam em `test_fixtures/consumidor/`.

## Aprender (Módulo 8)

Menu ☰ → **Aprender**: trilhas guiadas com dados fictícios embutidos (comparar duas pessoas, ler genótipos,
o genoma inteiro no mapa), exercícios corrigidos na hora e um glossário em português e inglês.
Professores: numa análise, o botão **Criar pacote de aula** gera um arquivo `.genozaula` (os VCFs + as perguntas);
os alunos o importam em Aprender e recebem a mesma comparação pronta. As respostas são calculadas no aparelho
de cada aluno — o pacote não leva gabarito.

Toda análise ganhou a aba **Mapa** (cromossomos em escala com a densidade de variantes; toque num cromossomo
para ver as variantes de perto) e o **diagrama de interseções** no Resumo.

## Instalar no celular Android (Módulo 7)

O GitHub Actions gera o APK a cada mudança (workflow **APK Android e iOS** → artefato `genoz-apk`).
Para compilar no próprio computador, no PowerShell, dentro de `Genoz\app`:

```powershell
flutter build apk --release --split-per-abi
```

O arquivo `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` serve para a maioria dos celulares.
Os APKs publicados no GitHub são assinados com a chave do Genoz; confira com
`apksigner verify --print-certs genoz-*.apk` — o certificado (SHA-256) tem que ser
`ca196046beec1037e3b7810dfece15cfb3b1791f7a3409b4c679d4d15f6f1367`.
O app **não pede permissão de internet** nem de acesso aos arquivos: o seletor do sistema entrega só o arquivo
escolhido. Em **Ajustes** (menu ☰): tema, idioma, bloqueio por PIN/digital, proteção de tela e "Apagar todos os dados".

## Rodar o site (Módulo 6)

No PowerShell, dentro da pasta `Genoz`:

```powershell
.\tools\web.ps1
```

Depois abra http://127.0.0.1:8765/ no Chrome ou Edge. Tudo roda no navegador: os arquivos ficam
no armazenamento privado do navegador (OPFS), nada é enviado, e depois da primeira visita o site
funciona sem internet. A tela **Verificar privacidade** (menu ☰) mostra cada requisição feita.

## Estrutura

```
rust/genoz_core   núcleo científico (compartilhado por Web, Android e iOS)
rust/genoz_cli    ferramenta de linha de comando para desenvolvimento
app/              app Flutter (Android, iOS, Web)
app/rust          ponte Flutter ↔ núcleo (flutter_rust_bridge), sem lógica científica
test_fixtures/    VCFs de teste (fictícios)
tools/            scripts de ambiente
docs/             especificação, módulos, ADRs, referências
```

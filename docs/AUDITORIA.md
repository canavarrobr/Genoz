# Auditoria de dependências e de privacidade (Módulo 13)

**Data:** 02/10/2026 · versão 1.0.0. Os itens marcados "CI" são conferidos automaticamente a cada mudança.

## 1. Vulnerabilidades conhecidas (RustSec)

| Projeto | Dependências | Resultado |
|---|---|---|
| Núcleo + CLI (`rust/`) | 95 crates | **0 alertas** |
| Ponte do app (`app/rust/`) | 114 crates | **0 alertas** (depois de `cargo update`) |

Antes da atualização, a ponte tinha 4 avisos, nenhum de vulnerabilidade, todos em versões antigas presas no
`Cargo.lock`:
- `anyhow` 1.0.75 e `tokio` 1.34: "unsound";
- `futures-util` 0.3.29: versão retirada (yanked);
- `adler`: sem manutenção.

A atualização dentro de versões compatíveis resolveu os quatro. Testes, clippy, wasm e o build Web foram refeitos.

**CI:** o job `auditoria de dependências (RustSec)` roda `cargo audit --deny warnings` nos dois projetos a cada
mudança e **toda segunda-feira** (alertas novos aparecem sem mudança no código).

Dart: não existe um banco de alertas equivalente. As dependências de produção são poucas e conhecidas (lista na
seção 2) e estão nas versões atuais compatíveis (`flutter pub outdated`).

## 2. Licenças

`tools/licencas.py` gera [LICENCAS_DE_TERCEIROS.md](LICENCAS_DE_TERCEIROS.md): 84 crates Rust (o que entra no
binário Android) e 149 pacotes Dart de produção.
- **Nenhuma licença copyleft forte (GPL/AGPL).** São MIT, BSD, Apache-2.0, Zlib, Unicode e semelhantes.
- **Única exceção fraca:** `dbus` (MPL-2.0, copyleft por arquivo). Entra só pelo `file_picker_linux`, isto é, apenas
  no app de desktop Linux, nem no Android nem na Web. Não é modificado, então a MPL é cumprida com o aviso de
  licença.
- As licenças completas aparecem no app em **Sobre → Licenças**: as do Flutter e dos pacotes Dart, mais as fontes
  Inter e Poppins (OFL).
- Dados de anotação têm a licença no manifesto de cada pacote (GENCODE: acesso aberto; ClinVar: livre com
  atribuição).

## 3. Privacidade — checklist com evidências

| Promessa | Como é garantida | Evidência |
|---|---|---|
| O app Android não acessa a internet | Sem a permissão `INTERNET` (o sistema bloqueia qualquer socket). Única permissão: biometria opcional. | CI ("Permissões do APK"); `dumpsys package` no emulador |
| O site não envia nada | CSP `connect-src 'self' blob:`, `form-action 'none'`, sem CDN (fontes e CanvasKit locais) | `app/web/index.html`; teste no Edge: 85–96 requisições, todas para a própria origem ou `blob:` |
| Nenhuma biblioteca de rede/telemetria em uso | Sem Firebase, Sentry, analytics. `http` vem do `flutter_svg` (só em `SvgPicture.network`, que o app não usa — só `SvgPicture.asset`); `web_socket` vem de ferramentas de build | `docs/LICENCAS_DE_TERCEIROS.md`; busca no código |
| Verificável pelo usuário | Tela **Verificar privacidade**: conta conexões durante uma análise (0 esperado) | Módulos 6 e 7 |
| Dados de anotação baixados sob controle | O próprio usuário baixa no navegador do sistema; o app aceita só com SHA-256 igual ao do catálogo | ADR-016; teste com arquivo errado recusado |
| Nada de genótipo em logs | Nenhum `print`/`debugPrint` no app; o núcleo e a ponte não escrevem no console (só a CLI, que é local) | busca no código (`print(`, `println!`) |
| Projetos protegidos de verdade | Cofre Argon2id + XChaCha20-Poly1305; ao proteger, linhas apagadas + `VACUUM` (0 vestígios no banco) | ADR-017; teste com `freelist_count`; `grep` no banco do emulador |
| Apagar tudo apaga tudo | Banco (com `VACUUM`), projetos, cofres, temporários, anotações baixadas, progresso, ajustes e PIN | `wipe.dart`; teste de ajustes |
| Capturas de tela bloqueáveis | `FLAG_SECURE` opcional (Android) | Módulo 7 |
| Não é diagnóstico | Aviso em todas as telas de resultado, relatórios, família e anotação; o app não classifica variantes | revisão das telas |

## 4. Limites honestos

- Enquanto um projeto protegido está **aberto**, os dados ficam em claro na área privada do app (como os demais
  projetos). A proteção vale quando ele está trancado.
- No navegador, os dados ficam no armazenamento do site (OPFS), que o navegador pode apagar se faltar espaço. O app
  pede armazenamento persistente (`navigator.storage.persist()`, API local) e mostra nos Ajustes se foi concedido,
  sugerindo exportar um `.genoz` como cópia.
- O núcleo responde em português mesmo com o app em inglês. As mensagens de erro técnicas não são traduzidas.

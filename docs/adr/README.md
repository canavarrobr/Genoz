# Decisões de arquitetura (ADRs)

ADR-001 a ADR-006 estão resumidas na [especificação v4, seção 3.1](../especificacao/Genoz_especificacao_tecnica_v4.md).
As decisões tomadas durante o desenvolvimento ficam registradas aqui, uma por arquivo.

| ADR | Título | Módulo |
|---|---|---|
| [ADR-007](ADR-007-toolchain-rust-windows.md) | Toolchain Rust GNU + MinGW em `C:\mingw64` no Windows | 1 |
| [ADR-008](ADR-008-nucleo-sobre-read.md) | Núcleo trabalha sobre `Read`, não sobre caminhos | 1 |
| [ADR-009](ADR-009-divisao-multialelicos.md) | Convenção de divisão de multialélicos | 1 |
| [ADR-010](ADR-010-ausencia-nao-e-referencia.md) | Ausência de registro não é genótipo de referência | 2 |
| [ADR-011](ADR-011-fontes-e-marca.md) | Fontes embutidas e marca gerada por script | 5 |
| [ADR-012](ADR-012-web-isolamento-por-service-worker.md) | Web: isolamento de origem por service worker, arquivos no OPFS | 6 |
| [ADR-013](ADR-013-bloqueio-do-app.md) | Bloqueio do app por PIN/biometria (não é criptografia) | 7 |
| [ADR-014](ADR-014-modo-estudante-e-pacote-de-aula.md) | Modo estudante: respostas calculadas e pacote de aula | 8 |
| [ADR-015](ADR-015-chip-x-sequenciamento-e-fasta.md) | Chip × sequenciamento por letras; FASTA local para normalizar | 9 |
| [ADR-016](ADR-016-anotacao-local-e-online-controlado.md) | Anotação local em pacotes próprios; "online controlado" sem internet | 10 |

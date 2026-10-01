# ADR-013 — Bloqueio do app por PIN/biometria (não é criptografia)

**Status:** aceito · **Módulo:** 7 · **Data:** 01/10/2026

## Contexto

Dados genômicos ficam no aparelho. Quem pega o celular desbloqueado não deveria
conseguir abrir o Genoz. Criptografar os arquivos é outro problema (gestão de
chaves, desempenho em arquivos de centenas de MB) e está no Módulo 11.

## Decisão

1. **PIN de 4–8 dígitos**, guardado só como **PBKDF2-HMAC-SHA256** (20 000 iterações,
   sal aleatório de 16 bytes, comparação em tempo constante) no arquivo de ajustes
   (`ajustes.json`, armazenamento privado do app; excluído de backup).
   20 000 iterações cabem no navegador (dart2js) sem travar a tela.
2. **Espera crescente** depois de 5 erros (30 s, 1, 2, 4… até 15 min), persistida —
   fechar o app não zera a contagem.
3. **Biometria** opcional (`local_auth`, só biometria, sem cair no PIN do aparelho);
   exige PIN definido e uma leitura bem-sucedida para ligar.
4. O app **bloqueia ao abrir** e ao voltar depois de 1, 5 ou 15 min em segundo plano
   (não "imediato": o seletor de arquivos do sistema também põe o app em segundo plano).
5. A tela de bloqueio fica **por cima** do app (`MaterialApp.builder`); o conteúdo
   continua montado (nada se perde) mas invisível e fora da acessibilidade.
6. **Esqueci o PIN** → única saída: apagar todos os dados. O PIN não é recuperável.
7. **Proteção de tela** (`FLAG_SECURE`, opcional) por canal próprio (`genoz/janela`).
8. **Apagar todos os dados** limpa banco (com `VACUUM`, para não sobrar nada nas
   páginas livres do SQLite), arquivos, ajustes e as cópias que o seletor de arquivos
   deixa no cache (estas também são apagadas depois de cada importação).

## Consequências

- A tela de Ajustes diz claramente que o bloqueio não criptografa os arquivos.
- `MainActivity` virou `FlutterFragmentActivity` e os temas Android passaram a AppCompat
  (exigências da caixa de biometria). Se `flutter_native_splash` for rodado de novo,
  conferir que os temas continuam AppCompat.
- O APK de release só pede `USE_BIOMETRIC` (e `USE_FINGERPRINT`, que vem junto da
  biblioteca androidx.biometric). Nada de INTERNET nem de armazenamento — o CI falha se
  alguma dessas aparecer.

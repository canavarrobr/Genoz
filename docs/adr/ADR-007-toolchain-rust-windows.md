# ADR-007 — Toolchain Rust GNU + MinGW em `C:\mingw64` no Windows

**Status:** aceita (29/09/2026, Módulo 1)

## Contexto
- O Visual Studio Build Tools da máquina de desenvolvimento não tem o componente C++ (MSVC), e instalá-lo exige administrador.
- O toolchain Rust `x86_64-pc-windows-gnu` dispensa o MSVC, mas crates modernas (`windows-sys`, `getrandom`) precisam de `dlltool` e `as`, que não vêm completos no Rust.
- O GCC do MinGW falha quando está num caminho com espaço (`C:\Users\Cauan Navarro\...`) — o mesmo problema já visto com o Android NDK no projeto Ovvy.

## Decisão
- Rust instalado com `--default-host x86_64-pc-windows-gnu`.
- MinGW-w64 (WinLibs, via winget) copiado para `C:\mingw64` e `C:\mingw64\bin` colocado no início do PATH do usuário.
- Tudo automatizado em `tools/setup.ps1`; `tools/doctor.ps1` verifica.
- O CI (GitHub Actions) usa o toolchain padrão de cada sistema (MSVC no Windows), o que também garante que o código não depende do GNU.

## Consequências
- Nenhuma etapa exige administrador.
- O alvo Flutter **Windows desktop** continua indisponível (exige MSVC); não é necessário para o APK nem para o site. Se um dia for desejado, basta adicionar o componente "Desenvolvimento para desktop com C++" ao Build Tools.

# Genoz - instalação guiada das ferramentas (sem precisar de administrador).
# Uso (PowerShell, na pasta Genoz):  .\tools\setup.ps1
#
# Instala somente o que faltar:
#   1. Rust (rustup, toolchain GNU) + alvos WASM e Android
#   2. MinGW-w64 (WinLibs) via winget, necessário para o Rust GNU no Windows
# Flutter, JDK e Android SDK são verificados pelo doctor.ps1 (já usados no Ovvy).

$ErrorActionPreference = 'Stop'
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'

if (-not (Test-Path (Join-Path $cargoBin 'rustup.exe'))) {
    Write-Host "Instalando Rust (fonte oficial: static.rust-lang.org)..." -ForegroundColor Cyan
    $init = Join-Path $env:TEMP 'rustup-init.exe'
    Invoke-WebRequest 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-gnu/rustup-init.exe' -OutFile $init
    & $init -y --default-host x86_64-pc-windows-gnu --default-toolchain stable --profile minimal -c clippy -c rustfmt
}
$env:PATH = "$cargoBin;$env:PATH"
rustup target add wasm32-unknown-unknown aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

# O GCC do MinGW não funciona em caminhos com espaço (ex.: "C:\Users\Nome Sobrenome"),
# por isso a cópia final fica em C:\mingw64 (ver docs/adr/ADR-007).
if (-not (Test-Path 'C:\mingw64\bin\as.exe')) {
    Write-Host "Instalando MinGW-w64 (WinLibs) pelo winget..." -ForegroundColor Cyan
    winget install --id BrechtSanders.WinLibs.POSIX.UCRT --exact --scope user --disable-interactivity
    $pkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory |
        Where-Object Name -like 'BrechtSanders.WinLibs.POSIX.UCRT*' | Select-Object -First 1
    if (-not $pkg) { throw "WinLibs não encontrado após o winget." }
    robocopy (Join-Path $pkg.FullName 'mingw64') 'C:\mingw64' /E /NFL /NDL /NJH /NP /MT:16 | Out-Null
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' |
    Where-Object { $_ -and ($_ -notmatch 'BrechtSanders\.WinLibs') }
if ($userPath -notcontains 'C:\mingw64\bin') {
    [Environment]::SetEnvironmentVariable('Path', ((@('C:\mingw64\bin') + $userPath) -join ';'), 'User')
    Write-Host "PATH atualizado. Feche e reabra o terminal." -ForegroundColor Yellow
}
$env:PATH = "C:\mingw64\bin;$env:PATH"

& (Join-Path $PSScriptRoot 'doctor.ps1')

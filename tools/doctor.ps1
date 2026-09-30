# Genoz - diagnóstico do ambiente de desenvolvimento.
# Uso (PowerShell, na pasta Genoz):  .\tools\doctor.ps1
# Não altera nada; só verifica e explica o que falta.

$ErrorActionPreference = 'Continue'
$problemas = 0

function Ok($msg)    { Write-Host "  [OK]    $msg" -ForegroundColor Green }
function Falta($msg, $dica) {
    Write-Host "  [FALTA] $msg" -ForegroundColor Red
    if ($dica) { Write-Host "          -> $dica" -ForegroundColor Yellow }
    $script:problemas++
}
function Aviso($msg) { Write-Host "  [AVISO] $msg" -ForegroundColor Yellow }

function Versao($cmd, $arg = '--version') {
    try { (& $cmd $arg 2>$null | Select-Object -First 1) } catch { $null }
}

Write-Host "`nGenoz - verificação do ambiente`n" -ForegroundColor Cyan

# Rust
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
if (-not (Get-Command rustc -ErrorAction SilentlyContinue) -and (Test-Path $cargoBin)) {
    $env:PATH = "$cargoBin;$env:PATH"
}
$rustc = Versao rustc
if ($rustc) { Ok "Rust: $rustc" } else { Falta "Rust não encontrado" "rode .\tools\setup.ps1" }

if (Get-Command rustup -ErrorAction SilentlyContinue) {
    $targets = rustup target list --installed
    foreach ($t in 'wasm32-unknown-unknown', 'aarch64-linux-android', 'armv7-linux-androideabi', 'x86_64-linux-android') {
        if ($targets -contains $t) { Ok "alvo Rust $t" } else { Falta "alvo Rust $t" "rustup target add $t" }
    }
}

# MinGW (necessário para o toolchain Rust GNU no Windows)
$as = Get-Command as.exe -ErrorAction SilentlyContinue
$dlltool = Get-Command dlltool.exe -ErrorAction SilentlyContinue
if ($as -and $dlltool) { Ok "MinGW (as/dlltool): $(Split-Path $as.Source)" }
else { Falta "MinGW (as.exe/dlltool.exe) fora do PATH" "rode .\tools\setup.ps1 (instala WinLibs) e reabra o terminal" }

# Flutter
$flutter = Versao flutter
if ($flutter) { Ok "Flutter: $flutter" } else { Falta "Flutter não encontrado" "instale o Flutter e adicione flutter\bin ao PATH" }

# Java / Android
$jdk = $null
try { $jdk = (flutter config --list 2>$null | Select-String 'jdk-dir:\s*(.+)').Matches.Groups[1].Value.Trim() } catch {}
if ($jdk -and (Test-Path $jdk)) { Ok "JDK do Flutter: $jdk" } else { Aviso "JDK do Flutter não configurado (flutter config --jdk-dir <pasta do JDK 21>)" }

$sdk = $env:ANDROID_HOME
if ($sdk -and (Test-Path $sdk)) {
    Ok "Android SDK: $sdk"
    if ($sdk -match ' ') { Aviso "o caminho do Android SDK tem espaço; o NDK pode falhar" }
    $ndk = Get-ChildItem (Join-Path $sdk 'ndk') -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($ndk) { Ok "Android NDK: $($ndk.Name)" } else { Falta "Android NDK" "instale pelo SDK Manager (NDK side-by-side)" }
} else {
    Falta "ANDROID_HOME não definido" "aponte ANDROID_HOME para a pasta do Android SDK"
}

# Git
$git = Versao git
if ($git) { Ok "Git: $git" } else { Falta "Git não encontrado" "instale o Git for Windows" }

Write-Host ""
if ($problemas -eq 0) {
    Write-Host "Tudo pronto para desenvolver o Genoz." -ForegroundColor Green
} else {
    Write-Host "$problemas item(ns) precisam de atenção (veja as dicas acima)." -ForegroundColor Red
}
exit $problemas

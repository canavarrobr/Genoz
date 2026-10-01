# Compila o site do Genoz e o abre em http://127.0.0.1:8765/
# Uso (na pasta Genoz):  .\tools\web.ps1          (compila e serve)
#                        .\tools\web.ps1 -SoServir (só serve o que já foi compilado)
param([switch]$SoServir)
$ErrorActionPreference = 'Stop'
$env:Path = "C:\flutter\bin;C:\mingw64\bin;$env:USERPROFILE\.cargo\bin;" + $env:Path
$app = Join-Path $PSScriptRoot '..\app'
Push-Location $app
try {
  if (-not $SoServir) {
    flutter_rust_bridge_codegen build-web --release
    flutter.bat build web --release --no-web-resources-cdn
  }
  Write-Host 'Abra http://127.0.0.1:8765/ no Chrome ou Edge (Ctrl+C para parar).'
  python -m http.server 8765 --bind 127.0.0.1 --directory build\web
} finally { Pop-Location }

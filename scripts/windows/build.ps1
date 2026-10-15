param(
  [string]$ApiBaseUrl = 'http://179.197.74.30:3000',
  [switch]$SkipChecks
)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
  throw 'La compilación Flutter Windows requiere Windows y Visual Studio con C++.'
}
$endpoint = [Uri]$ApiBaseUrl
if (-not $endpoint.IsAbsoluteUri -or $endpoint.Scheme -notin @('http', 'https')) {
  throw 'ApiBaseUrl debe ser una dirección HTTP/HTTPS absoluta.'
}
Push-Location (Resolve-Path "$PSScriptRoot/../..")
try {
  function Invoke-Flutter {
    & flutter @args
    if ($LASTEXITCODE -ne 0) { throw "Flutter falló: $args" }
  }
  Invoke-Flutter pub get
  if (-not $SkipChecks) {
    Invoke-Flutter analyze
    Invoke-Flutter test
  }
  Invoke-Flutter build windows --release --target lib/main.dart "--dart-define=API_BASE_URL=$ApiBaseUrl"
  $release = 'build/windows/x64/runner/Release'
  if (-not (Test-Path "$release/ficon_power.exe")) { throw 'No se generó ficon_power.exe.' }
  New-Item -ItemType Directory -Force dist/windows | Out-Null
  Compress-Archive -Path "$release/*" -DestinationPath dist/windows/FiconPower-Windows-x64.zip -Force
  Write-Host 'Generado dist/windows/FiconPower-Windows-x64.zip (EXE + DLL + recursos).'
} finally { Pop-Location }

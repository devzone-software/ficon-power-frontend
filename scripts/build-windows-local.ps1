$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron resolver las dependencias.' }
flutter analyze lib test
if ($LASTEXITCODE -ne 0) { throw 'El análisis de código falló.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas locales.' }
flutter build windows --release -t lib/main.dart
if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación Windows.' }
if (!(Test-Path 'build/windows/x64/runner/Release/ficon_power.exe')) {
    throw 'No se generó ficon_power.exe.'
}
New-Item -ItemType Directory -Force dist/windows | Out-Null
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath dist/windows/FiconPower-Windows-x64.zip -Force
Write-Host 'Distribuir el ZIP completo: el EXE necesita sus DLL y la carpeta data.'

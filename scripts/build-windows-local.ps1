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
$releaseDirectory = Resolve-Path 'build/windows/x64/runner/Release'
# App-local CRT distribution recommended by Flutter's Windows deployment guide:
# https://docs.flutter.dev/platform-integration/windows/building
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (!(Test-Path $vswhere)) { throw 'No se encontró vswhere para localizar el runtime C++.' }
$visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or !$visualStudio) { throw 'No se encontró Visual Studio con C++.' }
$runtimeDirectory = Get-ChildItem -Path (Join-Path $visualStudio 'VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT') -Directory |
    Sort-Object FullName -Descending | Select-Object -First 1
if (!$runtimeDirectory) { throw 'No se encontró el runtime C++ redistribuible x64.' }
Copy-Item -Path (Join-Path $runtimeDirectory.FullName '*.dll') -Destination $releaseDirectory -Force
foreach ($required in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    if (!(Test-Path (Join-Path $releaseDirectory $required))) { throw "Falta el runtime $required en el paquete." }
}
Copy-Item -LiteralPath 'LEEME.md' -Destination $releaseDirectory -Force
New-Item -ItemType Directory -Force dist/windows | Out-Null
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath dist/windows/FiconPower-Windows-x64.zip -Force
Write-Host 'Distribuir el ZIP completo: el EXE necesita sus DLL y la carpeta data.'

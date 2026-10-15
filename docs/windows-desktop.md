# FICON Power para Windows

Rama: `feature/windows-desktop`.

Aplicación Flutter nativa que reutiliza `lib/main.dart`, las vistas de
escritorio, autenticación y consultas al backend. El backend continúa en el VPS.
No inicia Firebase Messaging ni el actualizador APK de Android. Las alertas
Android en segundo plano no están implementadas para Windows.

## Compilar

Requiere Windows x64, Flutter 3.44.8 y Visual Studio con Desktop development
with C++. Desde PowerShell en el proyecto:

```powershell
./scripts/windows/build.ps1 -ApiBaseUrl 'http://179.197.74.30:3000'
```

El script ejecuta análisis, pruebas y compilación release. Resultado:
`dist/windows/FiconPower-Windows-x64.zip`. Extraer todo el archivo y abrir
`ficon_power.exe`. No distribuir solo el EXE: requiere las DLL y `data`.
El equipo destino necesita el Microsoft Visual C++ Redistributable x64.
La URL es la configurada actualmente; usar HTTPS cuando el despliegue disponga
de certificado y dominio. No incluir credenciales de administrador o API privadas
en el ejecutable.

## GitHub Actions

El workflow `FICON Power Windows` compila al publicar esta rama y también admite
ejecución manual con una URL de backend. Descargar el artefacto de una ejecución
correcta en Actions. Este workflow no despliega al VPS ni crea un release público.

## Verificación manual en Windows

1. Abrir el EXE en un equipo x64 con los recursos completos.
2. Iniciar sesión y comprobar dashboard, dispositivos, detalle y mapa.
3. Comprobar incidentes, calendario y administración según permisos.
4. Validar exportaciones y apertura de enlaces.
5. Cerrar sesión y comprobar errores de conexión con el backend inaccesible.

La compilación Windows y estas pruebas requieren una ejecución real en Windows.
Las pruebas realizadas en Linux no equivalen a esa validación.

## Estado de preparación (15 de octubre de 2026)

Soporte nativo agregado a partir de las plantillas de Flutter 3.44.8, con icono
FICON y nombre de ventana personalizados. Sintaxis PowerShell validada y
análisis Dart correcto (`No issues found`). La suite Flutter local quedó
bloqueada por permisos de la configuración de herramientas del SDK compartido.
Todavía no se generó ni se ejecutó el EXE: falta un runner Windows. El workflow
incluye las pruebas para ejecutarlas antes de producir el artefacto.

Referencias: https://docs.flutter.dev/platform-integration/windows/setup y
https://docs.flutter.dev/platform-integration/windows/building.

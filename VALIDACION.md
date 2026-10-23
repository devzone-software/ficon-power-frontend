# Verificación de FICON Power autónomo

Implementación local: 22 de octubre de 2026. Compilación Windows: 23 de octubre de 2026.

## Alcance y origen

- Versión autónoma aislada en la rama `feature/autonomous-windows`, autorizada
  para su compilación en GitHub Actions; `main` permanece sin cambios.
- Frontend base: `main`, commit `657bad5`.
- Runner Windows reutilizado desde `feature/windows-desktop`, commit `dd8951e`.
- No se modificó el código de `main` del frontend ni el backend.
- No se copiaron `.env`, cuentas de servicio Firebase ni claves de firma de producción.

## Resultados

| Comprobación | Resultado |
|---|---|
| Análisis de `lib` y `test` | Sin observaciones |
| Suite completa de pruebas | 84 pruebas aprobadas |
| Recorrido móvil con el motor local | Aprobado: abrir Operaciones y registrar corte |
| Persistencia al reabrir el motor | Aprobada |
| Corte repetido sin duplicación | Aprobado |
| Atención y cierre por retorno | Aprobados |
| Filtros y paginación de incidentes | Aprobados |
| Usuario y destinatario WhatsApp coherentes | Aprobado |
| Historial de WhatsApp simulado | Aprobado; no entrega mensajes externos |
| Permisos del técnico y revocación de sesión | Aprobados |
| Retiro de dispositivo conservando historial | Aprobado |
| APK Android de lanzamiento | Compilada, ARM64, versión 1.0.0 (1) |
| Identificador Android | `pe.ficon.power.local` |
| Permiso Android INTERNET | Ausente, verificado en la APK final |
| Sonido de alarma | Recurso `raw/power_alarm` conservado en la APK |
| Firma Android | Certificado de desarrollo; no es la firma de producción |
| Instalación y prueba en un teléfono físico | Pendiente; no se instaló sin pedirlo |
| Compilación Windows x64 | Generada en GitHub Actions sobre Windows 2022 |
| Pruebas automatizadas en Windows | 84 aprobadas; análisis sin observaciones |
| Runtime C++ incluido | `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` y DLL asociadas |
| Prueba manual en un equipo Windows | Pendiente |

## Entregables

- `dist/mobile/ficon-power.apk`: aplicación Android independiente.
- `dist/windows/FiconPower-Windows-x64.zip`: ejecutable Windows, DLL, recursos
  y guía de uso; paquete descargado y comprobado localmente.
- `scripts/build-windows-local.ps1`: compila la misma aplicación en Windows y
  empaqueta el EXE con sus DLL y datos. Requiere Flutter y Visual Studio C++.
- `dist/FiconPower-Fuentes.zip`: fuentes y scripts para ambos destinos, sin cachés
  ni archivos privados de configuración.
- `LEEME.md`: cuentas iniciales, recorrido, almacenamiento y compilación.

## Límites de las verificaciones

Las pruebas automatizadas no sustituyen una revisión en dispositivos físicos.
En particular, faltan comprobar permisos y sonido de las alertas Android,
apertura desde una notificación del sistema, guardado/compartición de archivos
en el sistema operativo y ejecución del paquete Windows.

Las pantallas usan el motor local común. La rama de compilación de GitHub no
despliega al VPS. La compilación Windows se verifica en GitHub Actions; no se
considera una prueba manual de uso en un equipo Windows.

## Trazabilidad de Windows

- Rama: `feature/autonomous-windows`.
- Commit de compilación: `b1ba51bb9eb11ab821f8e2f6efc9a322beca9f1a`.
- [Ejecución de GitHub Actions](https://github.com/devzone-software/ficon-power-frontend/actions/runs/39948996039).
- Artefacto: `FiconPower-Windows-x64`, ID `12500191295`.
- SHA-256 del ZIP de distribución:
  `0fc391377fc09338b28d63e59a0457280fa251b0d35d3d40914bcdf384438ca0`.
- Se comprobó la integridad del ZIP y la presencia del ejecutable, las DLL del
  runtime C++ y `data/app.so`. El SHA-256 del archivo descargado de GitHub coincide
  con el digest publicado por Actions.

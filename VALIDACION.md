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
| Suite completa de pruebas | 88 pruebas aprobadas en Linux tras el fix de arranque y la actualización de claves |
| Recorrido móvil con el motor local | Aprobado: abrir Operaciones y registrar corte |
| Persistencia al reabrir el motor | Aprobada |
| Corte repetido sin duplicación | Aprobado |
| Atención y cierre por retorno | Aprobados |
| Filtros y paginación de incidentes | Aprobados |
| Usuario y destinatario WhatsApp coherentes | Aprobado |
| Historial de WhatsApp simulado | Aprobado; no entrega mensajes externos |
| Permisos del técnico y revocación de sesión | Aprobados |
| Retiro de dispositivo conservando historial | Aprobado |
| APK Android de lanzamiento | Compilada, ARM64, versión 1.0.2 (3) |
| Identificador Android | `pe.ficon.power.local` |
| Permiso Android INTERNET | Ausente, verificado en la APK final |
| Sonido de alarma | Recurso `raw/power_alarm` conservado en la APK |
| Firma Android | Certificado de desarrollo; no es la firma de producción |
| Instalación y arranque en un teléfono físico | Aprobados: actualización con datos conservados y login visible en Redmi 24117RN76L |
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
En particular, faltan comprobar a fondo permisos y sonido de las alertas Android,
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

## Corrección de pantalla gris en Android — 23/10/2026

El arranque de la APK 1.0.0 se detenía antes de mostrar el login. El registro del
celular mostró `Failed to load dynamic library at path: libdartjni.so` al llamar
a `getApplicationSupportDirectory`. La APK entregada solo contenía `libapp.so`
y `libflutter.so`: la preparación de paquetes con Dart, seguida de compilación
sin la etapa de Flutter pub get, había omitido la integración de plugins nativos.

Corrección aplicada localmente en la rama independiente:

- Regeneración nativa con `flutter pub get` antes de compilar.
- Verificación del registro JNI generado y de `lib/arm64-v8a/libdartjni.so` en
  el APK antes de copiarlo a distribución.
- Pantalla inicial visible con indicador de carga, error recuperable y botón
  Reintentar; no se eliminan datos si falla el almacenamiento.
- Versión Android 1.0.1, código 2, mismo identificador y firma de desarrollo.
- Actualización por ADB con `install -r`, sin desinstalar ni limpiar datos.
- Arranque en frío correcto, versión instalada comprobada y login verificado
  visualmente en el teléfono. El error JNI anterior ya no aparece al arrancar.
- Dos pruebas nuevas para carga inicial y fallo recuperable; suite total de 86
  pruebas y análisis sin observaciones.
- SHA-256 de la APK corregida:
  `a084b0ab0b0914b2021e9edeb81c7b530ee17aa41eaad62d52bf4d311a23b9e6`.

El ZIP Windows documentado arriba sigue correspondiendo a la versión 1.0.0 y
al commit b1ba51b. El fix de arranque se incorpora también a las fuentes comunes
para la nueva compilación independiente; no se despliega a producción.

## Claves iniciales simplificadas — Android 1.0.2

Por solicitud del usuario, las cuentas iniciales `superadmin`, `admin` y
`tecnico` de esta versión local usan `1234`. No se modifican credenciales de
producción. La actualización migra una sola vez las contraseñas predeterminadas
de instalaciones anteriores, conserva las contraseñas personalizadas y no
reemplaza datos de usuarios, dispositivos o incidentes.

Se agregaron pruebas de acceso para las tres cuentas y de migración con
conservación de datos y contraseña personalizada: 88 pruebas aprobadas en total,
con análisis sin observaciones. La APK conserva `libdartjni.so`.

SHA-256 de Android 1.0.2:
`2864af43a24d30894f199ab5d4cb00f94ee55a91bf6ed2d4cfbfb297542883b3`.

El ejecutable Windows 1.0.0 distribuido anteriormente mantiene su contraseña
anterior. Se prepara Windows 1.0.2 en `feature/autonomous-windows` para aplicar
las mismas claves y la migración al abrir los datos locales existentes.

## Corrección de etiquetas diarias — versión 1.0.3

La ficha titulada «Últimos 7 días» recibía 30 barras en el motor local. Al
repartirse en el ancho disponible, los textos de fecha se dividían en varias
líneas y parecían verticales. Se ajusta la consulta a siete días y cuatro
semanas, de acuerdo con los títulos de las gráficas.

Las etiquetas diarias se muestran como `dd/MM`, sin año ni hora. Todas las
etiquetas de barras tienen una sola línea, un ancho mínimo por barra y
desplazamiento horizontal cuando hace falta; el tooltip conserva la etiqueta
completa y el número de cortes. No cambia el historial ni la paleta de colores.

Se agregaron pruebas de formato y de presentación a 320 y 1024 píxeles, y
comprobaciones de los periodos de siete días/cuatro semanas. La versión se
compila para Android y Windows en la misma rama independiente.

# FICON Power

Aplicación autónoma para Android y Windows, basada en el frontend del proyecto.
Esta versión se publica únicamente en la rama `feature/autonomous-windows` del
frontend para su compilación en GitHub Actions. No se integra en `main` ni se
publica en el VPS. No contiene archivos `.env` ni claves de producción.

## Acceso inicial

| Usuario | Rol | Contraseña inicial |
|---|---|---|
| superadmin | Administrador general | 1234 |
| admin | Administrador | 1234 |
| tecnico | Técnico | 1234 |

Son cuentas locales ficticias, no cuentas del sistema de producción. El
superadministrador puede modificar las contraseñas en Usuarios. Cada instalación
mantiene sus propios usuarios y registros; Android y Windows no se sincronizan.

## Recorrido

1. Iniciar sesión y revisar el resumen mensual/semanal.
2. Abrir Dispositivos, filtrar por estado o distrito y consultar sus fichas.
3. Abrir **Operaciones** desde el icono de conexión eléctrica de la barra superior.
4. Registrar un corte: cambia el estado, crea un incidente y un evento y actualiza
   las estadísticas y las notificaciones locales.
5. Atender el incidente desde su ficha o el resumen.
6. Restaurar la energía en Operaciones: cierra el incidente y registra la duración.
7. Crear un usuario con WhatsApp habilitado y ejecutar una prueba. Su historial
   indica **Simulado**: no se entrega ningún mensaje externo.
8. Exportar dispositivos, incidentes o eventos a CSV/Excel.

Operaciones permite agregar o retirar dispositivos. El retiro conserva el
historial y exige restaurar la energía antes de retirar un medidor con corte.
La edición de nombre y distrito se conserva en la ficha habitual del dispositivo.
El técnico no puede administrar usuarios ni generar cortes.

## Datos y funcionamiento sin conexión

- Motor local en `lib/offline/local_engine.dart`; adaptador en memoria para los
  contratos existentes. No abre conexiones HTTP ni tiene fallback al backend.
- Datos iniciales ficticios: cuatro medidores y 24 cortes resueltos recientes.
- Archivo persistente `ficon-local-v1.json` en el directorio de soporte de la app.
  Se guarda tras cada modificación, con archivo temporal y respaldo `.bak`.
- Contraseñas con sal aleatoria y hash iterado; no se guardan en texto plano.
  Es almacenamiento local, no un mecanismo para proteger contra quien controle
  el equipo o edite el archivo de datos.
- Las sesiones duran 12 horas. Se inicia sesión de nuevo al abrir la aplicación.
- El mapa es un plano local de ubicaciones de Puno, no un mapa de calles descargado.
- La fecha inicial de renovación es 28/02/2027; no cambia la suscripción real.
- Las alertas del sistema requieren permiso del usuario. Sin permiso, permanece
  disponible la bandeja interna. No hay generación de eventos con la app cerrada.
- No usa Tuya, Meta, Firebase, Supabase, VPS ni actualizaciones remotas.
- El superadministrador puede restablecer el escenario desde Operaciones. Esa
  acción reemplaza datos locales y cierra las sesiones.

## Compilación Android

Con Flutter 3.44.8 y un SDK Android compatible:

```sh
bash scripts/build-android-local.sh
```

Salida: `dist/mobile/ficon-power.apk`. Identificador Android `pe.ficon.power.local`,
distinto del sistema original. Sin clave privada, Gradle utiliza la firma de
desarrollo; conservar esa clave local para poder actualizar la instalación.
No ejecutar los scripts antiguos de publicación del proyecto original.

APK local actual: 1.0.2 (3), con el arranque Android corregido y clave inicial
`1234`. Al actualizar, solo se cambia la clave predeterminada de esas tres
cuentas; se conservan las contraseñas personalizadas y todos los registros.
El script prepara
los plugins mediante `flutter pub get` y verifica que el paquete incluya la
biblioteca JNI antes de publicarlo en `dist/mobile`. No sustituir esa etapa por
`dart pub get` ni omitirla al construir una copia nueva.

## Compilación Windows

En Windows x64 con Flutter y Visual Studio con desarrollo de escritorio C++:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-windows-local.ps1
```

Salida: `dist/windows/FiconPower-Windows-x64.zip`. Extraer el ZIP completo y abrir
`ficon_power.exe`; no separar el ejecutable de las DLL y la carpeta `data`.
El ZIP incluye las DLL del runtime C++ para no depender de su instalación previa.
No necesita backend. Esta compilación requiere Windows; Linux no produce un
ejecutable Flutter Windows mediante compilación cruzada.

La versión Windows 1.0.2 también utiliza `1234` para las tres cuentas iniciales.
Al abrirla sobre una instalación anterior, migra las claves predeterminadas
sin borrar el historial; no cambia contraseñas personalizadas.

### GitHub Actions

El flujo `.github/workflows/windows-local.yml` prepara Windows 2022 y Flutter
3.44.8, ejecuta el análisis y todas las pruebas, compila y guarda el artefacto
`FiconPower-Windows-x64`. No usa secretos de producción ni despliega al VPS.
Debe publicarse con estas fuentes autónomas, no ejecutar el flujo del frontend
original, que compila la versión conectada al backend.

La publicación de esta rama inicia automáticamente la compilación. El paquete
resultante aparece como artefacto `FiconPower-Windows-x64` en la ejecución de
GitHub Actions; contiene el ZIP con el ejecutable, sus DLL y la carpeta `data`.

## Verificación

```sh
flutter test test/local_engine_test.dart
flutter analyze lib test/local_engine_test.dart
```

Las pruebas cubren persistencia, idempotencia de cortes, retorno, atención,
permisos, revocación de sesiones, filtros, destinatarios y mensajes simulados.
El estado real de compilaciones y verificaciones está en `VALIDACION.md`.

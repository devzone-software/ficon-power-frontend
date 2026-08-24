# FICON Power Mobile

Base inicial para la app móvil interna de FICON Power, en versiones inferiores a
`1.0.0` mientras madura hacia producción.

La app reutiliza el backend, autenticación y vistas actuales del dashboard
Flutter, pero se compila desde un entrypoint separado para poder evolucionar la
experiencia móvil sin afectar la versión web.

## Alcance de esta base

Incluido:

- Login contra el backend actual.
- Sesión persistente en almacenamiento seguro del celular hasta cerrar sesión.
- Acceso a dashboard, dispositivos, incidentes y eventos.
- Permiso Android de notificaciones.
- Notificaciones locales al detectar eventos nuevos desde `/api/events`.
- Configuración Android con nombre `FICON Power`.
- Firma release persistente para actualizar sobre la app instalada.
- Manifiesto de actualización `version.json`.
- Entry point móvil independiente: `lib/main_mobile.dart`.
- Registro de token FCM contra el backend cuando Firebase está configurado.
- Push FCM para recibir alertas aunque Android cierre la app.
- Navegación inferior adaptativa y panel lateral de cuenta.
- Vistas móviles compactas para dashboard, dispositivos, incidentes y eventos.
- Consola administrativa condicionada por rol.
- Exportación de dispositivos, incidentes y eventos en CSV/XLSX.

No incluido todavía:

- Offline mode.
- Publicación en Play Store/App Store.

## Notificaciones

La configuración completa, desde el registro Android hasta el diagnóstico en
PostgreSQL, está en [`firebase-mobile.md`](firebase-mobile.md).

La app solicita permiso de notificaciones en Android y consulta eventos nuevos
cada 20 segundos mientras el usuario está autenticado. Si detecta un evento
nuevo, muestra una notificación local:

- `deviceOffline`: Corte detectado.
- `deviceOnline`: Retorno detectado.
- otros eventos: Nuevo evento FICON Power.

Este polling queda como fallback de desarrollo cuando Firebase no está
configurado.

Cuando Firebase Cloud Messaging está configurado, la app registra su token FCM
en el backend y deja de hacer polling periódico para notificaciones locales. En
ese modo, el backend envía la alerta push y Android puede mostrarla aunque la
app esté cerrada o fuera de memoria.

Variables móviles necesarias en build:

```bash
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
```

Para no escribirlas en cada build, cree un archivo local ignorado por Git:

```bash
cp .env.mobile.example .env.mobile
nano .env.mobile
```

Contenido esperado:

```env
API_BASE_URL=http://179.197.74.30:3000
MOBILE_APK_URL=http://179.197.74.30:3000/mobile/ficon-power.apk
MOBILE_UPDATE_MANIFEST_URL=http://179.197.74.30:3000/mobile/version.json

FIREBASE_API_KEY=AIzaSy...
FIREBASE_APP_ID=1:123456789012:android:...
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_PROJECT_ID=ficon-power-test
```

Compilar cargando `.env.mobile`:

```bash
set -a
source .env.mobile
set +a
bash scripts/build-mobile-apk.sh
```

El script lee esas variables del entorno y las inyecta en la APK mediante
`--dart-define`.

Variables backend necesarias:

```env
FCM_ENABLED=true
FCM_PROJECT_ID=...
FCM_CREDENTIALS_PATH=/app/secrets/firebase-service-account.json
FCM_CREDENTIALS_JSON=
FCM_DRY_RUN=false
```

El backend registra cada intento en `notification_deliveries` y guarda tokens
activos/revocados en `mobile_device_tokens`.

## Sesión móvil persistente

En Android, la app guarda el token y el usuario en almacenamiento seguro del
dispositivo. Si cierras la app o la eliminas de segundo plano, al abrirla de
nuevo intentará restaurar la sesión y entrar directo al dashboard.

La sesión solo se borra cuando el usuario pulsa “Cerrar sesión”. Si el backend
invalida el token por expiración o seguridad, la app deberá volver a iniciar
sesión.

## Ejecutar en Android emulator

Desde `ficon-power-frontend/`:

```bash
flutter pub get
flutter run \
  -t lib/main_mobile.dart \
  -d android \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` permite que el emulador Android llegue al backend que corre en el host.

Si pruebas contra un VPS o servidor LAN, usa su URL real:

```bash
flutter run \
  -t lib/main_mobile.dart \
  -d android \
  --dart-define=API_BASE_URL=http://IP_O_DOMINIO:3000
```

## Firma release persistente

Antes de generar APKs instalables, crea una llave local una sola vez:

```bash
./scripts/generate-mobile-signing-key.sh
```

Esto crea:

```text
android/keystores/ficon-power-release.jks
android/key.properties
```

Ambos archivos están ignorados por Git y no deben publicarse. Haz una copia
segura: si pierdes esa llave, Android no podrá actualizar encima instalaciones
firmadas con ella.

## Build APK firmado

Con Flutter instalado en el host:

```bash
flutter build apk \
  -t lib/main_mobile.dart \
  --release \
  --dart-define=API_BASE_URL=http://179.197.74.30:3000
```

Si el host no tiene Flutter/Java, se puede usar Docker:

```bash
./scripts/build-mobile-apk.sh
```

El wrapper delega la implementación a
`scripts/mobile/android/build-apk.sh`. Por defecto genera exclusivamente
`arm64-v8a`, arquitectura confirmada para los teléfonos internos:

```bash
ANDROID_APK_VARIANT=arm64 bash scripts/build-mobile-apk.sh
```

Para recuperar la APK universal compatible con ARM64, ARMv7 y emuladores x86:

```bash
ANDROID_APK_VARIANT=universal bash scripts/build-mobile-apk.sh
```

El modo universal conserva el mismo nombre y sistema de actualización. Debe
usarse como respaldo si un dispositivo objetivo no informa `arm64-v8a` en:

```bash
adb shell getprop ro.product.cpu.abilist
```

La variante optimizada combina `--target-platform android-arm64` con un filtro
Gradle de ABI y exclusiones de librerías JNI transitivas. Así se evita que
plugins multiplataforma vuelvan a empaquetar binarios ARMv7 o x86. El modo
universal no aplica estos filtros.

El script usa cachés persistentes en `.mobile-build-cache/` para reutilizar
paquetes Pub, Gradle, Android SDK Platforms, Build Tools, NDK y CMake entre
compilaciones. Esa carpeta está ignorada por Git.

Para compilar contra otra URL:

```bash
API_BASE_URL=http://IP_O_DOMINIO:3000 ./scripts/build-mobile-apk.sh
```

Para compilar con push FCM:

```bash
API_BASE_URL=http://IP_O_DOMINIO:3000 \
FIREBASE_API_KEY=... \
FIREBASE_APP_ID=... \
FIREBASE_MESSAGING_SENDER_ID=... \
FIREBASE_PROJECT_ID=... \
./scripts/build-mobile-apk.sh
```

Forma recomendada usando `.env.mobile`:

```bash
set -a
source .env.mobile
set +a
./scripts/build-mobile-apk.sh
```

El APK queda en:

```text
dist/ficon-power.apk
dist/mobile/ficon-power.apk
```

También genera:

```text
dist/mobile/version.json
```

Si `dist/mobile/` existe antes de reconstruir el frontend web, Docker lo copia
al sitio estático. En el VPS quedará disponible como:

```text
http://TU_VPS:3000/mobile/ficon-power.apk
http://TU_VPS:3000/mobile/version.json
```

La app móvil consulta `version.json`; si detecta un `versionCode` mayor al que
tiene instalado, muestra “Actualización disponible”.

El manifest incorpora `architecture` con `arm64-v8a` o `universal` para dejar
trazabilidad del artefacto publicado. La aplicación tolera este campo adicional.

## Navegación y cuenta

La barra inferior contiene Resumen, Dispositivos, Incidentes y Eventos. Para
los roles `ADMIN` y `SUPERADMIN` agrega Administración como quinto destino.
Las operaciones de usuarios, bloqueos, auditoría y sesiones continúan visibles
exclusivamente para `SUPERADMIN`; `ADMIN` conserva únicamente las herramientas
operativas autorizadas.

El avatar abre un panel lateral con cuenta, nivel de acceso, estado del sistema,
accesos rápidos, versión instalada y cierre de sesión.

## Exportación

La acción del encabezado permite seleccionar Dispositivos, Incidentes o Eventos
y genera únicamente archivos `.csv` o `.xlsx`. CSV usa UTF-8 con BOM y escapado
RFC 4180 para abrir correctamente en Excel. XLSX genera un libro nativo con una
hoja nombrada según el conjunto elegido. Los archivos se crean en memoria y se
entregan al selector de compartir de Android sin solicitar acceso general al
almacenamiento.

## Siguiente fase recomendada

1. Definir atención y asignación de incidentes para técnicos.
2. Agregar modo offline controlado para consultas recientes.
3. Preparar permisos por organización/sede para futura app de clientes.
4. Publicar mediante un canal administrado o tienda cuando finalice la fase
   interna.

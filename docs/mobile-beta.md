# FICON Power Mobile Beta

Base inicial para la app móvil interna de FICON Power.

Esta beta reutiliza el backend, autenticación y vistas actuales del dashboard Flutter, pero se compila desde un entrypoint separado para poder evolucionar la experiencia móvil sin afectar la versión web.

## Alcance de esta base

Incluido:

- Login contra el backend actual.
- Acceso a dashboard, dispositivos, incidentes y eventos.
- Permiso Android de notificaciones.
- Notificaciones locales beta al detectar eventos nuevos desde `/api/events`.
- Marca visual `BETA`.
- Configuración Android con nombre `FICON Power Beta`.
- Entry point móvil independiente: `lib/main_mobile.dart`.

No incluido todavía:

- Notificaciones push con la app completamente cerrada.
- Pantallas móviles rediseñadas desde cero.
- Offline mode.
- Gestión móvil de usuarios.
- Publicación en Play Store/App Store.

## Notificaciones beta

La app solicita permiso de notificaciones en Android y consulta eventos nuevos
cada 20 segundos mientras el usuario está autenticado. Si detecta un evento
nuevo, muestra una notificación local:

- `deviceOffline`: Corte detectado.
- `deviceOnline`: Retorno detectado.
- otros eventos: Nuevo evento FICON Power.

Esta fase es suficiente para pruebas internas con la app abierta o viva en
memoria. Para recibir alertas cuando Android haya cerrado la app por completo,
la siguiente fase debe integrar Firebase Cloud Messaging y registrar tokens
móviles en el backend.

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

## Build APK beta

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

El script usa cachés persistentes en `.mobile-build-cache/` para reutilizar paquetes Pub, Gradle, NDK y CMake entre compilaciones. Esa carpeta está ignorada por Git.

Para compilar contra otra URL:

```bash
API_BASE_URL=http://IP_O_DOMINIO:3000 ./scripts/build-mobile-apk.sh
```

El APK queda en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Para compartirlo sin buscar dentro de `build/`, se puede copiar a:

```bash
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/ficon-power-beta.apk
```

`dist/` está ignorado por Git para no publicar ejecutables generados.

## Siguiente fase recomendada

1. Rediseñar navegación móvil:
   - Inicio
   - Dispositivos
   - Incidentes
   - Perfil
2. Agregar Firebase Cloud Messaging para notificaciones push reales.
3. Registrar tokens móviles en backend.
4. Enviar push ante corte y retorno de energía.
5. Agregar detalle móvil de incidente/dispositivo.
6. Preparar permisos por organización/sede para futura app de clientes.

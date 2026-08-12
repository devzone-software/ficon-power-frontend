# FICON Power Mobile Beta

Base inicial para la app móvil interna de FICON Power.

Esta beta reutiliza el backend, autenticación y vistas actuales del dashboard Flutter, pero se compila desde un entrypoint separado para poder evolucionar la experiencia móvil sin afectar la versión web.

## Alcance de esta base

Incluido:

- Login contra el backend actual.
- Acceso a dashboard, dispositivos, incidentes y eventos.
- Marca visual `BETA`.
- Configuración Android con nombre `FICON Power Beta`.
- Entry point móvil independiente: `lib/main_mobile.dart`.

No incluido todavía:

- Notificaciones push.
- Pantallas móviles rediseñadas desde cero.
- Offline mode.
- Gestión móvil de usuarios.
- Publicación en Play Store/App Store.

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
docker run --rm \
  -v "$PWD:/app" \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  flutter build apk \
    -t lib/main_mobile.dart \
    --release \
    --dart-define=API_BASE_URL=http://179.197.74.30:3000
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
2. Agregar Firebase Cloud Messaging.
3. Registrar tokens móviles en backend.
4. Enviar push ante corte y retorno de energía.
5. Agregar detalle móvil de incidente/dispositivo.
6. Preparar permisos por organización/sede para futura app de clientes.

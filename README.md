# FICON Power

Esta rama contiene la versión autónoma para Android y Windows: datos locales,
sin backend ni conexiones a Tuya, Firebase, Supabase o Meta. No se despliega al VPS.

Consulta [LEEME.md](LEEME.md) para las cuentas iniciales y el recorrido de uso,
y [VALIDACION.md](VALIDACION.md) para el estado de las verificaciones.
GitHub Actions compila el ejecutable en Windows y entrega el paquete completo.

## Referencia del frontend conectado original

Frontend en Flutter para el sistema de gestión de continuidad eléctrica y alerta temprana de Grupo FICON S.A.C. Consume la API REST del [backend Java/Spring Boot](../ficon-power-backend).

## Versiones y requisitos

| Componente | Versión | Fuente |
|------------|---------|--------|
| Flutter | `3.44.8` | `Dockerfile` |
| Dart | `3.12.2` o compatible | `pubspec.yaml` (`sdk: ^3.12.2`) |
| nginx | `1.27-alpine` | `Dockerfile` |
| Docker Engine + Compose | Compose v2 (`docker compose`) | Ejecución del sistema completo |

Dependencias directas de la aplicación: `cupertino_icons ^1.0.8`, `http ^1.2.0` e `intl ^0.20.0`. Para desarrollo y pruebas se usa `flutter_lints ^6.0.0` y el SDK `flutter_test`. Las versiones exactas resueltas, incluidas las dependencias transitivas, están fijadas en `pubspec.lock`.

## Instalación de dependencias

Con Flutter `3.44.8` disponible en el `PATH`:

```bash
flutter --version
flutter pub get
```

`flutter pub get` instala tanto las dependencias de ejecución como las de desarrollo indicadas en `pubspec.yaml`, respetando `pubspec.lock`.

No es necesario instalar Flutter en el host si se usa Docker: la etapa de compilación descarga Flutter `3.44.8`, ejecuta `flutter pub get`, genera la aplicación web y la imagen final la sirve con nginx.

## Arquitectura hexagonal

La estructura de `lib/` refleja la del backend (`adapters`, `domain`, `ports`, `usecase`):

```
lib/
├── config/                  # Configuración de la app (AppConfig)
├── domain/                  # Entidades puras: Site, Device, Incident, MonitoringOverview
├── ports/
│   ├── input/               # Puertos de entrada (casos de uso): GetMonitoringOverview
│   └── output/              # Puertos de salida: MonitoringQueryRepository
├── usecase/                 # Implementaciones de casos de uso: GetMonitoringOverviewService
├── adapters/
│   └── http/                # Adaptador HTTP: FiconMonitoringRepository (API REST del backend)
├── presentation/            # UI Flutter: páginas y widgets (DashboardPage)
└── main.dart                # Ensamblaje e inyección de dependencias
```

El flujo de dependencias apunta hacia el dominio: la presentación depende del puerto de entrada, el caso de uso del puerto de salida, y el adaptador HTTP implementa ese puerto. `main.dart` es el único lugar donde se instancian las clases concretas.

## Configuración

Los valores se inyectan en tiempo de compilación con `--dart-define`:

| Variable       | Descripción                                  | Valor por defecto        |
|----------------|----------------------------------------------|--------------------------|
| `API_BASE_URL` | URL base del backend FICON Power             | `http://localhost:8080`  |
| `API_KEY`      | Clave para el header `X-API-Key` en integraciones; el dashboard usa login Bearer | vacío |

El dashboard solicita login contra el backend. Usuarios iniciales de pruebas locales:

- Las credenciales locales fuertes se documentan en el backend, dentro de `.local/credentials.local.md`.
- Ese archivo está ignorado por Git y no debe publicarse.

En la tarjeta “Plantillas Meta de WhatsApp”, la UI muestra nombre, idioma y variables usadas por WhatsApp. Los mensajes ya no se editan desde el dashboard; el texto aprobado se administra en Meta Business.

## Ejecución

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=API_KEY=mi-clave
```

En Android emulator, el backend local se alcanza como `http://10.0.2.2:8080`.

### App móvil interna

La rama móvil usa un entrypoint separado para compilar la app Android sin afectar la entrada web:

```bash
flutter run \
  -t lib/main_mobile.dart \
  -d android \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

La guía completa está en [`docs/mobile-app.md`](docs/mobile-app.md). La
configuración de push se documenta por separado en
[`docs/firebase-mobile.md`](docs/firebase-mobile.md).

La app móvil solicita permiso de notificaciones en Android. Cuando Firebase
Cloud Messaging está configurado, registra el token en el backend y recibe
alertas aunque la aplicación esté cerrada. El sondeo local permanece únicamente
como fallback cuando la APK fue compilada sin Firebase.

La sesión móvil se guarda en almacenamiento seguro del celular y se restaura al
abrir la app hasta que el usuario cierre sesión.

Primera vez, crea la firma local:

```bash
./scripts/generate-mobile-signing-key.sh
```

Para generar el APK firmado contra el VPS:

```bash
./scripts/build-mobile-apk.sh
```

El script genera por defecto una APK Android ARM64 y usa cachés persistentes en
`.mobile-build-cache/` para Pub, Gradle, Android SDK, Build Tools, NDK y CMake.
El APK queda en `dist/ficon-power.apk` y el publicable para el VPS en
`dist/mobile/ficon-power.apk`. El respaldo universal se construye con
`ANDROID_APK_VARIANT=universal bash scripts/build-mobile-apk.sh`.

### Sistema completo con Docker

Desde `ficon-power-frontend/`, manteniendo `ficon-power-backend/` como carpeta hermana:

```bash
cp ../ficon-power-backend/.env.example ../ficon-power-backend/.env
# Complete las variables de ../ficon-power-backend/.env antes de continuar.
docker compose build
docker compose up -d
docker compose ps
```

La interfaz queda disponible en `http://localhost:3000`. En esta modalidad el navegador solicita `/api/*` al mismo origen; nginx reenvía esas solicitudes a `http://ficon-power-backend:8080` dentro de la red de Compose.

Para comprobar la comunicación entre ambos contenedores:

```bash
# Debe responder HTTP 200 y devolver la lista de sedes (o [] en una BD vacía).
curl -i http://localhost:3000/api/sites

# Verificaciones adicionales de estado y resolución interna.
docker compose ps
docker compose exec frontend wget -qO- http://ficon-power-backend:8080/
```

Si `API_KEY` está configurada en el backend, defina el mismo valor en un archivo `.env` situado junto a este `docker-compose.yml`; nginx lo añadirá como `X-API-Key`. Si se deja vacía, la configuración de nginx sigue siendo válida y el header se omite en la práctica. Para detener el sistema:

```bash
docker compose down
```

## Pruebas y análisis

```bash
flutter analyze
flutter test
```

## Endpoints consumidos

- `GET /api/sites` — sedes, ubicación y cantidad de dispositivos.
- `GET /api/devices` — catálogo de dispositivos, estado e indisponibilidad acumulada.
- `GET /api/incidents?limit=100` — cortes de energía, duración, dispositivo y sede.
- `GET /api/notification-templates` — configuración de plantillas Meta de WhatsApp.
- `POST /api/auth/login` — inicio de sesión y emisión de token Bearer.

Las fechas llegan como ISO-8601 con el offset de Perú (`-05:00`) y se muestran en hora local.

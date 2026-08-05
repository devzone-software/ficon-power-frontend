# FICON Power Frontend

Frontend en Flutter para el sistema de gestión de continuidad eléctrica y alerta temprana de Grupo FICON S.A.C. Consume la API REST del [backend Java/Spring Boot](../ficon-power-backend).

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
| `API_KEY`      | Clave para el header `X-API-Key` (opcional)  | vacío                    |

## Ejecución

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=API_KEY=mi-clave
```

En Android emulator, el backend local se alcanza como `http://10.0.2.2:8080`.

## Pruebas y análisis

```bash
flutter analyze
flutter test
```

## Endpoints consumidos

- `GET /api/sites` — sedes, ubicación y cantidad de dispositivos.
- `GET /api/devices` — catálogo de dispositivos, estado e indisponibilidad acumulada.
- `GET /api/incidents?limit=100` — cortes de energía, duración, dispositivo y sede.

Las fechas llegan como ISO-8601 con el offset de Perú (`-05:00`) y se muestran en hora local.

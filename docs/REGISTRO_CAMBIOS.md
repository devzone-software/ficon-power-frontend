# Registro detallado de cambios — Sistema FICON Power

**Fecha:** 3 de agosto de 2026
**Alcance:** Dos repositorios independientes ubicados en `E:/FICON/1`:
- `ficon-power-backend` — API REST en Java 21 / Spring Boot 4.1.0 (Maven, arquitectura hexagonal, JDBC directo sin JPA, PostgreSQL/Supabase con Flyway, H2 para tests).
- `ficon-power-frontend` — Aplicación Flutter (Dart SDK ^3.12.2, arquitectura hexagonal espejo, sin state management formal — se usa `FutureBuilder`, plataformas Android y Web).

**Contexto del sistema:** FICON Power es el sistema de gestión de continuidad eléctrica y alerta temprana de Grupo FICON S.A.C. El backend recibe eventos de conectividad de dispositivos IoT Tuya (vía Tuya Pulsar con verificación de firma MD5 y descifrado AES, y vía Tuya Cloud), registra cortes de energía como incidentes en PostgreSQL y envía alertas por WhatsApp Business API. El frontend es el panel de administración que consume la API REST (Dashboard, Dispositivos, Incidentes, Eventos). Zona horaria operativa: `America/Lima`.

**Nota sobre control de versiones:** todos los cambios quedaron en el working tree de cada repositorio, sin commits (decisión explícita del usuario; cada repo se maneja por separado).

---

## Funcionalidad 1: Mensajes de notificación editables desde el dashboard

### Problema
Los mensajes de WhatsApp de los dos eventos de monitoreo (corte de energía y retorno de energía) estaban **hardcodeados** en el código del backend (`WhatsAppNotificationAdapter`), por lo que cualquier cambio de texto requería modificar código y redesplegar.

### Solución implementada
Los textos se convirtieron en **plantillas persistidas en base de datos**, editables en caliente desde el dashboard del frontend, con placeholders que el backend reemplaza al momento de notificar.

**Placeholders disponibles:**
- `{dispositivo}` → nombre del dispositivo.
- `{fechaCorte}` → fecha/hora del corte (formato `dd/MM/yyyy HH:mm:ss`, hora de Perú).
- `{fechaRetorno}` → fecha/hora de retorno (solo aplica al evento de retorno).

### Cambios en el backend

1. **Migración Flyway `V4__notification_templates.sql`** (nueva):
   - Crea la tabla `notification_templates(event_type varchar(30) PK, body text NOT NULL, updated_at timestamptz NOT NULL DEFAULT now())` con constraint `CHECK` de body no vacío.
   - Siembra las dos plantillas con los textos originales convertidos a placeholders:
     - `power_outage`: `DEVICE OFF\nDispositivo: {dispositivo}\nFecha y hora del corte: {fechaCorte}`
     - `power_restored`: `DEVICE ON\nDispositivo: {dispositivo}\nFecha y hora del corte: {fechaCorte}\nFecha y hora de retorno: {fechaRetorno}`

2. **Dominio** (nuevos):
   - `NotificationEventType` — enum `POWER_OUTAGE("power_outage")` / `POWER_RESTORED("power_restored")` con conversión desde código.
   - `NotificationTemplate` — record `(eventType, body)` con los textos por defecto como fallback estático.

3. **Puertos** (nuevos): salida `NotificationTemplateRepository` (findAll, findByEventType, update); entrada `GetNotificationTemplates` y `UpdateNotificationTemplate`.

4. **Casos de uso** (nuevos): `GetNotificationTemplatesService` y `UpdateNotificationTemplateService` (valida: body no vacío y máximo 1000 caracteres).

5. **Persistencia** (nueva): `PostgresNotificationTemplateRepository` con `JdbcTemplate` (UPDATE ... RETURNING con `updated_at = now()`).

6. **Renderizado** (modificado): `WhatsAppNotificationAdapter` ahora recibe el repositorio de plantillas, obtiene la plantilla del evento (o el default si no hay fila), formatea las fechas y reemplaza los placeholders con `String.replace`. `NotificationConfig` actualizado para inyectar el repositorio. **No se tocaron** `NotificationChannel`, `MultiNotificationService` ni el caso de uso de conectividad.

7. **API REST** (nueva): `web/NotificationTemplateController.java`:
   - `GET /api/notification-templates` → lista `[{eventType, body}]`.
   - `PUT /api/notification-templates/{eventType}` con body `{"body": "..."}` (validación Bean Validation: `@NotBlank`, `@Size(max=1000)`); `eventType` inválido → HTTP 400.
   - Protegidos automáticamente por el header `X-API-Key` (el filtro existente cubre `/api/**`).

8. **Documentación:** README del backend actualizado con los endpoints y la nota de que los mensajes editables aplican al **modo texto** de WhatsApp (`WHATSAPP_TEMPLATE_NAME` vacío); en modo plantilla Meta el texto se ignora.

### Cambios en el frontend

1. **Dominio** `lib/domain/notification_template.dart` (nuevo): entidad con `eventType`, `body`, `fromJson` y `displayName` ("Corte de energía" / "Retorno de energía").
2. **Puertos** (nuevos): salida `NotificationTemplateRepository`; entrada `GetNotificationTemplates` y `UpdateNotificationTemplate`, con sus servicios en `usecase/`.
3. **Adaptador HTTP** `FiconMonitoringRepository` (modificado): implementa también el nuevo puerto; agrega GET de plantillas y PUT con JSON (helper `_put`, timeout 15 s, manejo de errores con `ApiException`, header `X-API-Key` como el resto).
4. **UI — Dashboard** (`dashboard_page.dart`, modificado): nueva tarjeta **"Mensajes de notificación"** que lista las dos plantillas con preview monoespaciado y botón de editar por cada una. El diálogo de edición tiene campo multilínea precargado, leyenda de placeholders según el evento, botones Cancelar/Guardar con spinner durante el guardado, SnackBar de éxito/error y refresco de la tarjeta.
5. **Ensamblaje** `main.dart`: nuevos servicios creados con el mismo repositorio e inyectados al `DashboardPage`.

---

## Funcionalidad 2: Edición de nombre de dispositivo y asignación de sede

### Problema
No era posible desde la app: (a) cambiar el nombre de un dispositivo — y si se hubiera podido, la **sincronización con Tuya al arrancar el backend lo sobrescribía** (el upsert hacía `name = EXCLUDED.name`); (b) asignar el dispositivo a una sede. Además no existía forma de crear sedes (solo existía "Sin sede asignada" generada por la migración V3), por lo que la asignación no era usable sin un endpoint de creación.

### Decisiones de diseño (conversadas con el usuario)
- La "ubicación" del dispositivo la define **la sede** (ej. una cuchilla en Lampa, otra en Puno, otra en Putina); no se agregaron campos de zona/coordenadas al dispositivo.
- **Nombre protegido:** nueva columna `devices.name_customized`. Si el usuario edita el nombre en la app, la sincronización con Tuya ya no lo pisa; si nunca lo editó, el nombre sigue al de Tuya.

### Cambios en el backend

1. **Migración Flyway `V5__device_custom_names.sql`** (nueva): `ALTER TABLE devices ADD COLUMN name_customized boolean NOT NULL DEFAULT false` con comentario de columna.

2. **Upsert de Tuya protegido** (`PostgresDeviceRepository.upsert`, modificado): el `ON CONFLICT DO UPDATE` ahora usa `SET name = CASE WHEN devices.name_customized THEN devices.name ELSE EXCLUDED.name END`, preservando el resto del comportamiento (categoría, producto, modelo, reactivación).

3. **Actualización de dispositivo:**
   - Puerto de salida `DeviceRepository`: nuevo método `updateDetails(UUID id, String name, UUID siteId)` implementado en `PostgresDeviceRepository` con `UPDATE ... SET name = ?, site_id = ?, name_customized = true, updated_at = now() ... RETURNING`.
   - Puerto de entrada `UpdateDeviceDetails` + caso de uso `UpdateDeviceDetailsService` (valida nombre no vacío, máx. 150 caracteres, sede obligatoria; lanza `DeviceNotFoundException` si el dispositivo no existe).
   - `PUT /api/devices/{id}` en `DeviceController` con body `{name, siteId}` (`@NotBlank @Size(max=150)`, `@NotNull`). Errores: dispositivo inexistente → 404; datos inválidos → 400; sede inexistente (violación de FK) → 400.

4. **Creación de sedes:**
   - Puerto de salida `SiteRepository` + adaptador `PostgresSiteRepository` (`INSERT INTO sites (name, district, province) ... RETURNING` con `device_count = 0`, fechas con offset de Perú igual que las demás vistas).
   - Puerto de entrada `CreateSite` + caso de uso `CreateSiteService` (nombre obligatorio, máx. 150).
   - `POST /api/sites` en `SiteController` con body `{name, district?, province?}` → HTTP 201. Nombre duplicado (índice único case-insensitive `uq_sites_name_ci`) → HTTP 409.
   - Al reasignar sede, distrito/provincia/departamento de las vistas se actualizan solos (provienen del JOIN con `sites`).

5. **Documentación:** README del backend actualizado con ambos endpoints y el comportamiento de `name_customized`.

### Cambios en el frontend

1. **Dominio `Device`** (modificado): se agregó el campo `siteId` (necesario para preseleccionar la sede actual en el diálogo).
2. **Puertos** (nuevos): salida `DeviceRepository` (updateDeviceDetails) y `SiteRepository` (createSite); entrada `GetSites`, `UpdateDeviceDetails` y `CreateSite`, con sus servicios en `usecase/`.
3. **Adaptador HTTP** (modificado): implementa los dos puertos nuevos; el helper `_put` se refactorizó en `_sendJson` genérico con `_putJson` y `_postJson` (acepta 200/201).
4. **UI — página Dispositivos** (`devices_page.dart`, reescrita):
   - Nueva columna **"Acciones"** en la tabla con botón de editar por dispositivo.
   - Diálogo de edición: campo **Nombre** precargado (validado no vacío), dropdown **Sede** que muestra "Nombre (Distrito, Provincia)" y opción **"＋ Nueva sede…"** que despliega campos inline (nombre obligatorio, distrito y provincia opcionales).
   - Al guardar: si se eligió sede nueva, primero la crea (`POST /api/sites`) y luego actualiza el dispositivo (`PUT /api/devices/{id}`) con el `siteId` resultante. Spinner durante el guardado, SnackBar de éxito/error y refresco de la tabla.
5. **Ensamblaje** `main.dart`: servicios `GetSitesService`, `UpdateDeviceDetailsService` y `CreateSiteService` inyectados a `DevicesPage`.

---

## Incidencia resuelta durante las pruebas

Al ejecutar el frontend con `flutter run -d chrome --web-port=3000` fallaba con `SocketException errno 10048` (dirección ya en uso): un proceso `dartvm.exe` (PID 9956) de una ejecución anterior había quedado huérfano escuchando en el puerto 3000. Se identificó con `netstat`/`Get-Process` y se detuvo el proceso, liberando el puerto.

---

## Verificación ejecutada

- **Backend:** `./mvnw.cmd test` — exit 0 tras cada funcionalidad. Incluye:
  - `WhatsAppNotificationAdapterTest` actualizado al nuevo constructor + caso nuevo que verifica que una plantilla personalizada desde el repositorio se renderiza con placeholders.
  - Nuevos: `UpdateNotificationTemplateServiceTest`, `UpdateDeviceDetailsServiceTest`, `CreateSiteServiceTest`.
  - El test de contexto Spring (`FiconPowerApplicationTest`) levanta la aplicación con H2 y aplica las migraciones V4 y V5 sin errores.
- **Frontend:** `flutter analyze` — "No issues found"; `flutter test` — todos los tests pasan (tras cada funcionalidad).

## Inventario de archivos

**Backend — nuevos (16):**
`V4__notification_templates.sql`, `V5__device_custom_names.sql`, `domain/NotificationEventType.java`, `domain/NotificationTemplate.java`, `ports/input/{CreateSite, GetNotificationTemplates, UpdateDeviceDetails, UpdateNotificationTemplate}.java`, `ports/output/{NotificationTemplateRepository, SiteRepository}.java`, `usecase/{CreateSiteService, GetNotificationTemplatesService, UpdateDeviceDetailsService, UpdateNotificationTemplateService}.java`, `adapters/persistence/{PostgresNotificationTemplateRepository, PostgresSiteRepository}.java`, `web/NotificationTemplateController.java`, `test/.../usecase/{CreateSiteServiceTest, UpdateDeviceDetailsServiceTest, UpdateNotificationTemplateServiceTest}.java`

**Backend — modificados (8):**
`README.md`, `WhatsAppNotificationAdapter.java`, `PostgresDeviceRepository.java`, `NotificationConfig.java`, `ports/output/DeviceRepository.java`, `web/DeviceController.java`, `web/SiteController.java`, `test/.../WhatsAppNotificationAdapterTest.java`

**Frontend — nuevos (11):**
`domain/notification_template.dart`, `ports/input/{create_site, get_notification_templates, get_sites, update_device_details, update_notification_template}.dart`, `ports/output/{device_repository, notification_template_repository, site_repository}.dart`, `usecase/{create_site_service, get_notification_templates_service, get_sites_service, update_device_details_service, update_notification_template_service}.dart`

**Frontend — modificados (5):**
`lib/adapters/http/ficon_monitoring_repository.dart`, `lib/domain/device.dart`, `lib/main.dart`, `lib/presentation/pages/dashboard_page.dart`, `lib/presentation/pages/devices_page.dart`

## API REST resultante (todas bajo `X-API-Key` salvo `/`)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Healthcheck público |
| GET | `/api/sites` | Lista sedes |
| POST | `/api/sites` | Crea sede `{name, district?, province?}` → 201 / 409 duplicado |
| GET | `/api/devices` | Lista dispositivos |
| PUT | `/api/devices/{id}` | Edita nombre y sede `{name, siteId}` → 200 / 400 / 404 |
| GET | `/api/incidents?limit=100` | Lista incidentes |
| GET | `/api/events?limit=100` | Lista eventos |
| GET | `/api/notification-templates` | Lista plantillas de mensajes |
| PUT | `/api/notification-templates/{eventType}` | Actualiza mensaje `{body}` → 200 / 400 |

## Trabajo pendiente conversado (fuera del alcance de esta entrega)

- Dockerfile del frontend (servir la build web con nginx) y conexión entre los contenedores de frontend y backend (red Docker).
- Edición de sedes existentes (por ahora solo creación), gestión de técnicos/contactos (el esquema V3 ya los contempla).
- Autenticación de usuarios en el frontend (hoy la seguridad es la API key compartida).

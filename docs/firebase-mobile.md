# Firebase Cloud Messaging en FICON Power

Esta guía configura notificaciones push Android para que las alertas lleguen
aunque la aplicación esté cerrada o fuera de memoria. La integración se divide
en dos credenciales independientes:

- la APK utiliza identificadores públicos del proyecto Firebase;
- el backend utiliza una cuenta de servicio privada para enviar mensajes.

La cuenta de servicio, `.env.mobile`, `.env`, llaves de firma y tokens nunca se
publican en Git.

## Arquitectura

```text
Tuya Message Service
        │
        ▼
Backend FICON ── Firebase Admin/HTTP v1 ──► FCM ──► Android
        ▲                                      │
        │ POST /api/mobile/device-tokens       │ token
        └──────────── APK FICON ◄──────────────┘
```

El frontend inicializa `FirebaseOptions` desde valores inyectados con
`--dart-define`. Por este motivo, el build automatizado no necesita versionar
`google-services.json`; el archivo descargado se usa para extraer los cuatro
identificadores públicos.

## Registrar la aplicación Android

1. Abrir [Firebase Console](https://console.firebase.google.com/).
2. Crear o seleccionar el proyecto destinado a FICON Power.
3. Abrir **Configuración del proyecto > General > Tus apps**.
4. Seleccionar **Agregar app > Android**.
5. Registrar exactamente este package name:

   ```text
   com.devzonesoft.ficon_power_frontend
   ```

6. Descargar `google-services.json`.

Las pantallas de referencia de Firebase muestran primero **Registrar app**,
después **Descargar y agregar el archivo de configuración** y finalmente
**Agregar el SDK de Firebase**. En este repositorio el SDK ya está integrado en
Gradle y `pubspec.yaml`; no se deben repetir manualmente esos cambios.

No se incluyen capturas con identificadores reales para evitar publicar datos
del proyecto. Las capturas internas pueden guardarse fuera de Git y deben
ocultar API key, App ID, Project ID y número de proyecto.

## Extraer los identificadores de la APK

Desde el directorio donde se descargó `google-services.json`:

```bash
python3 - <<'PY'
import json

with open("google-services.json", encoding="utf-8") as source:
    data = json.load(source)

client = next(
    item for item in data["client"]
    if item["client_info"]["android_client_info"]["package_name"]
       == "com.devzonesoft.ficon_power_frontend"
)

print("FIREBASE_API_KEY=" + client["api_key"][0]["current_key"])
print("FIREBASE_APP_ID=" + client["client_info"]["mobilesdk_app_id"])
print("FIREBASE_MESSAGING_SENDER_ID=" + data["project_info"]["project_number"])
print("FIREBASE_PROJECT_ID=" + data["project_info"]["project_id"])
PY
```

`FIREBASE_PROJECT_ID` no es igual a `FIREBASE_APP_ID`:

| Variable | Ejemplo de estructura | Procedencia |
|---|---|---|
| `FIREBASE_API_KEY` | `AIzaSy...` | `current_key` |
| `FIREBASE_APP_ID` | `1:123...:android:abc...` | `mobilesdk_app_id` |
| `FIREBASE_MESSAGING_SENDER_ID` | `123456789012` | `project_number` |
| `FIREBASE_PROJECT_ID` | `ficon-power-prod` | `project_id` |

## Configurar `.env.mobile`

```bash
cd ~/app/ficon-power-frontend
cp .env.mobile.example .env.mobile
nano .env.mobile
```

Contenido:

```env
API_BASE_URL=http://IP_O_DOMINIO:3000
MOBILE_APK_URL=http://IP_O_DOMINIO:3000/mobile/ficon-power.apk
MOBILE_UPDATE_MANIFEST_URL=http://IP_O_DOMINIO:3000/mobile/version.json
FIREBASE_API_KEY=AIzaSy...
FIREBASE_APP_ID=1:123456789012:android:...
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_PROJECT_ID=ficon-power-prod
```

El archivo ya está ignorado por `.gitignore`. Se comprueba con:

```bash
git check-ignore -v .env.mobile
```

## Crear la cuenta de servicio del backend

En Firebase Console:

1. Abrir **Configuración del proyecto > Cuentas de servicio**.
2. Seleccionar **Generar nueva clave privada**.
3. Descargar el JSON una sola vez.
4. Moverlo al directorio privado del backend:

   ```bash
   mkdir -p ~/app/ficon-power-backend/secrets
   chmod 700 ~/app/ficon-power-backend/secrets
   mv firebase-service-account.json \
     ~/app/ficon-power-backend/secrets/firebase-service-account.json
   chmod 600 \
     ~/app/ficon-power-backend/secrets/firebase-service-account.json
   ```

El `docker-compose.yml` monta `../ficon-power-backend/secrets` como
`/app/secrets` en modo de solo lectura. La ruta configurada en el backend debe
ser la ruta **dentro del contenedor**, no la ruta del host.

```env
FCM_ENABLED=true
FCM_PROJECT_ID=ficon-power-prod
FCM_CREDENTIALS_PATH=/app/secrets/firebase-service-account.json
FCM_CREDENTIALS_JSON=
FCM_DRY_RUN=false
```

## Construir la APK con Firebase

```bash
cd ~/app/ficon-power-frontend
set -a
source .env.mobile
set +a
bash scripts/build-mobile-apk.sh
```

La compilación predeterminada es Android `arm64-v8a`. Firebase y el registro de
tokens funcionan igual que en la APK universal. Si una prueba de compatibilidad
falla, se reconstruye el respaldo sin cambiar credenciales:

```bash
ANDROID_APK_VARIANT=universal bash scripts/build-mobile-apk.sh
```

Los valores se inyectan en la variante móvil. No quedan guardados en
`version.json`. El script genera:

```text
dist/mobile/ficon-power.apk
dist/mobile/version.json
```

## Reiniciar los contenedores

```bash
cd ~/app/ficon-power-frontend
docker compose down
docker compose up --build -d
docker compose ps
```

Comprobar la configuración efectiva sin imprimir secretos:

```bash
docker compose exec backend printenv FCM_ENABLED
docker compose exec backend printenv FCM_PROJECT_ID
docker compose exec backend printenv FCM_CREDENTIALS_PATH
docker compose exec backend printenv FCM_DRY_RUN
docker compose exec backend \
  sh -lc 'test -r /app/secrets/firebase-service-account.json && echo legible'
```

## Verificar el registro del teléfono

1. Instalar la APK compilada con `.env.mobile`.
2. Abrirla y aceptar el permiso de notificaciones.
3. Iniciar sesión.
4. Consultar PostgreSQL:

```sql
select user_id, platform, app_version, last_seen_at, revoked_at
from mobile_device_tokens
order by last_seen_at desc;
```

Debe aparecer un token activo con `revoked_at` nulo. El token se registra en:

```http
POST /api/mobile/device-tokens
```

Al cerrar sesión, el backend revoca el registro del dispositivo. Al volver a
iniciar sesión, la APK registra el token vigente nuevamente.

## Verificar una notificación

Se genera un evento real o controlado de corte/retorno y se revisa:

```bash
docker compose logs --since=10m backend \
  | grep -Ei 'firebase|fcm|notification|device token'
```

```sql
select channel, provider, event_type, status, error_code, error_message,
       created_at
from notification_deliveries
order by created_at desc
limit 50;
```

La prueba final debe ejecutarse con la APK visible, en segundo plano y
completamente cerrada. Cuando está visible, la APK escucha
`FirebaseMessaging.onMessage` y vuelve a publicar el mensaje como notificación
local en `fcm_fallback_notification_channel`, con el sonido `power_alarm`. En
segundo plano o cerrada, Android muestra directamente la notificación entregada
por FCM. Los tres escenarios requieren Google Play Services y el permiso de
notificaciones habilitado.

## Diagnóstico

### `mobile_device_tokens` está vacío

- la APK se compiló sin las cuatro variables Firebase;
- se instaló una APK anterior;
- no se inició sesión después de instalar;
- el permiso de notificaciones fue denegado;
- Google Play Services no está disponible;
- `API_BASE_URL` no alcanza al VPS.

### El token existe pero no llega el push

- `FCM_ENABLED` está vacío o en `false`;
- `FCM_PROJECT_ID` no coincide con el proyecto de la APK;
- la cuenta de servicio no es legible dentro del contenedor;
- `FCM_DRY_RUN=true` valida sin entregar;
- el token fue revocado o expiró;
- Firebase devolvió un error registrado en `notification_deliveries`.

### El backend no inicia

```bash
docker compose config
docker compose logs --tail=200 backend
```

Se revisan especialmente montajes con formato `origen:destino:ro`. El destino
requerido para este proyecto es:

```text
/app/secrets/firebase-service-account.json
```

### Seguridad

- No se muestran ni comparten claves privadas, contraseñas o tokens.
- No se agrega `.env.mobile`, `.env`, `google-services.json` ni el JSON de
  cuenta de servicio al repositorio.
- La cuenta de servicio se monta como solo lectura.
- Las API keys públicas de Firebase identifican el proyecto; no sustituyen la
  autorización del backend ni la firma de la cuenta de servicio.

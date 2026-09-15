#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${FCM_PROJECT_ID:-ficon-power}"
SERVICE_ACCOUNT_PATH="${FCM_SERVICE_ACCOUNT_PATH:-}"
TOKEN="${1:-${FCM_DEVICE_TOKEN:-}}"
TITLE="${FCM_TEST_TITLE:-Alarma FICON}"
BODY="${FCM_TEST_BODY:-Prueba directa de corte de energía}"
CHANNEL_ID="${FCM_CHANNEL_ID:-fcm_fallback_notification_channel}"
SOUND="${FCM_SOUND:-power_alarm}"
INCIDENT_ID="${FCM_INCIDENT_ID:-test-direct-fcm}"
SOURCE="${FCM_SOURCE:-manual-vps-test}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -z "${SERVICE_ACCOUNT_PATH}" ]]; then
  if [[ -f "${FRONTEND_DIR}/../ficon-power-backend/secrets/firebase-service-account.json" ]]; then
    SERVICE_ACCOUNT_PATH="${FRONTEND_DIR}/../ficon-power-backend/secrets/firebase-service-account.json"
  elif [[ -f "${FRONTEND_DIR}/../ficon-power-backend/.secrets/firebase-service-account.json" ]]; then
    SERVICE_ACCOUNT_PATH="${FRONTEND_DIR}/../ficon-power-backend/.secrets/firebase-service-account.json"
  else
    SERVICE_ACCOUNT_PATH="${FRONTEND_DIR}/../ficon-power-backend/secrets/firebase-service-account.json"
  fi
fi

if [[ -z "${TOKEN}" ]]; then
  read -r -p "Pega el token FCM completo: " TOKEN
fi

if [[ -z "${TOKEN}" ]]; then
  echo "Error: falta el token FCM." >&2
  echo "Uso: $0 'TOKEN_FCM_COMPLETO'" >&2
  exit 1
fi

if [[ "${TOKEN}" == *"\\"* ]]; then
  echo "Error: el token contiene backslash (\\)." >&2
  echo "Copia el token crudo desde Supabase, sin escapes Markdown." >&2
  exit 1
fi

if [[ "${TOKEN}" == *"["* || "${TOKEN}" == *"]"* || "${TOKEN}" == *"("* || "${TOKEN}" == *")"* ]]; then
  echo "Error: el token parece tener formato Markdown o caracteres extraños." >&2
  echo "Debe ser solo el token FCM crudo." >&2
  exit 1
fi

if [[ ! -f "${SERVICE_ACCOUNT_PATH}" ]]; then
  echo "Error: no existe el service account en:" >&2
  echo "${SERVICE_ACCOUNT_PATH}" >&2
  echo "Puedes indicar otra ruta con FCM_SERVICE_ACCOUNT_PATH=/ruta/firebase-service-account.json" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker no está disponible en este entorno." >&2
  exit 1
fi

SERVICE_ACCOUNT_DIR="$(cd "$(dirname "${SERVICE_ACCOUNT_PATH}")" && pwd)"
SERVICE_ACCOUNT_FILE="$(basename "${SERVICE_ACCOUNT_PATH}")"

echo "Enviando alarma FCM directa..."
echo "Proyecto: ${PROJECT_ID}"
echo "Canal Android: ${CHANNEL_ID}"
echo "Sonido: ${SOUND}"
echo "Token: ${TOKEN:0:12}...${TOKEN: -8}"

docker run --rm \
  -e PROJECT_ID="${PROJECT_ID}" \
  -e TOKEN="${TOKEN}" \
  -e TITLE="${TITLE}" \
  -e BODY="${BODY}" \
  -e CHANNEL_ID="${CHANNEL_ID}" \
  -e SOUND="${SOUND}" \
  -e INCIDENT_ID="${INCIDENT_ID}" \
  -e SOURCE="${SOURCE}" \
  -e SERVICE_ACCOUNT_FILE="${SERVICE_ACCOUNT_FILE}" \
  -v "${SERVICE_ACCOUNT_DIR}:/secrets:ro" \
  gcr.io/google.com/cloudsdktool/google-cloud-cli:slim \
  sh -lc '
    set -eu
    gcloud auth activate-service-account --key-file="/secrets/${SERVICE_ACCOUNT_FILE}" >/dev/null
    ACCESS_TOKEN="$(gcloud auth print-access-token)"

    python3 - "$PROJECT_ID" "$TOKEN" "$TITLE" "$BODY" "$CHANNEL_ID" "$SOUND" "$INCIDENT_ID" "$SOURCE" <<'"'"'PY'"'"' > /tmp/fcm-message.json
import json
import sys

project_id, token, title, body, channel_id, sound, incident_id, source = sys.argv[1:]
payload = {
    "message": {
        "token": token,
        "notification": {
            "title": title,
            "body": body,
        },
        "data": {
            "eventType": "power_outage",
            "incidentId": incident_id,
            "source": source,
        },
        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": channel_id,
                "sound": sound,
                "tag": incident_id,
                "default_vibrate_timings": True,
            },
        },
    },
}
print(json.dumps(payload, ensure_ascii=False))
PY

    curl -sS -X POST "https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      --data-binary @/tmp/fcm-message.json
    echo
  '

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

API_BASE_URL="${API_BASE_URL:-http://179.197.74.30:3000}"
FLUTTER_DOCKER_IMAGE="${FLUTTER_DOCKER_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"
CACHE_DIR="${PROJECT_DIR}/.mobile-build-cache"
LOCAL_UID="$(id -u)"
LOCAL_GID="$(id -g)"
APK_SOURCE="${PROJECT_DIR}/build/app/outputs/flutter-apk/app-release.apk"
APK_TARGET="${PROJECT_DIR}/dist/ficon-power.apk"
MOBILE_DIST_DIR="${PROJECT_DIR}/dist/mobile"
MOBILE_APK_TARGET="${MOBILE_DIST_DIR}/ficon-power.apk"
KEY_PROPERTIES="${PROJECT_DIR}/android/key.properties"
VERSION_LINE="$(grep '^version:' "${PROJECT_DIR}/pubspec.yaml" | awk '{print $2}' | tr -d '\r')"
APP_VERSION_NAME="${VERSION_LINE%%+*}"
APP_VERSION_CODE="${VERSION_LINE##*+}"
API_BASE_URL_CLEAN="${API_BASE_URL%/}"
MOBILE_UPDATE_MANIFEST_URL="${MOBILE_UPDATE_MANIFEST_URL:-${API_BASE_URL_CLEAN}/mobile/version.json}"
MOBILE_APK_URL="${MOBILE_APK_URL:-${API_BASE_URL_CLEAN}/mobile/ficon-power.apk}"
FIREBASE_API_KEY="${FIREBASE_API_KEY:-}"
FIREBASE_APP_ID="${FIREBASE_APP_ID:-}"
FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID:-}"
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-}"

APP_VERSION_NAME="$(printf '%s' "${APP_VERSION_NAME}" | tr -d '\r')"
APP_VERSION_CODE="$(printf '%s' "${APP_VERSION_CODE}" | tr -d '\r')"
API_BASE_URL_CLEAN="$(printf '%s' "${API_BASE_URL_CLEAN}" | tr -d '\r')"
MOBILE_UPDATE_MANIFEST_URL="$(printf '%s' "${MOBILE_UPDATE_MANIFEST_URL}" | tr -d '\r')"
MOBILE_APK_URL="$(printf '%s' "${MOBILE_APK_URL}" | tr -d '\r')"
FIREBASE_API_KEY="$(printf '%s' "${FIREBASE_API_KEY}" | tr -d '\r')"
FIREBASE_APP_ID="$(printf '%s' "${FIREBASE_APP_ID}" | tr -d '\r')"
FIREBASE_MESSAGING_SENDER_ID="$(printf '%s' "${FIREBASE_MESSAGING_SENDER_ID}" | tr -d '\r')"
FIREBASE_PROJECT_ID="$(printf '%s' "${FIREBASE_PROJECT_ID}" | tr -d '\r')"

if [[ ! -f "${KEY_PROPERTIES}" ]]; then
  echo "No existe android/key.properties para firmar actualizaciones."
  echo "Crea la llave local una sola vez con:"
  echo "  ./scripts/generate-mobile-signing-key.sh"
  exit 1
fi

mkdir -p \
  "${CACHE_DIR}/pub" \
  "${CACHE_DIR}/gradle" \
  "${CACHE_DIR}/android-ndk" \
  "${CACHE_DIR}/android-cmake" \
  "${PROJECT_DIR}/dist" \
  "${MOBILE_DIST_DIR}"

# Normaliza ownership de artefactos que pudieron quedar creados por Docker
# como root/nobody en compilaciones anteriores.
docker run --rm \
  -v "${PROJECT_DIR}:/app" \
  alpine:3.20 \
  sh -c "chown -R ${LOCAL_UID}:${LOCAL_GID} /app/.dart_tool /app/.mobile-build-cache /app/build /app/dist 2>/dev/null || true"

# Evita referencias rotas a cachés internas de contenedores anteriores.
rm -rf "${PROJECT_DIR}/.dart_tool"

docker run --rm \
  -v "${PROJECT_DIR}:/app" \
  -v "${CACHE_DIR}/pub:/tmp/pub-cache" \
  -v "${CACHE_DIR}/gradle:/tmp/gradle" \
  -v "${CACHE_DIR}/android-ndk:/opt/android-sdk-linux/ndk" \
  -v "${CACHE_DIR}/android-cmake:/opt/android-sdk-linux/cmake" \
  -e HOME=/tmp/flutter-home \
  -e PUB_CACHE=/tmp/pub-cache \
  -e GRADLE_USER_HOME=/tmp/gradle \
  -w /app \
  "${FLUTTER_DOCKER_IMAGE}" \
  bash -lc "mkdir -p /tmp/flutter-home; git config --global --add safe.directory /sdks/flutter; status=0; flutter pub get && flutter build apk -t lib/main_mobile.dart --release --dart-define=API_BASE_URL='${API_BASE_URL}' --dart-define=APP_VERSION_NAME='${APP_VERSION_NAME}' --dart-define=APP_VERSION_CODE='${APP_VERSION_CODE}' --dart-define=MOBILE_UPDATE_MANIFEST_URL='${MOBILE_UPDATE_MANIFEST_URL}' --dart-define=FIREBASE_API_KEY='${FIREBASE_API_KEY}' --dart-define=FIREBASE_APP_ID='${FIREBASE_APP_ID}' --dart-define=FIREBASE_MESSAGING_SENDER_ID='${FIREBASE_MESSAGING_SENDER_ID}' --dart-define=FIREBASE_PROJECT_ID='${FIREBASE_PROJECT_ID}' || status=\$?; chown -R ${LOCAL_UID}:${LOCAL_GID} /app/.mobile-build-cache /app/.dart_tool /app/build /app/dist 2>/dev/null || true; exit \$status"

cp "${APK_SOURCE}" "${APK_TARGET}"
cp "${APK_SOURCE}" "${MOBILE_APK_TARGET}"

cat >"${MOBILE_DIST_DIR}/version.json" <<EOF
{
  "versionCode": ${APP_VERSION_CODE},
  "versionName": "${APP_VERSION_NAME}",
  "apkUrl": "${MOBILE_APK_URL}",
  "notes": "Actualización de FICON Power",
  "required": false
}
EOF

echo "APK generado: ${APK_TARGET}"
echo "APK publicable: ${MOBILE_APK_TARGET}"
echo "Manifest publicable: ${MOBILE_DIST_DIR}/version.json"

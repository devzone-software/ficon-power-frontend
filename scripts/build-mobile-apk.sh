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
APK_TARGET="${PROJECT_DIR}/dist/ficon-power-beta.apk"

mkdir -p \
  "${CACHE_DIR}/pub" \
  "${CACHE_DIR}/gradle" \
  "${CACHE_DIR}/android-ndk" \
  "${CACHE_DIR}/android-cmake" \
  "${PROJECT_DIR}/dist"

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
  bash -lc "mkdir -p /tmp/flutter-home; git config --global --add safe.directory /sdks/flutter; status=0; flutter pub get && flutter build apk -t lib/main_mobile.dart --release --dart-define=API_BASE_URL='${API_BASE_URL}' || status=\$?; chown -R ${LOCAL_UID}:${LOCAL_GID} /app/.mobile-build-cache /app/.dart_tool /app/build /app/dist 2>/dev/null || true; exit \$status"

cp "${APK_SOURCE}" "${APK_TARGET}"

echo "APK generado: ${APK_TARGET}"

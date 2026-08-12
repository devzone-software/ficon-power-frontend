#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

API_BASE_URL="${API_BASE_URL:-http://179.197.74.30:3000}"
FLUTTER_DOCKER_IMAGE="${FLUTTER_DOCKER_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"
CACHE_DIR="${PROJECT_DIR}/.mobile-build-cache"
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
  -v "${CACHE_DIR}/pub:/root/.pub-cache" \
  -v "${CACHE_DIR}/gradle:/root/.gradle" \
  -v "${CACHE_DIR}/android-ndk:/opt/android-sdk-linux/ndk" \
  -v "${CACHE_DIR}/android-cmake:/opt/android-sdk-linux/cmake" \
  -w /app \
  "${FLUTTER_DOCKER_IMAGE}" \
  bash -lc "flutter pub get && flutter build apk -t lib/main_mobile.dart --release --dart-define=API_BASE_URL='${API_BASE_URL}'"

cp "${APK_SOURCE}" "${APK_TARGET}"

echo "APK generado: ${APK_TARGET}"

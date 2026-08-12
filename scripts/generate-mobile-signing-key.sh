#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANDROID_DIR="${PROJECT_DIR}/android"
KEYSTORE_DIR="${ANDROID_DIR}/keystores"
KEYSTORE_FILE="${KEYSTORE_DIR}/ficon-power-release.jks"
KEY_PROPERTIES="${ANDROID_DIR}/key.properties"
FLUTTER_DOCKER_IMAGE="${FLUTTER_DOCKER_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"
LOCAL_UID="$(id -u)"
LOCAL_GID="$(id -g)"

random_secret() {
  local secret=""
  while [[ ${#secret} -lt 32 ]]; do
    secret="${secret}$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)"
  done
  printf '%s' "${secret:0:32}"
}

if [[ -f "${KEYSTORE_FILE}" || -f "${KEY_PROPERTIES}" ]]; then
  echo "Ya existe configuración de firma móvil:"
  echo "  ${KEYSTORE_FILE}"
  echo "  ${KEY_PROPERTIES}"
  echo "No se sobrescribió nada."
  exit 0
fi

STORE_PASSWORD="${STORE_PASSWORD:-$(random_secret)}"
KEY_PASSWORD="${KEY_PASSWORD:-$(random_secret)}"
KEY_ALIAS="${KEY_ALIAS:-ficon-power}"

mkdir -p "${KEYSTORE_DIR}"

docker run --rm \
  -v "${ANDROID_DIR}:/android" \
  -w /android \
  "${FLUTTER_DOCKER_IMAGE}" \
  keytool -genkeypair \
    -v \
    -keystore "keystores/ficon-power-release.jks" \
    -storetype JKS \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "${KEY_ALIAS}" \
    -storepass "${STORE_PASSWORD}" \
    -keypass "${KEY_PASSWORD}" \
    -dname "CN=FICON Power, OU=Mobile, O=FICON, L=Lima, ST=Lima, C=PE"

cat >"${KEY_PROPERTIES}" <<EOF
storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=keystores/ficon-power-release.jks
EOF

docker run --rm \
  -v "${ANDROID_DIR}:/android" \
  alpine:3.20 \
  sh -c "chown -R ${LOCAL_UID}:${LOCAL_GID} /android/keystores /android/key.properties 2>/dev/null || true"

chmod 600 "${KEY_PROPERTIES}"

echo "Firma móvil creada."
echo "Guarda una copia segura de:"
echo "  ${KEYSTORE_FILE}"
echo "  ${KEY_PROPERTIES}"
echo "Sin esa llave no podrás actualizar encima instalaciones firmadas con ella."

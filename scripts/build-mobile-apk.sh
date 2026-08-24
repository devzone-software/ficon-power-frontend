#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wrapper estable para conservar el comando histórico. La implementación
# específica de plataforma vive en scripts/mobile/android.
exec bash "${SCRIPT_DIR}/mobile/android/build-apk.sh" "$@"

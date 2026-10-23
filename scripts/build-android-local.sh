#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Do not load production dotenv files or invoke main_mobile.dart.
flutter pub get
flutter test test/local_engine_test.dart
flutter build apk --release -t lib/main.dart --target-platform android-arm64
mkdir -p dist/mobile
cp build/app/outputs/flutter-apk/app-release.apk dist/mobile/ficon-power.apk

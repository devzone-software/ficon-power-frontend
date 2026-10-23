#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Do not load production dotenv files or invoke main_mobile.dart.
flutter pub get
# flutter pub get (not dart pub get) generates the native/JNI registrations.
# A build without them compiles but fails before the login screen can open.
registrant=android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
test -s "$registrant"
grep -q 'JniFlutterPlugin' "$registrant"
flutter test test/local_engine_test.dart
flutter test test/local_startup_test.dart
flutter build apk --release -t lib/main.dart --target-platform android-arm64
# Verify the actual package, not just Gradle's successful exit status.
unzip -Z -1 build/app/outputs/flutter-apk/app-release.apk | grep -Fx 'lib/arm64-v8a/libdartjni.so'
mkdir -p dist/mobile
cp build/app/outputs/flutter-apk/app-release.apk dist/mobile/ficon-power.apk

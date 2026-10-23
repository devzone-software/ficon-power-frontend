/// Configuración de la aplicación leída en tiempo de compilación.
///
/// Los valores se inyectan con `--dart-define`, por ejemplo:
/// ```bash
/// flutter run -d chrome \
///   --dart-define=API_BASE_URL=http://localhost:8080 \
///   --dart-define=API_KEY=mi-clave
/// ```
class AppConfig {
  AppConfig._();

  /// URL base del backend FICON Power.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://local.ficon',
  );

  /// Clave para el header `X-API-Key`. Vacía si el backend no la exige.
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  /// Código de versión móvil inyectado por el script de build.
  static const int appVersionCode = int.fromEnvironment(
    'APP_VERSION_CODE',
    defaultValue: 3,
  );

  /// Nombre de versión móvil inyectado por el script de build.
  static const String appVersionName = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '1.0.2',
  );

  /// URL del manifiesto de actualización móvil.
  static const String mobileUpdateManifestUrl = String.fromEnvironment(
    'MOBILE_UPDATE_MANIFEST_URL',
    defaultValue: '',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  /// Datos privados de acceso a Tuya Spatial para la guía móvil.
  /// Se inyectan desde `.env.mobile` durante la compilación.
  static const String _tuyaSpatialProjectQrOverride = String.fromEnvironment(
    'TUYA_SPATIAL_PROJECT_QR_DATA',
    defaultValue: '',
  );

  /// La copia autónoma no contiene el QR del proyecto real.
  static const String tuyaSpatialProjectQrData = _tuyaSpatialProjectQrOverride;

  static const String tuyaSpatialAccount = String.fromEnvironment(
    'TUYA_SPATIAL_ACCOUNT',
    defaultValue: '',
  );

  static const String tuyaSpatialPassword = String.fromEnvironment(
    'TUYA_SPATIAL_PASSWORD',
    defaultValue: '',
  );

  static bool get tuyaSpatialGuideConfigured =>
      tuyaSpatialProjectQrData.isNotEmpty &&
      tuyaSpatialAccount.isNotEmpty &&
      tuyaSpatialPassword.isNotEmpty;

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}

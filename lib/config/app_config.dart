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
    defaultValue: 'http://localhost:8080',
  );

  /// Clave para el header `X-API-Key`. Vacía si el backend no la exige.
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  /// Código de versión móvil inyectado por el script de build.
  static const int appVersionCode = int.fromEnvironment(
    'APP_VERSION_CODE',
    defaultValue: 1,
  );

  /// Nombre de versión móvil inyectado por el script de build.
  static const String appVersionName = String.fromEnvironment(
    'APP_VERSION_NAME',
    defaultValue: '0.1.0',
  );

  /// URL del manifiesto de actualización móvil.
  static const String mobileUpdateManifestUrl = String.fromEnvironment(
    'MOBILE_UPDATE_MANIFEST_URL',
    defaultValue: '',
  );
}

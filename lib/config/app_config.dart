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
}

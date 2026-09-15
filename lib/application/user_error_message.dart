import '../adapters/http/exception_handler.dart';

class UserErrorMessage {
  const UserErrorMessage._();

  static String from(Object? error) {
    if (error == null) {
      return 'Ocurrió un error inesperado. Inténtalo nuevamente.';
    }
    return ExceptionHandler.fromException(error);
  }

  static String forAction(String action, Object? error) =>
      '$action: ${from(error)}';
}

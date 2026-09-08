import 'package:ficon_power_frontend/adapters/http/ficon_api_client.dart';
import 'package:ficon_power_frontend/application/user_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('muestra mensajes controlados y la referencia del backend', () {
    final message = UserErrorMessage.from(
      ApiException(
        'El servidor no pudo completar la operación.',
        statusCode: 500,
        traceId: 'trace-456',
      ),
    );

    expect(
      message,
      'El servidor no pudo completar la operación.\nReferencia: trace-456',
    );
  });

  test('oculta excepciones técnicas desconocidas', () {
    final message = UserErrorMessage.from(Exception('database password'));

    expect(message, 'Ocurrió un error inesperado. Inténtalo nuevamente.');
    expect(message, isNot(contains('database password')));
  });

  test('traduce fallos comunes de conectividad', () {
    expect(
      UserErrorMessage.from(Exception('SocketException: connection refused')),
      'No se pudo conectar con el servidor. Revisa tu conexión a Internet.',
    );
    expect(
      UserErrorMessage.from(Exception('TimeoutException after 15 seconds')),
      'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
    );
  });
}

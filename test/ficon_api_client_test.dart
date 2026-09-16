import 'dart:convert';

import 'package:ficon_power_frontend/adapters/http/ficon_api_client.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('decodifica eventos SSE aunque los datos tengan varias líneas', () async {
    final session = AuthSession()
      ..start(
        token: 'stream-token',
        user: const AuthUser(
          id: 'user-1',
          username: 'reader',
          role: 'USER',
          displayName: 'Reader',
        ),
      );
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      session: session,
      client: MockClient((request) async {
        expect(request.url.path, '/api/realtime/stream');
        expect(request.headers['authorization'], 'Bearer stream-token');
        expect(request.headers['accept'], 'text/event-stream');
        return http.Response(
          'id: 12\nevent: device.updated\ndata: {"id":12,\ndata: "entityType":"device"}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );

    final event = await client.getEventStream('/api/realtime/stream').first;

    expect(event.id, '12');
    expect(event.event, 'device.updated');
    expect(event.data, '{"id":12,\n"entityType":"device"}');
  });

  test('envía el token de sesión y decodifica listas', () async {
    final session = AuthSession()
      ..start(
        token: 'session-token',
        user: const AuthUser(
          id: 'user-1',
          username: 'admin',
          role: 'ADMIN',
          displayName: 'Admin',
        ),
      );
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      session: session,
      client: MockClient((request) async {
        expect(request.url.path, '/api/devices');
        expect(request.headers['authorization'], 'Bearer session-token');
        return http.Response(
          jsonEncode([
            {'id': 'device-1'},
          ]),
          200,
        );
      }),
    );

    final result = await client.getList('/api/devices');

    expect(result.single['id'], 'device-1');
  });

  test('login sin autenticar no envía bearer', () async {
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      client: MockClient((request) async {
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(jsonEncode({'token': 'new-token'}), 200);
      }),
    );

    final result = await client.postJson('/api/auth/login', {
      'username': 'admin',
      'password': 'secret',
    }, authenticated: false);

    expect(result['token'], 'new-token');
  });

  test('conserva el mensaje de error enviado por el backend', () async {
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Acceso denegado'}), 403),
      ),
    );

    await expectLater(
      client.getList('/api/users'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.message, 'message', 'Acceso denegado'),
      ),
    );
  });

  test('traduce validaciones técnicas del backend', () async {
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail':
                'Validation failed for field password: size must be between 8 and 120',
          }),
          400,
        ),
      ),
    );

    await expectLater(
      client.getJson('/api/users'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'La contraseña debe tener entre 8 y 120 caracteres.',
        ),
      ),
    );
  });

  test('lee el contrato uniforme de error y conserva su referencia', () async {
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'validation_error',
            'message': 'Revisa los datos indicados.',
            'fieldErrors': [
              {
                'field': 'displayName',
                'message': 'El nombre visible es obligatorio.',
              },
            ],
            'traceId': 'request-123',
          }),
          400,
        ),
      ),
    );

    await expectLater(
      client.getJson('/api/users'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              'El nombre visible es obligatorio.',
            )
            .having((error) => error.code, 'code', 'validation_error')
            .having((error) => error.traceId, 'traceId', 'request-123'),
      ),
    );
  });

  test('los errores de conexión no exponen URL ni excepción técnica', () async {
    final client = FiconApiClient(
      baseUrl: 'https://internal.example:8443',
      client: MockClient((_) async => throw http.ClientException('socket')),
    );

    await expectLater(
      client.getJson('/api/devices'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              'No se pudo conectar con el servidor. '
                  'Revisa tu conexión a Internet.',
            )
            .having(
              (error) => error.message,
              'does not expose URL',
              isNot(contains('internal.example')),
            ),
      ),
    );
  });

  test(
    'renueva la sesión y reintenta la petición con el token nuevo',
    () async {
      final session = AuthSession()
        ..start(
          token: 'expired-access-token',
          refreshToken: 'refresh-token',
          refreshExpiresAt: DateTime.utc(2026, 12, 1),
          user: const AuthUser(
            id: 'user-1',
            username: 'admin',
            role: 'ADMIN',
            displayName: 'Admin',
          ),
        );
      var deviceRequests = 0;
      final client = FiconApiClient(
        baseUrl: 'https://ficon.test',
        session: session,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/refresh') {
            expect(jsonDecode(request.body)['refreshToken'], 'refresh-token');
            return http.Response(
              jsonEncode({
                'token': 'renewed-access-token',
                'expiresAt': '2026-08-25T12:00:00Z',
                'refreshToken': 'rotated-refresh-token',
                'refreshExpiresAt': '2026-11-23T12:00:00Z',
                'user': {
                  'id': 'user-1',
                  'username': 'admin',
                  'role': 'ADMIN',
                  'displayName': 'Admin actualizado',
                  'email': 'admin@ficon.test',
                  'whatsappPhone': '+51987654321',
                },
              }),
              200,
            );
          }
          expect(request.url.path, '/api/devices');
          deviceRequests++;
          if (deviceRequests == 1) {
            expect(
              request.headers['authorization'],
              'Bearer expired-access-token',
            );
            return http.Response('', 401);
          }
          expect(
            request.headers['authorization'],
            'Bearer renewed-access-token',
          );
          return http.Response(jsonEncode(<Object>[]), 200);
        }),
      );

      expect(await client.getList('/api/devices'), isEmpty);
      expect(deviceRequests, 2);
      expect(session.token, 'renewed-access-token');
      expect(session.refreshToken, 'rotated-refresh-token');
      expect(session.user?.displayName, 'Admin actualizado');
      expect(session.user?.email, 'admin@ficon.test');
      expect(session.user?.whatsappPhone, '+51987654321');
    },
  );

  test('limpia la sesión cuando el refresh token fue revocado', () async {
    final session = AuthSession()
      ..start(
        token: 'expired-access-token',
        refreshToken: 'revoked-refresh-token',
        user: const AuthUser(
          id: 'user-1',
          username: 'admin',
          role: 'ADMIN',
          displayName: 'Admin',
        ),
      );
    final client = FiconApiClient(
      baseUrl: 'https://ficon.test',
      session: session,
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          return http.Response(jsonEncode({'error': 'Sesión revocada'}), 401);
        }
        return http.Response('', 401);
      }),
    );

    await expectLater(
      client.getList('/api/devices'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(session.isAuthenticated, isFalse);
    expect(session.refreshToken, isNull);
  });
}

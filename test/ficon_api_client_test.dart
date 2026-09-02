import 'dart:convert';

import 'package:ficon_power_frontend/adapters/http/ficon_api_client.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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

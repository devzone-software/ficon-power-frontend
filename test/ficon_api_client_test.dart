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
}

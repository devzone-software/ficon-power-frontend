import 'dart:convert';

import 'package:ficon_power_frontend/adapters/http/ficon_monitoring_repository.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('incluye el token FCM al cerrar la sesión móvil', () async {
    final session = AuthSession()
      ..start(
        token: 'access-token',
        refreshToken: 'refresh-token',
        user: const AuthUser(
          id: 'user-1',
          username: 'technician',
          role: 'USER',
          displayName: 'Técnico',
        ),
      );
    late Map<String, dynamic> logoutPayload;
    final repository = FiconMonitoringRepository(
      baseUrl: 'https://ficon.test',
      session: session,
      client: MockClient((request) async {
        if (request.url.path == '/api/mobile/device-tokens') {
          return http.Response(
            jsonEncode({
              'id': 'token-id',
              'userId': 'user-1',
              'platform': 'android',
              'lastSeenAt': '2026-09-04T12:00:00Z',
            }),
            200,
          );
        }
        expect(request.url.path, '/api/auth/logout');
        logoutPayload = (jsonDecode(request.body) as Map).cast<String, dynamic>();
        return http.Response('', 200);
      }),
    );

    await repository.registerMobilePushToken(
      token: 'fcm-token',
      platform: 'android',
      appVersion: '0.1.4',
    );
    await repository.logout();

    expect(logoutPayload['refreshToken'], 'refresh-token');
    expect(logoutPayload['deviceToken'], 'fcm-token');
  });
}

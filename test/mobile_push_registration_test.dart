import 'dart:async';
import 'dart:convert';

import 'package:ficon_power_frontend/adapters/http/ficon_monitoring_repository.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:ficon_power_frontend/mobile/notifications/mobile_push_registration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('reintenta el registro FCM después de un fallo transitorio', (
    tester,
  ) async {
    final session = _authenticatedSession();
    var attempts = 0;
    MobilePushStatus? status;

    await tester.pumpWidget(
      MaterialApp(
        home: MobilePushRegistration(
          session: session,
          repository: FiconMonitoringRepository(session: session),
          retryDelays: const [Duration(milliseconds: 10)],
          requestPermission: () async => AuthorizationStatus.authorized,
          loadToken: () async => 'fcm-token-12345678',
          tokenRefreshes: const Stream.empty(),
          registerToken: (_) async {
            attempts++;
            if (attempts == 1) throw Exception('sin red');
          },
          child: Builder(
            builder: (context) {
              status = MobilePushStatusScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(attempts, 1);
    expect(status?.phase, MobilePushPhase.retrying);
    expect(status?.lastError, contains('sin red'));

    await tester.pump(const Duration(milliseconds: 11));
    await tester.pump();

    expect(attempts, 2);
    expect(status?.phase, MobilePushPhase.registered);
    expect(status?.tokenHint, '••••12345678');
    expect(status?.lastError, isNull);
  });

  test('solicita una prueba dirigida al token actual', () async {
    final session = _authenticatedSession();
    final repository = FiconMonitoringRepository(
      baseUrl: 'https://ficon.test',
      session: session,
      client: MockClient((request) async {
        expect(request.url.path, '/api/mobile/device-tokens/test');
        expect(jsonDecode(request.body), {'token': 'current-token'});
        return http.Response(
          jsonEncode({
            'configured': true,
            'tokenRegistered': true,
            'accepted': true,
            'message': 'Firebase aceptó la notificación de prueba.',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.sendMobilePushTest('current-token');

    expect(result.configured, isTrue);
    expect(result.tokenRegistered, isTrue);
    expect(result.accepted, isTrue);
  });
}

AuthSession _authenticatedSession() => AuthSession()
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

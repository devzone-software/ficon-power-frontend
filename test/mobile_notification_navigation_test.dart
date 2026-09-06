import 'dart:async';

import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:ficon_power_frontend/mobile/notifications/mobile_notification_navigation.dart';
import 'package:ficon_power_frontend/presentation/navigation/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(
  id: 'user-1',
  username: 'operator',
  role: 'USER',
  displayName: 'Operator',
);

void main() {
  test('prioriza el incidente y admite alias de payload', () {
    final incident = MobileNotificationDestination.fromData(const {
      'incident_id': ' incident-1 ',
      'deviceId': 'device-1',
    });
    final device = MobileNotificationDestination.fromData(const {
      'device_id': ' device-2 ',
    });

    expect(incident?.route, AppRoutes.incidents);
    expect(incident?.incidentId, 'incident-1');
    expect(device?.route, AppRoutes.devices);
    expect(device?.deviceId, 'device-2');
    expect(
      MobileNotificationDestination.fromLocalPayload(
        'incident:incident-3',
      )?.incidentId,
      'incident-3',
    );
  });

  testWidgets('abre el incidente al tocar una notificación en segundo plano', (
    tester,
  ) async {
    final messages = StreamController<RemoteMessage>();
    final session = AuthSession()..start(token: 'token', user: _user);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      _testApp(
        session: session,
        navigatorKey: navigatorKey,
        openedMessages: messages.stream,
      ),
    );
    messages.add(
      const RemoteMessage(
        messageId: 'opened-1',
        data: {'incidentId': 'incident-7'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('incident:incident-7'), findsOneWidget);
    await messages.close();
  });

  testWidgets('conserva el destino inicial hasta que exista una sesión', (
    tester,
  ) async {
    final session = AuthSession();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      _testApp(
        session: session,
        navigatorKey: navigatorKey,
        initialMessage: () async => const RemoteMessage(
          messageId: 'initial-1',
          data: {'deviceId': 'device-4'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);

    session.start(token: 'token', user: _user);
    await tester.pumpAndSettle();

    expect(find.text('device:device-4'), findsOneWidget);
  });

  testWidgets('recupera una notificación local que inició la aplicación', (
    tester,
  ) async {
    final session = AuthSession()..start(token: 'token', user: _user);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      _testApp(
        session: session,
        navigatorKey: navigatorKey,
        initialLocalPayload: () async => 'incident:incident-local',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('incident:incident-local'), findsOneWidget);
  });
}

Widget _testApp({
  required AuthSession session,
  required GlobalKey<NavigatorState> navigatorKey,
  Stream<RemoteMessage>? openedMessages,
  Future<RemoteMessage?> Function()? initialMessage,
  Future<String?> Function()? initialLocalPayload,
}) {
  return MobileNotificationNavigation(
    navigatorKey: navigatorKey,
    session: session,
    openedMessages: openedMessages ?? const Stream<RemoteMessage>.empty(),
    initialMessage: initialMessage ?? () async => null,
    initialLocalPayload: initialLocalPayload,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: const Text('inicio'),
      routes: {
        AppRoutes.incidents: (context) {
          final target =
              ModalRoute.of(context)!.settings.arguments
                  as MobileNotificationDestination;
          return Text('incident:${target.incidentId}');
        },
        AppRoutes.devices: (context) {
          final target =
              ModalRoute.of(context)!.settings.arguments
                  as MobileNotificationDestination;
          return Text('device:${target.deviceId}');
        },
      },
    ),
  );
}

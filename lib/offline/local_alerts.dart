import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/auth_session.dart';
import 'local_engine.dart';

class LocalAlerts {
  LocalAlerts(this.engine, this.session, this.onOpen);
  final void Function(Map<String, dynamic>) onOpen;
  final LocalEngine engine;
  final AuthSession session;
  final plugin = FlutterLocalNotificationsPlugin();
  final Set<String> _seen = {};
  StreamSubscription<Row>? _subscription;

  Future<void> start() async {
    if (!Platform.isAndroid && !Platform.isWindows) return;
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          windows: WindowsInitializationSettings(
            appName: 'FICON Power',
            appUserModelId: 'Ficon.Power.Local.1',
            guid: '0d218a21-3c36-449c-8abb-cbb03a01b05e',
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) {
            onOpen((jsonDecode(payload) as Map).cast<String, dynamic>());
          }
        },
      );
      final launch = await plugin.getNotificationAppLaunchDetails();
      final launchPayload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && launchPayload != null) {
        onOpen((jsonDecode(launchPayload) as Map).cast<String, dynamic>());
      }
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _seen.addAll(engine.rows('notifications').map((n) => n['id'] as String));
      _subscription = engine.changes.stream
          .where((e) => e['entityType'] == 'notification')
          .listen((_) => unawaited(_showNew()));
    } catch (error) {
      // The persistent notification inbox remains available without OS permission.
      debugPrint('Notificaciones del sistema no disponibles: $error');
    }
  }

  Future<void> _showNew() async {
    final pending = engine
        .rows('notifications')
        .where(
          (n) => n['userId'] == session.user?.id && !_seen.contains(n['id']),
        )
        .toList();
    for (final notification in pending) {
      _seen.add(notification['id']);
      try {
        await plugin.show(
          id: notification['id'].hashCode & 0x7fffffff,
          title: notification['title'],
          body: notification['body'],
          payload: jsonEncode(notification['data']),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'ficon_local_power',
              'Alertas de energía',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('power_alarm'),
            ),
            windows: WindowsNotificationDetails(),
          ),
        );
      } catch (error) {
        debugPrint('No se pudo mostrar la alerta: $error');
      }
    }
  }

  Future<void> dispose() async => _subscription?.cancel();
}

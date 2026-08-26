import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'config/auth_session.dart';
import 'main.dart';
import 'mobile/config/mobile_firebase_config.dart';
import 'mobile/notifications/mobile_event_notification_watcher.dart';
import 'mobile/notifications/mobile_power_alert_channel.dart';
import 'mobile/notifications/mobile_push_registration.dart';
import 'mobile/session/mobile_session_storage.dart';
import 'mobile/updates/mobile_update_checker.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (MobileFirebaseConfig.isConfigured && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: MobileFirebaseConfig.options);
  }
}

/// Entrypoint de la app móvil interna.
///
/// Reutiliza los casos de uso, repositorio HTTP y pantallas actuales, pero
/// permite compilar una variante móvil sin afectar la entrada web.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (MobileFirebaseConfig.isConfigured) {
    await Firebase.initializeApp(options: MobileFirebaseConfig.options);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await MobilePowerAlertChannel().ensureCreated();
  }

  final session = AuthSession();
  final sessionStorage = MobileSessionStorage();
  await sessionStorage.restoreInto(session);
  session.addListener(() => unawaited(sessionStorage.save(session)));

  final repository = FiconMonitoringRepository(session: session);
  final navigatorKey = GlobalKey<NavigatorState>();
  final app = MobilePushRegistration(
    repository: repository,
    session: session,
    child: FiconPowerApp(
      repository: repository,
      session: session,
      navigatorKey: navigatorKey,
      title: 'FICON Power',
      showBetaBanner: false,
    ),
  );
  runApp(
    MobileUpdateChecker(
      session: session,
      navigatorKey: navigatorKey,
      child: MobileFirebaseConfig.isConfigured
          ? app
          : MobileEventNotificationWatcher(
              repository: repository,
              session: session,
              child: app,
            ),
    ),
  );
}

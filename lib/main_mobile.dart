import 'dart:async';

import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'config/auth_session.dart';
import 'main.dart';
import 'mobile/mobile_event_notification_watcher.dart';
import 'mobile/mobile_session_storage.dart';

/// Entrypoint de la app móvil beta interna.
///
/// Reutiliza los casos de uso, repositorio HTTP y pantallas actuales, pero
/// permite compilar una variante móvil con marca beta visible. Las siguientes
/// iteraciones deben priorizar UI móvil dedicada y notificaciones push.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = AuthSession();
  final sessionStorage = MobileSessionStorage();
  await sessionStorage.restoreInto(session);
  session.addListener(() => unawaited(sessionStorage.save(session)));

  final repository = FiconMonitoringRepository(session: session);
  runApp(
    MobileEventNotificationWatcher(
      repository: repository,
      session: session,
      child: FiconPowerApp(
        repository: repository,
        session: session,
        title: 'FICON Power Beta',
        showBetaBanner: false,
      ),
    ),
  );
}

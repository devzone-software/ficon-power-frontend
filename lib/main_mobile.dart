import 'dart:async';

import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'config/auth_session.dart';
import 'main.dart';
import 'mobile/mobile_event_notification_watcher.dart';
import 'mobile/mobile_session_storage.dart';
import 'mobile/mobile_update_checker.dart';

/// Entrypoint de la app móvil interna.
///
/// Reutiliza los casos de uso, repositorio HTTP y pantallas actuales, pero
/// permite compilar una variante móvil sin afectar la entrada web.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = AuthSession();
  final sessionStorage = MobileSessionStorage();
  await sessionStorage.restoreInto(session);
  session.addListener(() => unawaited(sessionStorage.save(session)));

  final repository = FiconMonitoringRepository(session: session);
  runApp(
    MobileUpdateChecker(
      session: session,
      child: MobileEventNotificationWatcher(
        repository: repository,
        session: session,
        child: FiconPowerApp(
          repository: repository,
          session: session,
          title: 'FICON Power',
          showBetaBanner: false,
        ),
      ),
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ficon_power_frontend/main.dart';
import 'package:ficon_power_frontend/offline/local_engine.dart';
import 'package:ficon_power_frontend/offline/local_console.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/adapters/http/ficon_monitoring_repository.dart';

void main() {
  testWidgets(
    'mobile shell opens operations and records a power loss locally',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Directory directory;
      late LocalEngine engine;
      late FiconMonitoringRepository repository;
      final session = AuthSession();
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('ficon-ui-test-');
        engine = await LocalEngine.open(directory.path);
        repository = FiconMonitoringRepository(
          client: LocalClient(engine),
          baseUrl: 'http://local.ficon',
          session: session,
        );
        final login = await repository.login(
          username: 'superadmin',
          password: '1234',
        );
        session.start(token: login.token, user: login.user);
      });
      LocalConsole.engine = engine;
      LocalConsole.session = session;
      await tester.pumpWidget(
        FiconPowerApp(repository: repository, session: session),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Operaciones'), findsOneWidget);
      await tester.tap(find.byTooltip('Operaciones'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Control de energía'), findsOneWidget);
      expect(
        find.text('Registrar corte'),
        findsWidgets,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      await tester.tap(find.text('Registrar corte').first);
      // File writes complete on the real event loop; drain each continuation
      // before advancing the widget test's fake clock again.
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        if (find.text('Restaurar energía').evaluate().isNotEmpty &&
            find.byType(LinearProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }
      expect(find.text('Restaurar energía'), findsOneWidget);
      expect(
        engine.rows('incidents').where((i) => i['status'] == 'active'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      repository.dispose();
      await tester.runAsync(() async {
        await engine.changes.close();
        await directory.delete(recursive: true);
      });
    },
  );
}

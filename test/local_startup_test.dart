import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ficon_power_frontend/main.dart';

void main() {
  testWidgets('renders a visible loading screen before native initialization', (
    tester,
  ) async {
    final application = Completer<Widget>();
    await tester.pumpWidget(LocalStartup(initialize: () => application.future));
    expect(find.text('Abriendo FICON Power…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    application.complete(
      const MaterialApp(home: Scaffold(body: Text('Login listo'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login listo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing native plugin shows a recoverable error instead of a blank screen',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        LocalStartup(
          initialize: () async {
        if (attempts++ == 0) {
              throw MissingPluginException('native storage unavailable');
        }
            return const MaterialApp(home: Scaffold(body: Text('Login listo')));
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se pudo iniciar FICON Power.'), findsOneWidget);
      expect(find.textContaining('No se borraron tus datos.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Login listo'), findsOneWidget);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}

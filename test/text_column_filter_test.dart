import 'package:ficon_power_frontend/presentation/theme/ficon_theme.dart';
import 'package:ficon_power_frontend/presentation/widgets/table_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra sugerencias coincidentes mientras se escribe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFiconTheme(),
        home: Scaffold(
          body: TextColumnFilter(
            label: 'Buscar medidor',
            value: '',
            options: const ['Medidor 1', 'Sede Miraflores', 'Sede Surco'],
            wideOnMobile: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'mira');
    await tester.pump();

    expect(find.text('Sugerencias'), findsOneWidget);
    expect(find.text('Sede Miraflores'), findsOneWidget);
    expect(find.text('Sede Surco'), findsNothing);
  });
}

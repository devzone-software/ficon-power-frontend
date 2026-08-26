import 'package:ficon_power_frontend/presentation/widgets/table_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite una sola opción y la segunda pulsación la limpia', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var value = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ChoiceColumnFilter(
              label: 'Estado',
              value: value,
              options: const ['En línea', 'Fuera de línea'],
              labels: const {'En línea': 'Online', 'Fuera de línea': 'Offline'},
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Online'));
    await tester.pump();
    expect(value, 'En línea');

    await tester.tap(find.text('Offline'));
    await tester.pump();
    expect(value, 'Fuera de línea');

    await tester.tap(find.text('Offline'));
    await tester.pump();
    expect(value, isEmpty);
  });
}

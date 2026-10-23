import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ficon_power_frontend/application/chart_date_label.dart';
import 'package:ficon_power_frontend/application/dashboard_statistics.dart';
import 'package:ficon_power_frontend/presentation/dashboard/frequency_bar_chart.dart';

void main() {
  test('daily labels omit year/time and pad day and month', () {
    expect(compactDailyChartLabel('2026-10-23'), '23/10');
    expect(compactDailyChartLabel('2026-10-23T08:30:00'), '23/10');
    expect(compactDailyChartLabel('3/1'), '03/01');
    expect(compactDailyChartLabel('Lun'), 'Lun');
  });

  for (final width in [320.0, 1024.0]) {
    testWidgets('daily dates stay on one horizontal line at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FrequencyBarChart(
              title: 'Últimos 7 días',
              subtitle: 'Cortes diarios',
              icon: Icons.bar_chart,
              color: Colors.blue,
              compactDates: true,
              points: List.generate(
                7,
                (i) => FrequencyPoint(label: '2026-10-${17 + i}', count: i),
              ),
            ),
          ),
        ),
      );
      for (var day = 17; day <= 23; day++) {
        final label = tester.widget<Text>(find.text('$day/10'));
        expect(label.maxLines, 1);
        expect(label.softWrap, false);
      }
      expect(find.text('2026-10-23'), findsNothing);
      expect(find.byTooltip('2026-10-23: 6 cortes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

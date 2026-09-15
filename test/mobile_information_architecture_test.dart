import 'package:ficon_power_frontend/domain/device.dart';
import 'package:ficon_power_frontend/presentation/devices/device_compact_card.dart';
import 'package:ficon_power_frontend/presentation/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la navegación móvil conserva solo resumen, dispositivos y admin', () {
    expect(mobileNavRoutes, {
      AppRoutes.dashboard,
      AppRoutes.devices,
      AppRoutes.admin,
    });
    expect(mobileNavRoutes, isNot(contains(AppRoutes.incidents)));
    expect(mobileNavRoutes, isNot(contains(AppRoutes.events)));
    expect(mobileNavRoutes, isNot(contains(AppRoutes.calendar)));
  });

  testWidgets('la tarjeta móvil solo muestra nombre, distrito y estado', (
    tester,
  ) async {
    const device = Device(
      id: 'device-1',
      externalId: 'tuya-secret-id',
      name: 'Medidor Alto Puno',
      district: 'Puno',
      category: 'dlq',
      model: 'RPE1',
      active: true,
      status: 'online',
      eventCount: 24,
      incidentCount: 5,
      totalDowntimeSeconds: 3600,
    );
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceCompactCard(device: device, onOpen: (_) => opened = true),
        ),
      ),
    );

    expect(find.text('Medidor Alto Puno'), findsOneWidget);
    expect(find.text('Puno'), findsOneWidget);
    expect(find.text('En línea'), findsOneWidget);
    expect(find.text('tuya-secret-id'), findsNothing);
    expect(find.text('dlq'), findsNothing);
    expect(find.text('RPE1'), findsNothing);
    expect(find.text('24'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.tap(find.byType(DeviceCompactCard));
    expect(opened, isTrue);
  });
}

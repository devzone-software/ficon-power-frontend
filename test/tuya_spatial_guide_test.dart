import 'package:ficon_power_frontend/presentation/devices/onboarding/tuya_spatial_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guía disponible sin servicios ni credenciales externos', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TuyaSpatialGuidePage()));
    expect(find.text('Guía de dispositivos'), findsOneWidget);
    expect(find.text('1. Agregar un dispositivo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('7. Exportar y conservar'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('7. Exportar y conservar'), findsOneWidget);
    expect(find.textContaining('no se envían mensajes reales'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:ficon_power_frontend/presentation/devices/onboarding/tuya_spatial_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('muestra el flujo y mantiene oculta la contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TuyaSpatialGuidePage(
          projectQrData: 'https://example.com/project',
          account: 'usuario-autorizado',
          password: 'clave-privada-visible-solo-al-copiar',
        ),
      ),
    );

    expect(find.text('1. Descargar Smart Industry'), findsOneWidget);
    expect(find.text('Descargar APK internacional'), findsOneWidget);
    expect(find.text('Abrir Google Play'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('2. Escanear el QR del proyecto'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2. Escanear el QR del proyecto'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3. Iniciar sesión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('3. Iniciar sesión'), findsOneWidget);
    expect(find.text('usuario-autorizado'), findsOneWidget);
    expect(find.text('••••••••••••'), findsOneWidget);
    expect(find.text('clave-privada-visible-solo-al-copiar'), findsNothing);
    expect(find.byIcon(Icons.copy_outlined), findsNWidgets(2));
    expect(find.textContaining('Figura 6.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('10. Verificar el resultado'),
      900,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('10. Verificar el resultado'), findsOneWidget);
    expect(find.textContaining('Figura 13.'), findsOneWidget);
  });

  testWidgets('avisa cuando faltan datos privados de compilación', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TuyaSpatialGuidePage()));

    await tester.scrollUntilVisible(
      find.byType(QrImageView),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    final projectUri = Uri.parse(
      tester
          .widget<TuyaSpatialGuidePage>(find.byType(TuyaSpatialGuidePage))
          .projectQrData,
    );
    expect(projectUri.host, 'smartapp.tuya.com');
    expect(projectUri.path, '/tyIndustry');
    expect(projectUri.queryParameters['t'], '1792161730208');
    expect(find.textContaining('TUYA_SPATIAL_PROJECT_QR_DATA'), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('TUYA_SPATIAL_ACCOUNT'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('TUYA_SPATIAL_ACCOUNT'), findsOneWidget);
  });

  testWidgets('incluye requisitos y las figuras del procedimiento móvil', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TuyaSpatialGuidePage(
          projectQrData: 'https://example.com/project',
          account: 'usuario',
          password: 'contraseña',
        ),
      ),
    );

    expect(find.text('Antes de comenzar'), findsOneWidget);
    expect(find.textContaining('modo de emparejamiento'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Figura 7.'),
      700,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Figura 7.'), findsOneWidget);
  });
}

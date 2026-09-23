import 'package:ficon_power_frontend/presentation/admin/mobile/admin_record_card.dart';
import 'package:ficon_power_frontend/presentation/devices/onboarding/tuya_spatial_guide.dart';
import 'package:ficon_power_frontend/presentation/login/widgets/login_form_card.dart';
import 'package:ficon_power_frontend/presentation/login/widgets/login_support_dialog.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin y superadmin acceden al destino administrativo móvil', () {
    const admin = AuthUser(
      id: '1',
      username: 'admin',
      role: 'ADMIN',
      displayName: 'Administrador',
    );
    const superadmin = AuthUser(
      id: '2',
      username: 'root',
      role: 'SUPERADMIN',
      displayName: 'Superadministrador',
    );
    const reader = AuthUser(
      id: '3',
      username: 'reader',
      role: 'USER',
      displayName: 'Lectura',
    );

    expect(admin.canAccessAdmin, isTrue);
    expect(superadmin.canAccessAdmin, isTrue);
    expect(reader.canAccessAdmin, isFalse);
    expect(admin.canManageUsers, isFalse);
    expect(superadmin.canManageUsers, isTrue);
  });

  testWidgets('el login móvil valida campos y permite ver la contraseña', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final username = TextEditingController();
    final password = TextEditingController();
    var visible = false;
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginFormCard(
            formKey: formKey,
            usernameController: username,
            passwordController: password,
            loading: false,
            showPassword: visible,
            error: null,
            onTogglePassword: () => visible = true,
            onSubmit: () {
              submitted = formKey.currentState?.validate() ?? false;
            },
            onSupport: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('Ingresa el usuario.'), findsOneWidget);
    expect(submitted, isFalse);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    expect(visible, isTrue);
  });

  testWidgets('la ayuda de acceso dirige al correo de soporte', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLoginSupportDialog(context),
            child: const Text('Abrir ayuda'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir ayuda'));
    await tester.pumpAndSettle();

    expect(find.text('Contacte con '), findsOneWidget);
    expect(find.text('soporte'), findsOneWidget);
  });

  testWidgets('la guía explica que el alta pertenece a Tuya Spatial', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TuyaSpatialGuidePage()));

    expect(find.text('Agregar un medidor'), findsOneWidget);
    expect(find.textContaining('Tuya Spatial'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('8. Esperar el emparejamiento'),
      800,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('8. Esperar el emparejamiento'), findsOneWidget);
  });

  testWidgets('la ficha administrativa conserva campos y acción', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminRecordCard(
            title: 'Sesión de técnico',
            fields: const {'IP': '192.168.1.10', 'Rol': 'USER'},
            action: TextButton(
              onPressed: () => invoked = true,
              child: const Text('Revocar'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('192.168.1.10'), findsOneWidget);
    await tester.tap(find.text('Revocar'));
    expect(invoked, isTrue);
  });
}

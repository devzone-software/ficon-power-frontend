import 'package:ficon_power_frontend/adapters/http/ficon_monitoring_repository.dart';
import 'package:ficon_power_frontend/application/ficon_app_router.dart';
import 'package:ficon_power_frontend/application/ficon_dependencies.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:ficon_power_frontend/presentation/widgets/admin_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selecciona la ruta inicial según la sesión', () {
    final session = AuthSession();
    final repository = FiconMonitoringRepository(session: session);
    final router = FiconAppRouter(
      repository: repository,
      session: session,
      dependencies: FiconDependencies(repository),
      navigatorKey: GlobalKey<NavigatorState>(),
    );

    expect(router.initialRoute, AppRoutes.login);

    session.start(
      token: 'token',
      user: const AuthUser(
        id: '1',
        username: 'reader',
        role: 'USER',
        displayName: 'Reader',
      ),
    );

    expect(router.initialRoute, AppRoutes.dashboard);
  });
}

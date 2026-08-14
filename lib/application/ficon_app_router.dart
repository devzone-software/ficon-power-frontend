import 'package:flutter/material.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../config/auth_session.dart';
import '../presentation/pages/admin_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/devices_page.dart';
import '../presentation/pages/events_page.dart';
import '../presentation/pages/incidents_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/widgets/admin_scaffold.dart';
import 'ficon_dependencies.dart';

class FiconAppRouter {
  FiconAppRouter({
    required this.repository,
    required this.session,
    required this.dependencies,
    required this.navigatorKey,
  });

  final FiconMonitoringRepository repository;
  final AuthSession session;
  final FiconDependencies dependencies;
  final GlobalKey<NavigatorState> navigatorKey;

  String get initialRoute =>
      session.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;

  Map<String, WidgetBuilder> get routes => {
    AppRoutes.login: (_) => _loginPage(),
    AppRoutes.dashboard: (_) => _protected(_dashboardPage),
    AppRoutes.devices: (_) => _protected(
      () => DevicesPage(
        getDevices: dependencies.getDevices,
        getSites: dependencies.getSites,
        updateDeviceDetails: dependencies.updateDeviceDetails,
        createSite: dependencies.createSite,
        currentUser: session.user!,
        onLogout: logout,
      ),
    ),
    AppRoutes.incidents: (_) => _protected(
      () => IncidentsPage(
        getIncidents: dependencies.getIncidents,
        currentUser: session.user!,
        onLogout: logout,
      ),
    ),
    AppRoutes.events: (_) => _protected(
      () => EventsPage(
        getEvents: dependencies.getEvents,
        currentUser: session.user!,
        onLogout: logout,
      ),
    ),
    AppRoutes.admin: (_) => _superadminOnly(
      () => AdminPage(
        repository: repository,
        currentUser: session.user!,
        onLogout: logout,
      ),
    ),
  };

  Route<dynamic> unknownRoute(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => session.isAuthenticated ? _dashboardPage() : _loginPage(),
  );

  Future<void> logout() async {
    await repository.logout();
    session.clear();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _protected(Widget Function() pageBuilder) {
    return session.isAuthenticated ? pageBuilder() : _loginPage();
  }

  Widget _superadminOnly(Widget Function() pageBuilder) {
    final user = session.user;
    if (session.isAuthenticated && user != null && user.canManageUsers) {
      return pageBuilder();
    }
    return session.isAuthenticated ? _dashboardPage() : _loginPage();
  }

  LoginPage _loginPage() => LoginPage(repository: repository, session: session);

  DashboardPage _dashboardPage() => DashboardPage(
    getOverview: dependencies.getOverview,
    getNotificationTemplates: dependencies.getNotificationTemplates,
    currentUser: session.user!,
    onLogout: logout,
  );
}

import 'package:flutter/material.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../config/auth_session.dart';
import '../mobile/notifications/mobile_notification_navigation.dart';
import '../presentation/pages/admin_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/devices_page.dart';
import '../presentation/pages/events_page.dart';
import '../presentation/pages/incidents_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/operations_calendar_page.dart';
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
    AppRoutes.devices: (context) => _protected(
      () => DevicesPage(
        getDevices: dependencies.getDevices,
        getDeviceDetail: dependencies.getDeviceDetail,
        getSites: dependencies.getSites,
        updateDeviceDetails: dependencies.updateDeviceDetails,
        createSite: dependencies.createSite,
        currentUser: session.user!,
        onLogout: logout,
        focusDeviceId: _destination(context)?.deviceId,
        realtimeChanges: dependencies.realtime.changes,
      ),
    ),
    AppRoutes.incidents: (context) => _protected(
      () => IncidentsPage(
        getIncidents: dependencies.getIncidents,
        currentUser: session.user!,
        onLogout: logout,
        focusIncidentId: _destination(context)?.incidentId,
        realtimeChanges: dependencies.realtime.changes,
      ),
    ),
    AppRoutes.calendar: (_) => _protected(
      () => OperationsCalendarPage(
        getCalendar: dependencies.getOperationsCalendar,
        managePlans: dependencies.manageTuyaPlans,
        getDeviceDetail: dependencies.getDeviceDetail,
        currentUser: session.user!,
        onLogout: logout,
        realtimeChanges: dependencies.realtime.changes,
      ),
    ),
    AppRoutes.events: (_) => _protected(
      () => EventsPage(
        getEvents: dependencies.getEvents,
        currentUser: session.user!,
        onLogout: logout,
        realtimeChanges: dependencies.realtime.changes,
      ),
    ),
    AppRoutes.admin: (_) => _adminOnly(
      () => AdminPage(
        repository: repository,
        currentUser: session.user!,
        onLogout: logout,
        realtimeChanges: dependencies.realtime.changes,
      ),
    ),
  };

  MobileNotificationDestination? _destination(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is MobileNotificationDestination ? arguments : null;
  }

  Route<dynamic> unknownRoute(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => session.isAuthenticated ? _dashboardPage() : _loginPage(),
  );

  Future<void> logout() async {
    await repository.logout();
    session.clear();
  }

  Widget _protected(Widget Function() pageBuilder) {
    return session.isAuthenticated ? pageBuilder() : _loginPage();
  }

  Widget _adminOnly(Widget Function() pageBuilder) {
    final user = session.user;
    if (session.isAuthenticated && user != null && user.canAccessAdmin) {
      return pageBuilder();
    }
    return session.isAuthenticated ? _dashboardPage() : _loginPage();
  }

  LoginPage _loginPage() => LoginPage(repository: repository, session: session);

  DashboardPage _dashboardPage() => DashboardPage(
    getOverview: dependencies.getOverview,
    getIncidents: dependencies.getIncidents,
    manageTuyaPlans: dependencies.manageTuyaPlans,
    currentUser: session.user!,
    onLogout: logout,
    realtimeChanges: dependencies.realtime.changes,
  );
}

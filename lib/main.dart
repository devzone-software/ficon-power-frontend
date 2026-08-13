import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'config/auth_session.dart';
import 'presentation/pages/admin_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/devices_page.dart';
import 'presentation/pages/events_page.dart';
import 'presentation/pages/incidents_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/theme/ficon_theme.dart';
import 'presentation/widgets/admin_scaffold.dart';
import 'usecase/create_site_service.dart';
import 'usecase/get_devices_service.dart';
import 'usecase/get_events_service.dart';
import 'usecase/get_incidents_service.dart';
import 'usecase/get_monitoring_overview_service.dart';
import 'usecase/get_notification_templates_service.dart';
import 'usecase/get_sites_service.dart';
import 'usecase/update_device_details_service.dart';

void main() {
  final session = AuthSession();
  final repository = FiconMonitoringRepository(session: session);
  runApp(FiconPowerApp(repository: repository, session: session));
}

class FiconPowerApp extends StatefulWidget {
  const FiconPowerApp({
    super.key,
    required this.repository,
    required this.session,
    this.navigatorKey,
    this.title = 'FICON Power',
    this.showBetaBanner = false,
  });

  final FiconMonitoringRepository repository;
  final AuthSession session;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String title;
  final bool showBetaBanner;

  @override
  State<FiconPowerApp> createState() => _FiconPowerAppState();
}

class _FiconPowerAppState extends State<FiconPowerApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final GetMonitoringOverviewService getOverview;
  late final GetDevicesService getDevices;
  late final GetIncidentsService getIncidents;
  late final GetEventsService getEvents;
  late final GetNotificationTemplatesService getNotificationTemplates;
  late final GetSitesService getSites;
  late final UpdateDeviceDetailsService updateDeviceDetails;
  late final CreateSiteService createSite;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    getOverview = GetMonitoringOverviewService(widget.repository);
    getDevices = GetDevicesService(widget.repository);
    getIncidents = GetIncidentsService(widget.repository);
    getEvents = GetEventsService(widget.repository);
    getNotificationTemplates = GetNotificationTemplatesService(
      widget.repository,
    );
    getSites = GetSitesService(widget.repository);
    updateDeviceDetails = UpdateDeviceDetailsService(widget.repository);
    createSite = CreateSiteService(widget.repository);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: widget.title,
        debugShowCheckedModeBanner: false,
        theme: buildFiconTheme(),
        builder: (context, child) {
          if (!widget.showBetaBanner || child == null) return child ?? const SizedBox.shrink();
          return Banner(
            message: 'BETA',
            location: BannerLocation.topEnd,
            color: FiconColors.cyan,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            child: child,
          );
        },
        initialRoute: widget.session.isAuthenticated
            ? AppRoutes.dashboard
            : AppRoutes.login,
        routes: {
          AppRoutes.login: (_) =>
              LoginPage(repository: widget.repository, session: widget.session),
          AppRoutes.dashboard: (_) => _protected(
                () => DashboardPage(
                  getOverview: getOverview,
                  getNotificationTemplates: getNotificationTemplates,
                  currentUser: widget.session.user!,
                  onLogout: _logout,
                ),
              ),
          AppRoutes.devices: (_) => _protected(
                () => DevicesPage(
                  getDevices: getDevices,
                  getSites: getSites,
                  updateDeviceDetails: updateDeviceDetails,
                  createSite: createSite,
                  currentUser: widget.session.user!,
                  onLogout: _logout,
                ),
              ),
          AppRoutes.incidents: (_) => _protected(
                () => IncidentsPage(
                  getIncidents: getIncidents,
                  currentUser: widget.session.user!,
                  onLogout: _logout,
                ),
              ),
          AppRoutes.events: (_) => _protected(
                () => EventsPage(
                  getEvents: getEvents,
                  currentUser: widget.session.user!,
                  onLogout: _logout,
                ),
              ),
          AppRoutes.admin: (_) => _superadminOnly(
                () => AdminPage(
                  repository: widget.repository,
                  currentUser: widget.session.user!,
                  onLogout: _logout,
                ),
              ),
        },
        onUnknownRoute: (_) => MaterialPageRoute(
          builder: (_) => widget.session.isAuthenticated
              ? _dashboardPage()
              : LoginPage(repository: widget.repository, session: widget.session),
        ),
      ),
    );
  }

  Widget _protected(Widget Function() pageBuilder) {
    if (widget.session.isAuthenticated) return pageBuilder();
    return LoginPage(repository: widget.repository, session: widget.session);
  }

  Widget _superadminOnly(Widget Function() pageBuilder) {
    final user = widget.session.user;
    if (widget.session.isAuthenticated && user != null && user.canManageUsers) {
      return pageBuilder();
    }
    if (widget.session.isAuthenticated) return _dashboardPage();
    return LoginPage(repository: widget.repository, session: widget.session);
  }

  DashboardPage _dashboardPage() {
    return DashboardPage(
      getOverview: getOverview,
      getNotificationTemplates: getNotificationTemplates,
      currentUser: widget.session.user!,
      onLogout: _logout,
    );
  }

  Future<void> _logout() async {
    await widget.repository.logout();
    widget.session.clear();
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}

import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'config/auth_session.dart';
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
  });

  final FiconMonitoringRepository repository;
  final AuthSession session;

  @override
  State<FiconPowerApp> createState() => _FiconPowerAppState();
}

class _FiconPowerAppState extends State<FiconPowerApp> {
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
        title: 'FICON Power',
        debugShowCheckedModeBanner: false,
        theme: buildFiconTheme(),
        home: widget.session.isAuthenticated
            ? DashboardPage(
                getOverview: getOverview,
                getNotificationTemplates: getNotificationTemplates,
                currentUser: widget.session.user!,
                onLogout: _logout,
              )
            : LoginPage(repository: widget.repository, session: widget.session),
        routes: widget.session.isAuthenticated
            ? {
                AppRoutes.dashboard: (_) => DashboardPage(
                      getOverview: getOverview,
                      getNotificationTemplates: getNotificationTemplates,
                      currentUser: widget.session.user!,
                      onLogout: _logout,
                    ),
                AppRoutes.devices: (_) => DevicesPage(
                      getDevices: getDevices,
                      getSites: getSites,
                      updateDeviceDetails: updateDeviceDetails,
                      createSite: createSite,
                      currentUser: widget.session.user!,
                      onLogout: _logout,
                    ),
                AppRoutes.incidents: (_) => IncidentsPage(
                      getIncidents: getIncidents,
                      currentUser: widget.session.user!,
                      onLogout: _logout,
                    ),
                AppRoutes.events: (_) => EventsPage(
                      getEvents: getEvents,
                      currentUser: widget.session.user!,
                      onLogout: _logout,
                    ),
              }
            : const {},
      ),
    );
  }

  Future<void> _logout() async {
    await widget.repository.logout();
    widget.session.clear();
  }
}

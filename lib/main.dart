import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/devices_page.dart';
import 'presentation/pages/events_page.dart';
import 'presentation/pages/incidents_page.dart';
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
import 'usecase/update_notification_template_service.dart';

void main() {
  // Ensamblaje de la arquitectura hexagonal: el adaptador HTTP
  // implementa el puerto de salida y los casos de uso exponen los
  // puertos de entrada que consume la presentación.
  final repository = FiconMonitoringRepository();
  runApp(
    FiconPowerApp(
      getOverview: GetMonitoringOverviewService(repository),
      getDevices: GetDevicesService(repository),
      getIncidents: GetIncidentsService(repository),
      getEvents: GetEventsService(repository),
      getNotificationTemplates: GetNotificationTemplatesService(repository),
      updateNotificationTemplate: UpdateNotificationTemplateService(repository),
      getSites: GetSitesService(repository),
      updateDeviceDetails: UpdateDeviceDetailsService(repository),
      createSite: CreateSiteService(repository),
    ),
  );
}

class FiconPowerApp extends StatelessWidget {
  const FiconPowerApp({
    super.key,
    required this.getOverview,
    required this.getDevices,
    required this.getIncidents,
    required this.getEvents,
    required this.getNotificationTemplates,
    required this.updateNotificationTemplate,
    required this.getSites,
    required this.updateDeviceDetails,
    required this.createSite,
  });

  final GetMonitoringOverviewService getOverview;
  final GetDevicesService getDevices;
  final GetIncidentsService getIncidents;
  final GetEventsService getEvents;
  final GetNotificationTemplatesService getNotificationTemplates;
  final UpdateNotificationTemplateService updateNotificationTemplate;
  final GetSitesService getSites;
  final UpdateDeviceDetailsService updateDeviceDetails;
  final CreateSiteService createSite;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FICON Power',
      debugShowCheckedModeBanner: false,
      theme: buildFiconTheme(),
      // La raíz redirige al resumen; cualquier ruta desconocida
      // también redirige al resumen (ver onUnknownRoute).
      initialRoute: AppRoutes.dashboard,
      routes: {
        '/': (_) => DashboardPage(
          getOverview: getOverview,
          getNotificationTemplates: getNotificationTemplates,
          updateNotificationTemplate: updateNotificationTemplate,
        ),
        AppRoutes.dashboard: (_) => DashboardPage(
          getOverview: getOverview,
          getNotificationTemplates: getNotificationTemplates,
          updateNotificationTemplate: updateNotificationTemplate,
        ),
        AppRoutes.devices: (_) => DevicesPage(
          getDevices: getDevices,
          getSites: getSites,
          updateDeviceDetails: updateDeviceDetails,
          createSite: createSite,
        ),
        AppRoutes.incidents: (_) => IncidentsPage(getIncidents: getIncidents),
        AppRoutes.events: (_) => EventsPage(getEvents: getEvents),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => DashboardPage(
          getOverview: getOverview,
          getNotificationTemplates: getNotificationTemplates,
          updateNotificationTemplate: updateNotificationTemplate,
        ),
        settings: const RouteSettings(name: AppRoutes.fallback),
      ),
    );
  }
}

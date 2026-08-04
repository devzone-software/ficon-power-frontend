import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/devices_page.dart';
import 'presentation/pages/events_page.dart';
import 'presentation/pages/incidents_page.dart';
import 'presentation/widgets/admin_scaffold.dart';
import 'usecase/get_devices_service.dart';
import 'usecase/get_events_service.dart';
import 'usecase/get_incidents_service.dart';
import 'usecase/get_monitoring_overview_service.dart';

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
  });

  final GetMonitoringOverviewService getOverview;
  final GetDevicesService getDevices;
  final GetIncidentsService getIncidents;
  final GetEventsService getEvents;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FICON Power',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blueGrey.shade100),
          ),
        ),
      ),
      // La raíz redirige al resumen; cualquier ruta desconocida
      // también redirige al resumen (ver onUnknownRoute).
      initialRoute: AppRoutes.dashboard,
      routes: {
        '/': (_) => DashboardPage(getOverview: getOverview),
        AppRoutes.dashboard: (_) => DashboardPage(getOverview: getOverview),
        AppRoutes.devices: (_) => DevicesPage(getDevices: getDevices),
        AppRoutes.incidents: (_) => IncidentsPage(getIncidents: getIncidents),
        AppRoutes.events: (_) => EventsPage(getEvents: getEvents),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => DashboardPage(getOverview: getOverview),
        settings: const RouteSettings(name: AppRoutes.fallback),
      ),
    );
  }
}

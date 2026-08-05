import 'device.dart';
import 'incident.dart';
import 'site.dart';

/// Vista agregada del monitoreo: sedes, dispositivos e incidentes.
/// Equivalente a las vistas de `MonitoringViews` del backend.
class MonitoringOverview {
  const MonitoringOverview({
    required this.sites,
    required this.devices,
    required this.incidents,
  });

  final List<Site> sites;
  final List<Device> devices;
  final List<Incident> incidents;

  int get onlineCount => devices.where((d) => d.isOnline).length;
  int get offlineCount => devices.length - onlineCount;
  int get openIncidents => incidents.where((i) => i.isOpen).length;
}

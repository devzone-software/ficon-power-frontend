import '../../domain/device.dart';
import '../../domain/event.dart';
import '../../domain/incident.dart';
import '../../domain/site.dart';

/// Puerto de salida: acceso a las consultas de monitoreo del backend.
/// Espejo de `MonitoringQueryRepository` del backend.
abstract interface class MonitoringQueryRepository {
  Future<List<Site>> fetchSites();

  Future<List<Device>> fetchDevices();

  Future<List<Incident>> fetchIncidents({int limit = 100});

  Future<List<Event>> fetchEvents({int limit = 100});
}

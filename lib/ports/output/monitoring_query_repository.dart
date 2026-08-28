import '../../domain/device.dart';
import '../../domain/event.dart';
import '../../domain/incident.dart';
import '../../domain/paged_result.dart';
import '../../domain/site.dart';

/// Puerto de salida: acceso a las consultas de monitoreo del backend.
/// Espejo de `MonitoringQueryRepository` del backend.
abstract interface class MonitoringQueryRepository {
  Future<List<Site>> fetchSites();

  Future<List<Device>> fetchDevices();

  Future<List<Incident>> fetchIncidents({int limit = 100});

  Future<PagedResult<Incident>> fetchIncidentsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    String deviceName = '',
    String siteName = '',
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Event>> fetchEvents({int limit = 100});

  Future<PagedResult<Event>> fetchEventsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String eventType = '',
    String deviceName = '',
    String siteName = '',
    DateTime? occurredDate,
  });
}

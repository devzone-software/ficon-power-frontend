import '../domain/device.dart';
import '../domain/incident.dart';
import '../domain/monitoring_overview.dart';
import '../domain/site.dart';
import '../ports/input/get_monitoring_overview.dart';
import '../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetMonitoringOverview].
/// Orquesta las consultas al puerto de salida, igual que los
/// servicios de `usecase` en el backend.
class GetMonitoringOverviewService implements GetMonitoringOverview {
  const GetMonitoringOverviewService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<MonitoringOverview> call() async {
    final results = await Future.wait([
      _repository.fetchSites(),
      _repository.fetchDevices(),
      _repository.fetchIncidents(limit: 100),
    ]);
    return MonitoringOverview(
      sites: results[0] as List<Site>,
      devices: results[1] as List<Device>,
      incidents: results[2] as List<Incident>,
    );
  }
}

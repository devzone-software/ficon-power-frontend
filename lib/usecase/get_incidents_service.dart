import '../../domain/incident.dart';
import '../../domain/paged_result.dart';
import '../../ports/input/get_incidents.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetIncidents].
class GetIncidentsService implements GetIncidents {
  const GetIncidentsService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Incident>> call({int limit = 100}) =>
      _repository.fetchIncidents(limit: limit);

  @override
  Future<PagedResult<Incident>> page({
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    String deviceName = '',
    String siteName = '',
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _repository.fetchIncidentsPage(
        page: page,
        size: size,
        search: search,
        status: status,
        deviceName: deviceName,
        siteName: siteName,
        startDate: startDate,
        endDate: endDate,
      );

  @override
  Future<void> acknowledge(String id) => _repository.acknowledgeIncident(id);
}

import '../../domain/incident.dart';
import '../../ports/input/get_incidents.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetIncidents].
class GetIncidentsService implements GetIncidents {
  const GetIncidentsService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Incident>> call({int limit = 100}) =>
      _repository.fetchIncidents(limit: limit);
}

import '../../domain/event.dart';
import '../../ports/input/get_events.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetEvents].
class GetEventsService implements GetEvents {
  const GetEventsService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Event>> call({int limit = 100}) =>
      _repository.fetchEvents(limit: limit);
}

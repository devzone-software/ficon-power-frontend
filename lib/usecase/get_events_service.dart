import '../../domain/event.dart';
import '../../domain/paged_result.dart';
import '../../ports/input/get_events.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetEvents].
class GetEventsService implements GetEvents {
  const GetEventsService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Event>> call({int limit = 100}) =>
      _repository.fetchEvents(limit: limit);

  @override
  Future<PagedResult<Event>> page({
    int page = 0,
    int size = 10,
    String search = '',
    String eventType = '',
    String deviceName = '',
    String siteName = '',
    DateTime? occurredDate,
  }) =>
      _repository.fetchEventsPage(
        page: page,
        size: size,
        search: search,
        eventType: eventType,
        deviceName: deviceName,
        siteName: siteName,
        occurredDate: occurredDate,
      );
}

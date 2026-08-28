import '../../domain/event.dart';
import '../../domain/paged_result.dart';

/// Puerto de entrada: caso de uso para listar los eventos Tuya
/// recibidos por el backend (tabla `events`).
abstract interface class GetEvents {
  Future<List<Event>> call({int limit = 100});

  Future<PagedResult<Event>> page({
    int page = 0,
    int size = 10,
    String search = '',
    String eventType = '',
    String deviceName = '',
    String siteName = '',
    DateTime? occurredDate,
  });
}

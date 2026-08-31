import '../../domain/incident.dart';
import '../../domain/paged_result.dart';

/// Puerto de entrada: caso de uso para listar los incidentes
/// de corte de energía (tabla `incidents` del backend).
abstract interface class GetIncidents {
  Future<List<Incident>> call({int limit = 100});

  Future<PagedResult<Incident>> page({
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    String deviceName = '',
    String siteName = '',
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> acknowledge(String id);
}

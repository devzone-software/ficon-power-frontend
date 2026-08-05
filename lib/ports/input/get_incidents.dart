import '../../domain/incident.dart';

/// Puerto de entrada: caso de uso para listar los incidentes
/// de corte de energía (tabla `incidents` del backend).
abstract interface class GetIncidents {
  Future<List<Incident>> call({int limit = 100});
}

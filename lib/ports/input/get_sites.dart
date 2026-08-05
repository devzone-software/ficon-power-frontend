import '../../domain/site.dart';

/// Puerto de entrada: caso de uso para listar las sedes
/// registradas (tabla `sites` del backend).
abstract interface class GetSites {
  Future<List<Site>> call();
}

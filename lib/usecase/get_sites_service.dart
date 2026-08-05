import '../../domain/site.dart';
import '../../ports/input/get_sites.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetSites].
class GetSitesService implements GetSites {
  const GetSitesService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Site>> call() => _repository.fetchSites();
}

import '../../domain/site.dart';
import '../../ports/input/create_site.dart';
import '../../ports/output/site_repository.dart';

/// Implementación del caso de uso [CreateSite].
class CreateSiteService implements CreateSite {
  const CreateSiteService(this._repository);

  final SiteRepository _repository;

  @override
  Future<Site> call({
    required String name,
    String? district,
    String? province,
  }) =>
      _repository.createSite(
        name: name,
        district: district,
        province: province,
      );
}

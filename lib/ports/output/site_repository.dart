import '../../domain/site.dart';

/// Puerto de salida: comandos de escritura sobre sedes.
/// Espejo de `SiteRepository` del backend.
abstract interface class SiteRepository {
  Future<Site> createSite({
    required String name,
    String? district,
    String? province,
  });
}

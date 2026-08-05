import '../../domain/site.dart';

/// Puerto de entrada: caso de uso para crear una sede nueva.
abstract interface class CreateSite {
  Future<Site> call({
    required String name,
    String? district,
    String? province,
  });
}

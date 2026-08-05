import '../../domain/event.dart';

/// Puerto de entrada: caso de uso para listar los eventos Tuya
/// recibidos por el backend (tabla `events`).
abstract interface class GetEvents {
  Future<List<Event>> call({int limit = 100});
}

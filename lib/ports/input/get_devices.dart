import '../../domain/device.dart';

/// Puerto de entrada: caso de uso para listar los dispositivos
/// monitoreados (tabla `devices` del backend).
abstract interface class GetDevices {
  Future<List<Device>> call();
}

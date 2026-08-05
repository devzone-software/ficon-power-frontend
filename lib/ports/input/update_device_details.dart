import '../../domain/device.dart';

/// Puerto de entrada: caso de uso para actualizar el nombre
/// y la sede de un dispositivo.
abstract interface class UpdateDeviceDetails {
  Future<Device> call(
    String id, {
    required String name,
    required String siteId,
  });
}

import '../../domain/device.dart';

/// Puerto de salida: comandos de escritura sobre dispositivos.
/// Espejo de `DeviceRepository` (updateDetails) del backend.
abstract interface class DeviceRepository {
  Future<Device> updateDeviceDetails(
    String id, {
    required String name,
    required String siteId,
  });
}

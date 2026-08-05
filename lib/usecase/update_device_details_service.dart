import '../../domain/device.dart';
import '../../ports/input/update_device_details.dart';
import '../../ports/output/device_repository.dart';

/// Implementación del caso de uso [UpdateDeviceDetails].
class UpdateDeviceDetailsService implements UpdateDeviceDetails {
  const UpdateDeviceDetailsService(this._repository);

  final DeviceRepository _repository;

  @override
  Future<Device> call(
    String id, {
    required String name,
    required String siteId,
  }) =>
      _repository.updateDeviceDetails(id, name: name, siteId: siteId);
}

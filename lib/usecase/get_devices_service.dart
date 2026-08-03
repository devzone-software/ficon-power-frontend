import '../../domain/device.dart';
import '../../ports/input/get_devices.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Implementación del caso de uso [GetDevices].
class GetDevicesService implements GetDevices {
  const GetDevicesService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<List<Device>> call() => _repository.fetchDevices();
}

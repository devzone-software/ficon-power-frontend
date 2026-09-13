import '../domain/device_detail.dart';
import '../ports/input/get_device_detail.dart';
import '../ports/output/monitoring_query_repository.dart';

class GetDeviceDetailService implements GetDeviceDetail {
  const GetDeviceDetailService(this._repository);

  final MonitoringQueryRepository _repository;

  @override
  Future<DeviceDetail> call(String deviceId) =>
      _repository.fetchDeviceDetail(deviceId);
}

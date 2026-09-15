import '../../domain/device_detail.dart';

abstract interface class GetDeviceDetail {
  Future<DeviceDetail> call(String deviceId);
}

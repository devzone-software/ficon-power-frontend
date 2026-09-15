import 'package:ficon_power_frontend/domain/device.dart';
import 'package:ficon_power_frontend/domain/device_detail.dart';
import 'package:ficon_power_frontend/domain/event.dart';
import 'package:ficon_power_frontend/domain/incident.dart';
import 'package:ficon_power_frontend/domain/paged_result.dart';
import 'package:ficon_power_frontend/domain/site.dart';
import 'package:ficon_power_frontend/ports/output/monitoring_query_repository.dart';
import 'package:ficon_power_frontend/usecase/get_monitoring_overview_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMonitoringQueryRepository implements MonitoringQueryRepository {
  @override
  Future<List<Site>> fetchSites() async => const [
    Site(id: '1', name: 'Sede Lima', active: true, deviceCount: 2),
  ];

  @override
  Future<List<Device>> fetchDevices() async => const [
    Device(
      id: '1',
      name: 'Medidor A',
      active: true,
      status: 'online',
      eventCount: 0,
      incidentCount: 0,
      totalDowntimeSeconds: 0,
    ),
    Device(
      id: '2',
      name: 'Medidor B',
      active: true,
      status: 'offline',
      eventCount: 0,
      incidentCount: 1,
      totalDowntimeSeconds: 60,
    ),
  ];

  @override
  Future<List<Incident>> fetchIncidents({int limit = 100}) async => const [
    Incident(id: '1', status: 'active', deviceName: 'Medidor B'),
    Incident(id: '2', status: 'resolved', deviceName: 'Medidor A'),
  ];

  @override
  Future<DeviceDetail> fetchDeviceDetail(String deviceId) =>
      throw UnimplementedError();

  @override
  Future<PagedResult<Incident>> fetchIncidentsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    String deviceName = '',
    String siteName = '',
    String incidentId = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final items = await fetchIncidents(limit: size);
    return PagedResult(
      items: items,
      page: page,
      size: size,
      totalItems: items.length,
      totalPages: 1,
      hasPrevious: false,
      hasNext: false,
    );
  }

  @override
  Future<void> acknowledgeIncident(String id) async {}

  @override
  Future<List<Event>> fetchEvents({int limit = 100}) async => const [];

  @override
  Future<PagedResult<Event>> fetchEventsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String eventType = '',
    String deviceName = '',
    String siteName = '',
    DateTime? occurredDate,
  }) async {
    return PagedResult(
      items: await fetchEvents(limit: size),
      page: page,
      size: size,
      totalItems: 0,
      totalPages: 0,
      hasPrevious: false,
      hasNext: false,
    );
  }
}

void main() {
  test(
    'GetMonitoringOverviewService agrega sedes, dispositivos e incidentes',
    () async {
      final service = GetMonitoringOverviewService(
        FakeMonitoringQueryRepository(),
      );

      final overview = await service();

      expect(overview.sites, hasLength(1));
      expect(overview.devices, hasLength(2));
      expect(overview.onlineCount, 1);
      expect(overview.offlineCount, 1);
      expect(overview.openIncidents, 1);
    },
  );
}

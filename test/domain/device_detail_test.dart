import 'package:ficon_power_frontend/domain/device_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta métricas, series e incidentes del detalle', () {
    final detail = DeviceDetail.fromJson({
      'device': {
        'id': 'device-1',
        'name': 'Medidor Puno',
        'active': true,
        'status': 'offline',
        'eventCount': 24,
        'incidentCount': 3,
        'totalDowntimeSeconds': 900,
      },
      'metrics': {
        'incidentsLast7Days': 1,
        'incidentsLast30Days': 2,
        'incidentsLast90Days': 3,
        'averageDowntimeSeconds': 300,
        'longestDowntimeSeconds': 600,
        'availabilityLast30Days': 99.97,
      },
      'dailyIncidents': [
        {'label': '13/09', 'count': 1},
      ],
      'weeklyIncidents': const [],
      'monthlyIncidents': const [],
      'weekdayIncidents': const [],
      'timeOfDayIncidents': const [],
      'recentIncidents': [
        {'id': 'incident-1', 'status': 'active', 'durationSeconds': 60},
      ],
    });

    expect(detail.device.name, 'Medidor Puno');
    expect(detail.metrics.availabilityLast30Days, 99.97);
    expect(detail.metrics.longestDowntimeSeconds, 600);
    expect(detail.dailyIncidents.single.count, 1);
    expect(detail.recentIncidents.single.isOpen, isTrue);
  });
}

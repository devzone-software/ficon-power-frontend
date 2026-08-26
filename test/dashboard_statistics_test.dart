import 'package:ficon_power_frontend/application/dashboard_statistics.dart';
import 'package:ficon_power_frontend/domain/device.dart';
import 'package:ficon_power_frontend/domain/incident.dart';
import 'package:ficon_power_frontend/domain/monitoring_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrega frecuencia, duración y ranking de dispositivos', () {
    final overview = MonitoringOverview(
      sites: const [],
      devices: const [
        Device(
          id: 'meter-1',
          name: 'Medidor principal',
          active: true,
          status: 'offline',
          eventCount: 4,
          incidentCount: 2,
          totalDowntimeSeconds: 3600,
        ),
        Device(
          id: 'meter-2',
          name: 'Medidor secundario',
          active: true,
          status: 'online',
          eventCount: 2,
          incidentCount: 1,
          totalDowntimeSeconds: 600,
        ),
      ],
      incidents: [
        Incident(
          id: '1',
          status: 'resolved',
          startTime: DateTime(2026, 8, 13, 5),
          durationSeconds: 600,
        ),
        Incident(
          id: '2',
          status: 'resolved',
          startTime: DateTime(2026, 8, 12, 14),
          durationSeconds: 1200,
        ),
      ],
    );

    final stats = DashboardStatistics.from(
      overview,
      referenceTime: DateTime(2026, 8, 13),
    );

    expect(stats.totalPowerOutages, 2);
    expect(stats.totalDowntimeSeconds, 4200);
    expect(stats.averageIncidentSeconds, 900);
    expect(stats.dailyIncidents.last.count, 1);
    expect(stats.timeOfDayIncidents.map((item) => item.count), [1, 0, 1, 0]);
    expect(stats.deviceRankings.first.label, 'Medidor principal');
  });
}

import 'dart:convert';

import 'package:ficon_power_frontend/application/mobile_data_export.dart';
import 'package:ficon_power_frontend/domain/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final table = MobileDataExportTables.devices(const [
    Device(
      id: 'device-1',
      name: 'Medidor "principal", norte',
      externalId: 'tuya-1',
      active: true,
      status: 'online',
      eventCount: 4,
      incidentCount: 2,
      totalDowntimeSeconds: 60,
    ),
  ]);

  test('exporta CSV compatible con Excel y escapa valores', () {
    final bytes = MobileDataExportEncoder.csv(table);
    final content = utf8.decode(bytes);

    expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
    expect(content, startsWith('"ID","ID Tuya"'));
    expect(content, contains('"tuya-1"'));
    expect(content, contains('"Medidor ""principal"", norte"'));
  });

  test('exporta un libro XLSX válido', () {
    final bytes = MobileDataExportEncoder.xlsx(table);

    expect(bytes, isNotEmpty);
    expect(bytes.take(2), [0x50, 0x4b]);
  });

  test('expone distrito sin duplicar la sede en dispositivos', () {
    final deviceTable = MobileDataExportTables.devices(const [
      Device(
        id: 'device-2',
        name: 'Medidor Puno',
        siteId: 'site-1',
        siteName: 'Timax - Puno',
        district: 'Puno',
        active: true,
        status: 'online',
        eventCount: 0,
        incidentCount: 0,
        totalDowntimeSeconds: 0,
      ),
    ]);

    expect(deviceTable.headers, contains('Distrito'));
    expect(deviceTable.headers, isNot(contains('Sede')));
    expect(deviceTable.headers, isNot(contains('ID sede')));
    expect(deviceTable.rows.single, contains('Puno'));
    expect(deviceTable.rows.single, isNot(contains('Timax - Puno')));
  });

  test('solo expone los formatos CSV y XLSX', () {
    expect(MobileExportFormat.values, [
      MobileExportFormat.csv,
      MobileExportFormat.xlsx,
    ]);
  });
}

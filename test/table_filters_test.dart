import 'package:ficon_power_frontend/presentation/widgets/table_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColumnFilterState', () {
    test('combina filtros de texto y fecha por clave', () {
      final filters = ColumnFilterState()
        ..setText('device', 'meter')
        ..setDate('date', DateTime(2026, 8, 13));

      expect(filters.matchesText('device', 'Main Meter'), isTrue);
      expect(filters.matchesText('device', 'Sensor'), isFalse);
      expect(filters.matchesDate('date', DateTime(2026, 8, 13, 23)), isTrue);
      expect(filters.matchesDate('date', DateTime(2026, 8, 12)), isFalse);
    });

    test('filtra direcciones IP por segmentos parciales', () {
      final filters = ColumnFilterState()
        ..setIpSegment('ip', 0, '198')
        ..setIpSegment('ip', 2, '7');

      expect(filters.matchesIp('ip', '198.162.74.30'), isTrue);
      expect(filters.matchesIp('ip', '198.162.12.30'), isFalse);
      expect(filters.matchesIp('ip', '10.0.0.1'), isFalse);
    });

    test('sin criterios acepta cualquier valor', () {
      final filters = ColumnFilterState();

      expect(filters.matchesText('missing', null), isTrue);
      expect(filters.matchesDate('missing', null), isTrue);
      expect(filters.matchesIp('missing', null), isTrue);
    });
  });
}

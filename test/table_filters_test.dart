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

    test('las opciones cerradas requieren coincidencia exacta', () {
      final filters = ColumnFilterState()..setText('role', 'ADMIN');

      expect(filters.matchesChoice('role', 'ADMIN'), isTrue);
      expect(filters.matchesChoice('role', 'SUPERADMIN'), isFalse);
    });

    test('la búsqueda unificada revisa todas las columnas de una fila', () {
      final filters = ColumnFilterState()..setText('query', 'miraflores');

      expect(
        filters.matchesAnyText('query', ['Medidor 1', 'Sede Miraflores']),
        isTrue,
      );
      expect(filters.matchesAnyText('query', ['Medidor 2', 'Surco']), isFalse);
    });

    test('ordena valores numéricos ascendente y descendente', () {
      final filters = ColumnFilterState()
        ..setSort('count', ColumnSortDirection.ascending);

      expect(filters.sortedNumeric('count', [8, 2, 5], (value) => value), [
        2,
        5,
        8,
      ]);

      filters.setSort('count', ColumnSortDirection.descending);
      expect(filters.sortedNumeric('count', [8, 2, 5], (value) => value), [
        8,
        5,
        2,
      ]);
    });

    test('unifica y ordena sugerencias sin duplicados', () {
      expect(
        mergeFilterOptions([
          ['Sede Surco', 'Medidor 2'],
          ['medidor 2', 'Sede Miraflores'],
        ]),
        ['Medidor 2', 'Sede Miraflores', 'Sede Surco'],
      );
    });
  });
}

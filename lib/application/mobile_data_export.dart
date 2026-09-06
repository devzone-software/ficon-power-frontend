import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../domain/device.dart';
import '../domain/event.dart';
import '../domain/incident.dart';

enum MobileExportDataset {
  devices('Dispositivos', 'dispositivos'),
  incidents('Incidentes', 'incidentes'),
  events('Eventos', 'eventos');

  const MobileExportDataset(this.label, this.fileName);

  final String label;
  final String fileName;
}

enum MobileExportFormat {
  csv('CSV', 'csv', 'text/csv'),
  xlsx(
    'Excel',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const MobileExportFormat(this.label, this.extension, this.mimeType);

  final String label;
  final String extension;
  final String mimeType;
}

class MobileExportRequest {
  const MobileExportRequest({required this.dataset, required this.format});

  final MobileExportDataset dataset;
  final MobileExportFormat format;
}

class MobileExportTable {
  const MobileExportTable({
    required this.sheetName,
    required this.headers,
    required this.rows,
  });

  final String sheetName;
  final List<String> headers;
  final List<List<Object?>> rows;
}

class MobileDataExportService {
  const MobileDataExportService(this.repository);

  final FiconMonitoringRepository repository;

  Future<void> share(MobileExportRequest request) async {
    final table = await _load(request.dataset);
    final bytes = switch (request.format) {
      MobileExportFormat.csv => MobileDataExportEncoder.csv(table),
      MobileExportFormat.xlsx => MobileDataExportEncoder.xlsx(table),
    };
    final stamp = DateTime.now().toUtc().toIso8601String().split('T').first;
    final file = XFile.fromData(
      bytes,
      mimeType: request.format.mimeType,
      name:
          'ficon-power-${request.dataset.fileName}-$stamp.'
          '${request.format.extension}',
    );
    await Share.shareXFiles([
      file,
    ], subject: 'Exportación FICON Power · ${request.dataset.label}');
  }

  Future<MobileExportTable> _load(MobileExportDataset dataset) async {
    return switch (dataset) {
      MobileExportDataset.devices => MobileDataExportTables.devices(
        await repository.fetchDevices(),
      ),
      MobileExportDataset.incidents => MobileDataExportTables.incidents(
        await repository.fetchIncidents(limit: 500),
      ),
      MobileExportDataset.events => MobileDataExportTables.events(
        await repository.fetchEvents(limit: 500),
      ),
    };
  }
}

class MobileDataExportTables {
  MobileDataExportTables._();

  static MobileExportTable devices(List<Device> devices) => MobileExportTable(
    sheetName: 'Dispositivos',
    headers: const [
      'ID',
      'ID Tuya',
      'Nombre',
      'Categoría',
      'Modelo',
      'Activo',
      'Estado',
      'Último cambio',
      'Distrito',
      'Eventos',
      'Incidentes',
      'Indisponibilidad (s)',
    ],
    rows: [
      for (final device in devices)
        [
          device.id,
          device.externalId,
          device.name,
          device.category,
          device.model,
          device.active,
          device.status,
          device.lastStatusChange?.toIso8601String(),
          device.district,
          device.eventCount,
          device.incidentCount,
          device.totalDowntimeSeconds,
        ],
    ],
  );

  static MobileExportTable incidents(List<Incident> incidents) =>
      MobileExportTable(
        sheetName: 'Incidentes',
        headers: const [
          'ID',
          'Dispositivo',
          'Sede',
          'Estado',
          'Inicio',
          'Fin',
          'Duración (s)',
        ],
        rows: [
          for (final incident in incidents)
            [
              incident.id,
              incident.deviceName,
              incident.siteName,
              incident.status,
              incident.startTime?.toIso8601String(),
              incident.endTime?.toIso8601String(),
              incident.durationSeconds,
            ],
        ],
      );

  static MobileExportTable events(List<Event> events) => MobileExportTable(
    sheetName: 'Eventos',
    headers: const [
      'ID',
      'Tipo',
      'Dispositivo',
      'Sede',
      'Fecha',
      'Latencia (ms)',
    ],
    rows: [
      for (final event in events)
        [
          event.id,
          event.eventType,
          event.deviceName,
          event.siteName,
          event.occurredAt?.toIso8601String(),
          event.deliveryLatencyMillis,
        ],
    ],
  );
}

class MobileDataExportEncoder {
  MobileDataExportEncoder._();

  static Uint8List csv(MobileExportTable table) {
    final rows = [table.headers, ...table.rows];
    final content = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$content\r\n'));
  }

  static Uint8List xlsx(MobileExportTable table) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    final sheet = workbook[table.sheetName];
    sheet.appendRow(table.headers.map(TextCellValue.new).toList());
    for (final row in table.rows) {
      sheet.appendRow(row.map(_excelCell).toList());
    }
    if (defaultSheet != null && defaultSheet != table.sheetName) {
      workbook.delete(defaultSheet);
    }
    return Uint8List.fromList(workbook.encode()!);
  }

  static String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  static CellValue _excelCell(Object? value) => switch (value) {
    null => TextCellValue(''),
    bool boolean => BoolCellValue(boolean),
    int number => IntCellValue(number),
    double number => DoubleCellValue(number),
    _ => TextCellValue(value.toString()),
  };
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/device.dart';
import '../../ports/input/get_devices.dart';

/// Tabla de dispositivos monitoreados (vista de la tabla `devices`).
class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key, required this.getDevices});

  final GetDevices getDevices;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getDevices();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.getDevices());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos')),
      body: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snapshot.data!;
          if (devices.isEmpty) {
            return const Center(
              child: Text('No hay dispositivos registrados.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: _DevicesTable(devices: devices),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DevicesTable extends StatelessWidget {
  const _DevicesTable({required this.devices});

  final List<Device> devices;

  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('ID externo')),
        DataColumn(label: Text('Sede')),
        DataColumn(label: Text('Distrito')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Último cambio')),
        DataColumn(label: Text('Incidentes'), numeric: true),
        DataColumn(label: Text('Indisponibilidad'), numeric: true),
      ],
      rows: [
        for (final device in devices)
          DataRow(
            cells: [
              DataCell(Text(device.name.isNotEmpty
                  ? device.name
                  : device.externalId ?? '')),
              DataCell(Text(device.externalId ?? '')),
              DataCell(Text(device.siteName ?? '')),
              DataCell(Text(device.district ?? '')),
              DataCell(_StatusLabel(online: device.isOnline)),
              DataCell(Text(_formatDate(device.lastStatusChange))),
              DataCell(Text('${device.incidentCount}')),
              DataCell(Text(_formatDowntime(device.totalDowntimeSeconds))),
            ],
          ),
      ],
    );
  }

  static String _formatDate(DateTime? value) =>
      value == null ? '' : _dateFormat.format(value.toLocal());

  static String _formatDowntime(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ${duration.inMinutes % 60} min';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes} min';
    return '${duration.inSeconds} s';
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Text(
      online ? 'En línea' : 'Fuera de línea',
      style: TextStyle(
        color: online ? Colors.green.shade700 : Colors.red.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudieron cargar los dispositivos.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

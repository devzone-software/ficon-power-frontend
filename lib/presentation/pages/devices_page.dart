import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../../ports/input/get_devices.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

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
    return AdminScaffold(
      currentRoute: AppRoutes.devices,
      title: 'Dispositivos',
      body: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
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
              DataCell(DeviceStatusChip(online: device.isOnline)),
              DataCell(Text(formatDateTime(device.lastStatusChange))),
              DataCell(Text('${device.incidentCount}')),
              DataCell(
                Text(formatDurationSeconds(device.totalDowntimeSeconds)),
              ),
            ],
          ),
      ],
    );
  }
}

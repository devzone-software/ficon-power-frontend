import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../widgets/common.dart';

class DevicesTable extends StatelessWidget {
  const DevicesTable({
    super.key,
    required this.devices,
    required this.onEdit,
    required this.onOpen,
    required this.canEdit,
  });

  final List<Device> devices;
  final ValueChanged<Device> onEdit;
  final ValueChanged<Device> onOpen;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('ID externo')),
        DataColumn(label: Text('Distrito')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Último cambio')),
        DataColumn(label: Text('Incidentes'), numeric: true),
        DataColumn(label: Text('Indisponibilidad'), numeric: true),
        DataColumn(label: Text('Acciones')),
      ],
      rows: [for (final device in devices) _row(device)],
    );
  }

  DataRow _row(Device device) {
    return DataRow(
      onSelectChanged: (_) => onOpen(device),
      cells: [
        DataCell(
          Text(device.name.isNotEmpty ? device.name : device.externalId ?? ''),
        ),
        DataCell(Text(device.externalId ?? '')),
        DataCell(Text(device.district ?? '')),
        DataCell(DeviceStatusChip(online: device.isOnline)),
        DataCell(Text(formatDateTime(device.lastStatusChange))),
        DataCell(Text('${device.incidentCount}')),
        DataCell(Text(formatDurationSeconds(device.totalDowntimeSeconds))),
        DataCell(
          IconButton(
            onPressed: canEdit ? () => onEdit(device) : null,
            icon: const Icon(Icons.edit_outlined),
            tooltip: canEdit
                ? 'Editar dispositivo'
                : 'Solo admin o superadmin pueden editar',
          ),
        ),
      ],
    );
  }
}

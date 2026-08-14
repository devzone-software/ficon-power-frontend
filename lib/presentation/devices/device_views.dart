part of '../pages/devices_page.dart';

class _DevicesTable extends StatelessWidget {
  const _DevicesTable({
    required this.devices,
    required this.onEdit,
    required this.canEdit,
  });

  final List<Device> devices;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

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
        DataColumn(label: Text('Acciones')),
      ],
      rows: [
        for (final device in devices)
          DataRow(
            cells: [
              DataCell(
                Text(
                  device.name.isNotEmpty
                      ? device.name
                      : device.externalId ?? '',
                ),
              ),
              DataCell(Text(device.externalId ?? '')),
              DataCell(Text(device.siteName ?? '')),
              DataCell(Text(device.district ?? '')),
              DataCell(DeviceStatusChip(online: device.isOnline)),
              DataCell(Text(formatDateTime(device.lastStatusChange))),
              DataCell(Text('${device.incidentCount}')),
              DataCell(
                Text(formatDurationSeconds(device.totalDowntimeSeconds)),
              ),
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
          ),
      ],
    );
  }
}

class _DevicesCompactList extends StatelessWidget {
  const _DevicesCompactList({
    required this.devices,
    required this.onEdit,
    required this.canEdit,
  });

  final List<Device> devices;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Column(
        children: [
          for (final device in devices) ...[
            _DeviceCompactCard(
              device: device,
              onEdit: onEdit,
              canEdit: canEdit,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DeviceCompactCard extends StatelessWidget {
  const _DeviceCompactCard({
    required this.device,
    required this.onEdit,
    required this.canEdit,
  });

  final Device device;
  final ValueChanged<Device> onEdit;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = device.name.isNotEmpty
        ? device.name
        : device.externalId ?? 'Sin nombre';
    final externalId = device.externalId?.trim().isNotEmpty == true
        ? device.externalId!
        : 'Sin ID externo';
    final site = device.siteName?.trim().isNotEmpty == true
        ? device.siteName!
        : 'Sin sede';
    final district = device.district?.trim().isNotEmpty == true
        ? device.district!
        : 'Sin distrito';
    final unavailable = formatDurationSeconds(device.totalDowntimeSeconds);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        (device.isOnline
                                ? StatusColors.online
                                : StatusColors.offline)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.electric_meter_outlined,
                    color: device.isOnline
                        ? StatusColors.online
                        : StatusColors.offline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: FiconColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        externalId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: FiconColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: canEdit ? () => onEdit(device) : null,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: canEdit
                      ? 'Editar dispositivo'
                      : 'Solo admin o superadmin pueden editar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DeviceStatusChip(online: device.isOnline),
                _DeviceMiniChip(icon: Icons.location_on_outlined, label: site),
                _DeviceMiniChip(icon: Icons.map_outlined, label: district),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DeviceStatTile(
                    label: 'Último cambio',
                    value: formatDateTime(device.lastStatusChange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DeviceStatTile(
                    label: 'Incidentes',
                    value: '${device.incidentCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DeviceStatTile(
              label: 'Indisponibilidad',
              value: unavailable,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceMiniChip extends StatelessWidget {
  const _DeviceMiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FiconColors.cyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FiconColors.cyan.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: FiconColors.logoBlue),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceStatTile extends StatelessWidget {
  const _DeviceStatTile({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: FiconColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FiconColors.cardBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FiconColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: fullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FiconColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return child;
  }
}

/// Diálogo para editar el nombre y la sede de un dispositivo.
/// Permite crear una sede nueva al vuelo. Devuelve `true` al
/// cerrarse si el guardado fue exitoso.

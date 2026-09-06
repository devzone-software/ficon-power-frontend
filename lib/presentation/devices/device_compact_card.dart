import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'device_detail_widgets.dart';

class DeviceCompactCard extends StatelessWidget {
  const DeviceCompactCard({
    super.key,
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
                _DeviceIcon(online: device.isOnline),
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
                DeviceMiniChip(
                  icon: Icons.location_on_outlined,
                  label: _present(device.district, 'Sin distrito'),
                ),
                if (device.category?.trim().isNotEmpty == true)
                  DeviceMiniChip(
                    icon: Icons.category_outlined,
                    label: device.category!,
                  ),
                if (device.model?.trim().isNotEmpty == true)
                  DeviceMiniChip(
                    icon: Icons.memory_outlined,
                    label: device.model!,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DeviceStatTile(
                    label: 'Último cambio',
                    value: formatDateTime(device.lastStatusChange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DeviceStatTile(
                    label: 'Incidentes',
                    value: '${device.incidentCount}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DeviceStatTile(
                    label: 'Eventos',
                    value: '${device.eventCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DeviceStatTile(
              label: 'Indisponibilidad',
              value: formatDurationSeconds(device.totalDowntimeSeconds),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _present(String? value, String fallback) =>
      value?.trim().isNotEmpty == true ? value! : fallback;
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? StatusColors.online : StatusColors.offline;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.electric_meter_outlined, color: color),
    );
  }
}

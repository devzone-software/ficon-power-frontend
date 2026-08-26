import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_section_header.dart';

class OfflineDevicesCard extends StatelessWidget {
  const OfflineDevicesCard({super.key, required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final visible = devices.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              icon: Icons.router_outlined,
              color: StatusColors.offline,
              title: 'Fuera de línea',
              subtitle: 'Dispositivos activos sin señal',
              trailing: devices.isNotEmpty
                  ? StatusChip(
                      label: '${devices.length}',
                      color: StatusColors.offline,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const EmptyNote('Todos los dispositivos están en línea.')
            else
              for (var index = 0; index < visible.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.power_off, color: StatusColors.offline),
                  title: Text(
                    visible[index].name.isNotEmpty
                        ? visible[index].name
                        : visible[index].externalId ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(visible[index].siteName ?? 'Sin sede'),
                  trailing: Text(
                    formatDateTime(visible[index].lastStatusChange),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

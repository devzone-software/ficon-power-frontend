import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'device_detail_widgets.dart';

class DeviceCompactCard extends StatelessWidget {
  const DeviceCompactCard({
    super.key,
    required this.device,
    required this.onOpen,
  });

  final Device device;
  final ValueChanged<Device> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = device.name.isNotEmpty
        ? device.name
        : device.externalId ?? 'Sin nombre';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(device),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: FiconColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: FiconColors.logoBlue),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DeviceMiniChip(
                    icon: Icons.location_on_outlined,
                    label: _present(device.district, 'Sin distrito'),
                  ),
                  DeviceStatusChip(online: device.isOnline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _present(String? value, String fallback) =>
      value?.trim().isNotEmpty == true ? value! : fallback;
}

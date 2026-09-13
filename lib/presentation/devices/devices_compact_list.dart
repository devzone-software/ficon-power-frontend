import 'package:flutter/material.dart';

import '../../domain/device.dart';
import 'device_compact_card.dart';

class DevicesCompactList extends StatelessWidget {
  const DevicesCompactList({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Column(
        children: [
          for (final device in devices) ...[
            DeviceCompactCard(
              device: device,
              onEdit: onEdit,
              onOpen: onOpen,
              canEdit: canEdit,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/device.dart';
import '../theme/ficon_theme.dart';

enum DevicesViewMode { list, map }

/// Geographic projection rendered entirely on-device, without remote tiles.
class DeviceLocationMap extends StatelessWidget {
  const DeviceLocationMap({
    super.key,
    required this.devices,
    required this.onOpenDevice,
  });
  final List<Device> devices;
  final ValueChanged<Device> onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final located = devices
        .where((d) => d.punoMapLocation != null && d.isInPuno)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Región Puno · ${located.length} dispositivos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Plano de ubicaciones · coordenadas aproximadas al centro de cada ciudad',
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 420,
            color: FiconColors.surface,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _Grid())),
                  const Positioned(left: 16, top: 12, child: Text('N ↑')),
                  for (var i = 0; i < located.length; i++)
                    Builder(
                      builder: (context) {
                        final device = located[i];
                        final point = device.punoMapLocation!;
                        final x = ((point.longitude + 70.7) / 1.3).clamp(
                          0.08,
                          0.90,
                        );
                        final y = ((-14.7 - point.latitude) / 1.4).clamp(
                          0.06,
                          0.89,
                        );
                        return Positioned(
                          left: (constraints.maxWidth - 125) * x,
                          top: 350 * y,
                          child: SizedBox(
                            width: 125,
                            child: TextButton.icon(
                              onPressed: () => onOpenDevice(device),
                              icon: Icon(
                                Icons.location_on,
                                color: device.hasActiveIncident
                                    ? FiconColors.danger
                                    : FiconColors.success,
                              ),
                              label: Text(device.district ?? device.name),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        if (devices.length != located.length)
          Text(
            '${devices.length - located.length} dispositivos sin coordenadas reconocidas.',
          ),
      ],
    );
  }
}

class _Grid extends CustomPainter {
  const _Grid();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FiconColors.slate.withValues(alpha: .12)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_Grid oldDelegate) => false;
}

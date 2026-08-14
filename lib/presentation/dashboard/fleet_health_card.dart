import 'package:flutter/material.dart';

import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_section_header.dart';

class FleetHealthCard extends StatelessWidget {
  const FleetHealthCard({super.key, required this.online, required this.total});

  final int online;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0
        ? 0.0
        : (online / total).clamp(0.0, 1.0).toDouble();
    final offline = total > online ? total - online : 0;
    final color = ratio >= 0.9
        ? StatusColors.online
        : ratio >= 0.5
        ? StatusColors.acknowledged
        : StatusColors.offline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: DashboardSectionHeader(
                    icon: Icons.monitor_heart_outlined,
                    color: FiconColors.logoBlue,
                    title: 'Disponibilidad de dispositivos',
                    subtitle: 'Señal estable para la red monitoreada',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(ratio * 100).round()} %',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Container(color: FiconColors.cardBorderSoft),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(
                  color: StatusColors.online,
                  label: '$online en línea',
                ),
                _LegendDot(
                  color: StatusColors.offline,
                  label: '$offline fuera de línea',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

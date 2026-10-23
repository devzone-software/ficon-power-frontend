import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/chart_date_label.dart';

import '../../application/dashboard_statistics.dart';
import '../theme/ficon_theme.dart';
import 'dashboard_section_header.dart';

class FrequencyBarChart extends StatelessWidget {
  const FrequencyBarChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
    this.compactDates = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FrequencyPoint> points;
  final bool compactDates;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      0,
      (max, point) => point.count > max ? point.count : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              icon: icon,
              color: color,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final minimumWidth =
                    points.length * 36.0 + math.max(0, points.length - 1) * 8;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(constraints.maxWidth, minimumWidth),
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < points.length; index++) ...[
                          Expanded(
                            child: _VerticalBar(
                              point: points[index],
                              maxValue: maxValue,
                              color: color,
                              label: compactDates
                                  ? compactDailyChartLabel(points[index].label)
                                  : points[index].label,
                            ),
                          ),
                          if (index < points.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.point,
    required this.maxValue,
    required this.color,
    required this.label,
  });

  final FrequencyPoint point;
  final int maxValue;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : point.count / maxValue;
    return Tooltip(
      message: '${point.label}: ${point.count} cortes',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${point.count}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FiconColors.deepAlt,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0 ? 0.04 : ratio.clamp(0.0, 1.0),
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: point.count == 0
                        ? FiconColors.cardBorderSoft
                        : color.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: FiconColors.slate),
          ),
        ],
      ),
    );
  }
}

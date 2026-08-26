import 'package:flutter/material.dart';

import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_section_header.dart';

class RankingBarItem {
  const RankingBarItem({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final int value;
  final String detail;
}

class RankingBarsCard extends StatelessWidget {
  const RankingBarsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String emptyMessage;
  final List<RankingBarItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      0,
      (max, item) => item.value > max ? item.value : max,
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
            const SizedBox(height: 14),
            if (items.isEmpty)
              EmptyNote(emptyMessage)
            else
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: 14),
                _HorizontalBar(
                  item: items[index],
                  maxValue: maxValue,
                  color: color,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.item,
    required this.maxValue,
    required this.color,
  });

  final RankingBarItem item;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : (item.value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${item.value}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 9,
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
        const SizedBox(height: 4),
        Text(
          item.detail,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: FiconColors.slate),
        ),
      ],
    );
  }
}

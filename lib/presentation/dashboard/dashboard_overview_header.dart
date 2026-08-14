import 'package:flutter/material.dart';

import '../theme/ficon_theme.dart';

class DashboardOverviewHeader extends StatelessWidget {
  const DashboardOverviewHeader({
    super.key,
    required this.online,
    required this.total,
    required this.openIncidents,
  });

  final int online;
  final int total;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onlineText = total == 0
        ? 'Sin dispositivos'
        : '$online/$total online';
    final incidentText = openIncidents == 0
        ? 'Operación estable'
        : '$openIncidents incidentes';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FiconColors.cardBorderSoft),
        boxShadow: [
          BoxShadow(
            color: FiconColors.logoBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: FiconColors.logoBlue),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) => _HeaderContent(
                  compact: constraints.maxWidth < 720,
                  textTheme: textTheme,
                  onlineText: onlineText,
                  incidentText: incidentText,
                  openIncidents: openIncidents,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.compact,
    required this.textTheme,
    required this.onlineText,
    required this.incidentText,
    required this.openIncidents,
  });

  final bool compact;
  final TextTheme textTheme;
  final String onlineText;
  final String incidentText;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FiconBrandMark(height: 36, showPowerLabel: false),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Panel de continuidad FICON',
                style: textTheme.titleLarge?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Monitoreo eléctrico para mantener tu red estable, veloz y conectada.',
          style: textTheme.bodyMedium?.copyWith(color: FiconColors.slate),
        ),
      ],
    );
    final chips = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _HeaderChip(
          icon: Icons.wifi_tethering,
          label: onlineText,
          accent: FiconColors.cyan,
        ),
        _HeaderChip(
          icon: openIncidents == 0
              ? Icons.verified_outlined
              : Icons.bolt_outlined,
          label: incidentText,
          accent: openIncidents == 0 ? FiconColors.cyan : FiconColors.warning,
        ),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [intro, const SizedBox(height: 18), chips],
      );
    }
    return Row(
      children: [
        Expanded(child: intro),
        const SizedBox(width: 16),
        chips,
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: FiconColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

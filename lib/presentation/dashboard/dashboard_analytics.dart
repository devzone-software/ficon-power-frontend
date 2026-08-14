part of '../pages/dashboard_page.dart';

class _DashboardAnalyticsSection extends StatelessWidget {
  const _DashboardAnalyticsSection({required this.stats});

  final DashboardStatistics stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final medium = constraints.maxWidth >= 720;
        final metricWidth = wide
            ? (constraints.maxWidth - 3 * 16) / 4
            : medium
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        final metricCards = Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _InsightMetricCard(
              width: metricWidth,
              title: 'Apagados registrados',
              value: '${stats.totalPowerOutages}',
              description: 'Cortes detectados en todos los medidores',
              icon: Icons.power_off_outlined,
              color: FiconColors.logoBlue,
            ),
            _InsightMetricCard(
              width: metricWidth,
              title: 'Promedio semanal',
              value: stats.weeklyAverageText,
              description: 'Frecuencia de apagados en las últimas semanas',
              icon: Icons.date_range_outlined,
              color: StatusColors.offline,
            ),
            _InsightMetricCard(
              width: metricWidth,
              title: 'Tiempo fuera acumulado',
              value: _formatDurationCompact(stats.totalDowntimeSeconds),
              description: 'Suma de downtime reportado por la flota',
              icon: Icons.timer_off_outlined,
              color: StatusColors.acknowledged,
            ),
            _InsightMetricCard(
              width: metricWidth,
              title: 'Duración promedio',
              value: _formatDurationCompact(stats.averageIncidentSeconds),
              description: 'Tiempo promedio antes de volver la energía',
              icon: Icons.av_timer_outlined,
              color: FiconColors.cyan,
            ),
          ],
        );

        final charts = [
          _FrequencyBarChart(
            title: 'Apagados por día',
            subtitle:
                'Cuántas veces se apagaron medidores en los últimos 7 días',
            icon: Icons.calendar_view_week_outlined,
            color: FiconColors.logoBlue,
            points: stats.dailyIncidents,
          ),
          _FrequencyBarChart(
            title: 'Apagados por semana',
            subtitle: 'Frecuencia semanal acumulada para todos los medidores',
            icon: Icons.stacked_bar_chart_outlined,
            color: StatusColors.offline,
            points: stats.weeklyIncidents,
          ),
          _FrequencyBarChart(
            title: 'Apagados por mes',
            subtitle: 'Comparación mensual para ver estacionalidad',
            icon: Icons.calendar_month_outlined,
            color: FiconColors.cyanSoft,
            points: stats.monthlyIncidents,
          ),
          _FrequencyBarChart(
            title: 'Días con más apagados',
            subtitle: 'Ayuda a detectar patrones por día de la semana',
            icon: Icons.event_repeat_outlined,
            color: StatusColors.acknowledged,
            points: stats.weekdayIncidents,
          ),
          _RankingBarsCard(
            title: 'Medidores con más apagados',
            subtitle: 'Ranking para priorizar revisión técnica por equipo',
            icon: Icons.electric_meter_outlined,
            color: StatusColors.offline,
            emptyMessage: 'No hay apagados por medidor.',
            items: stats.deviceRankings
                .map(
                  (device) => _RankingBarItem(
                    label: device.label,
                    value: device.incidents,
                    detail: _formatDurationCompact(device.downtimeSeconds),
                  ),
                )
                .toList(),
          ),
          _FrequencyBarChart(
            title: 'Apagados por horario',
            subtitle: 'En qué momento del día se concentran los cortes',
            icon: Icons.schedule_outlined,
            color: FiconColors.logoBlue,
            points: stats.timeOfDayIncidents,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              icon: Icons.analytics_outlined,
              color: FiconColors.logoBlue,
              title: 'Lectura estadística',
              subtitle:
                  'Métricas y gráficos derivados de las tablas operativas',
            ),
            const SizedBox(height: 16),
            metricCards,
            const SizedBox(height: 16),
            if (wide)
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[1]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[2]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[3]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[4]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[5]),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  for (var i = 0; i < charts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    charts[i],
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: textTheme.titleLarge?.copyWith(
                        color: FiconColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: FiconColors.deepAlt,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: FiconColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyBarChart extends StatelessWidget {
  const _FrequencyBarChart({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FrequencyPoint> points;

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
            _SectionHeader(
              icon: icon,
              color: color,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points) ...[
                    Expanded(
                      child: _VerticalBar(
                        label: point.label,
                        value: point.count,
                        ratio: maxValue == 0 ? 0 : point.count / maxValue,
                        color: color,
                      ),
                    ),
                    if (point != points.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final heightFactor = ratio.clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
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
              heightFactor: heightFactor == 0 ? 0.04 : heightFactor,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: value == 0
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
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: FiconColors.slate),
        ),
      ],
    );
  }
}

class _RankingBarsCard extends StatelessWidget {
  const _RankingBarsCard({
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
  final List<_RankingBarItem> items;

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
            _SectionHeader(
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

  final _RankingBarItem item;
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

class _RankingBarItem {
  const _RankingBarItem({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final int value;
  final String detail;
}

String _formatDurationCompact(int seconds) {
  if (seconds <= 0) return '0 min';
  final duration = Duration(seconds: seconds);
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

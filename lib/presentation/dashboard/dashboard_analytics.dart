part of '../pages/dashboard_page.dart';

class _DashboardAnalyticsSection extends StatelessWidget {
  const _DashboardAnalyticsSection({required this.stats});

  final _DashboardStats stats;

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
  final List<_FrequencyPoint> points;

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

class _DashboardStats {
  const _DashboardStats({
    required this.totalPowerOutages,
    required this.totalDowntimeSeconds,
    required this.averageIncidentSeconds,
    required this.dailyIncidents,
    required this.weeklyIncidents,
    required this.monthlyIncidents,
    required this.weekdayIncidents,
    required this.timeOfDayIncidents,
    required this.deviceRankings,
  });

  final int totalPowerOutages;
  final int totalDowntimeSeconds;
  final int averageIncidentSeconds;
  final List<_FrequencyPoint> dailyIncidents;
  final List<_FrequencyPoint> weeklyIncidents;
  final List<_FrequencyPoint> monthlyIncidents;
  final List<_FrequencyPoint> weekdayIncidents;
  final List<_FrequencyPoint> timeOfDayIncidents;
  final List<_ImpactRankingStat> deviceRankings;

  String get weeklyAverageText {
    if (weeklyIncidents.isEmpty) return '0/sem';
    final average =
        weeklyIncidents.fold<int>(0, (sum, point) => sum + point.count) /
        weeklyIncidents.length;
    return '${average.toStringAsFixed(1)}/sem';
  }

  factory _DashboardStats.from(MonitoringOverview data) {
    final totalPowerOutages = data.incidents.length;
    final totalDowntimeSeconds = data.devices.fold<int>(
      0,
      (sum, device) => sum + device.totalDowntimeSeconds,
    );
    final durations = [
      for (final incident in data.incidents)
        if (incident.durationSeconds != null && incident.durationSeconds! > 0)
          incident.durationSeconds!,
    ];
    final averageIncidentSeconds = durations.isEmpty
        ? 0
        : (durations.fold<int>(0, (sum, duration) => sum + duration) /
                  durations.length)
              .round();

    return _DashboardStats(
      totalPowerOutages: totalPowerOutages,
      totalDowntimeSeconds: totalDowntimeSeconds,
      averageIncidentSeconds: averageIncidentSeconds,
      dailyIncidents: _dailyFrequencyStats(data.incidents),
      weeklyIncidents: _weeklyFrequencyStats(data.incidents),
      monthlyIncidents: _monthlyFrequencyStats(data.incidents),
      weekdayIncidents: _weekdayFrequencyStats(data.incidents),
      timeOfDayIncidents: _timeOfDayFrequencyStats(data.incidents),
      deviceRankings: _deviceRankingStats(data.devices),
    );
  }

  static List<_FrequencyPoint> _dailyFrequencyStats(List<Incident> incidents) {
    final now = DateTime.now();
    final counts = <DateTime, int>{};
    for (var offset = 6; offset >= 0; offset--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      counts[date] = 0;
    }
    for (final incident in incidents) {
      final start = incident.startTime;
      if (start == null) continue;
      final date = DateTime(start.year, start.month, start.day);
      if (counts.containsKey(date)) {
        counts[date] = counts[date]! + 1;
      }
    }
    return [
      for (final entry in counts.entries)
        _FrequencyPoint(
          label:
              '${entry.key.day.toString().padLeft(2, '0')}/${entry.key.month.toString().padLeft(2, '0')}',
          count: entry.value,
        ),
    ];
  }

  static List<_FrequencyPoint> _weeklyFrequencyStats(List<Incident> incidents) {
    final today = DateTime.now();
    final currentMonday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - DateTime.monday));
    final counts = <DateTime, int>{};
    for (var offset = 3; offset >= 0; offset--) {
      counts[currentMonday.subtract(Duration(days: offset * 7))] = 0;
    }
    for (final incident in incidents) {
      final start = incident.startTime;
      if (start == null) continue;
      final day = DateTime(start.year, start.month, start.day);
      final monday = day.subtract(
        Duration(days: day.weekday - DateTime.monday),
      );
      if (counts.containsKey(monday)) {
        counts[monday] = counts[monday]! + 1;
      }
    }
    return [
      for (final entry in counts.entries)
        _FrequencyPoint(
          label:
              'S ${entry.key.day.toString().padLeft(2, '0')}/${entry.key.month.toString().padLeft(2, '0')}',
          count: entry.value,
        ),
    ];
  }

  static List<_FrequencyPoint> _monthlyFrequencyStats(
    List<Incident> incidents,
  ) {
    final now = DateTime.now();
    final counts = <DateTime, int>{};
    for (var offset = 5; offset >= 0; offset--) {
      final monthCursor = DateTime(now.year, now.month - offset, 1);
      counts[monthCursor] = 0;
    }
    for (final incident in incidents) {
      final start = incident.startTime;
      if (start == null) continue;
      final month = DateTime(start.year, start.month, 1);
      if (counts.containsKey(month)) {
        counts[month] = counts[month]! + 1;
      }
    }
    return [
      for (final entry in counts.entries)
        _FrequencyPoint(
          label: _monthShortName(entry.key.month),
          count: entry.value,
        ),
    ];
  }

  static List<_FrequencyPoint> _weekdayFrequencyStats(
    List<Incident> incidents,
  ) {
    final labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final counts = List<int>.filled(7, 0);
    for (final incident in incidents) {
      final start = incident.startTime;
      if (start == null) continue;
      counts[start.weekday - 1]++;
    }
    return [
      for (var index = 0; index < labels.length; index++)
        _FrequencyPoint(label: labels[index], count: counts[index]),
    ];
  }

  static List<_FrequencyPoint> _timeOfDayFrequencyStats(
    List<Incident> incidents,
  ) {
    final counts = List<int>.filled(4, 0);
    for (final incident in incidents) {
      final start = incident.startTime;
      if (start == null) continue;
      final hour = start.hour;
      if (hour < 6) {
        counts[0]++;
      } else if (hour < 12) {
        counts[1]++;
      } else if (hour < 18) {
        counts[2]++;
      } else {
        counts[3]++;
      }
    }
    return [
      _FrequencyPoint(label: '00-06', count: counts[0]),
      _FrequencyPoint(label: '06-12', count: counts[1]),
      _FrequencyPoint(label: '12-18', count: counts[2]),
      _FrequencyPoint(label: '18-24', count: counts[3]),
    ];
  }

  static List<_ImpactRankingStat> _deviceRankingStats(List<Device> devices) {
    final rankings =
        [
              for (final device in devices)
                _ImpactRankingStat(
                  label: device.name.isNotEmpty
                      ? device.name
                      : device.externalId ?? 'Dispositivo',
                  devices: 1,
                  incidents: device.incidentCount,
                  downtimeSeconds: device.totalDowntimeSeconds,
                ),
            ]
            .where((stat) => stat.incidents > 0 || stat.downtimeSeconds > 0)
            .toList()
          ..sort((a, b) {
            final incidentCompare = b.incidents.compareTo(a.incidents);
            if (incidentCompare != 0) return incidentCompare;
            return b.downtimeSeconds.compareTo(a.downtimeSeconds);
          });
    return rankings.take(10).toList();
  }
}

class _ImpactRankingStat {
  const _ImpactRankingStat({
    required this.label,
    required this.devices,
    required this.incidents,
    required this.downtimeSeconds,
  });

  final String label;
  final int devices;
  final int incidents;
  final int downtimeSeconds;
}

class _FrequencyPoint {
  const _FrequencyPoint({required this.label, required this.count});

  final String label;
  final int count;
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

String _monthShortName(int month) {
  const names = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return names[(month - 1).clamp(0, names.length - 1)];
}

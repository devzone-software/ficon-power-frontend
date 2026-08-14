import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_header.dart';
import 'frequency_bar_chart.dart';
import 'insight_metric_card.dart';
import 'ranking_bars_card.dart';

class DashboardAnalyticsSection extends StatelessWidget {
  const DashboardAnalyticsSection({super.key, required this.stats});

  final DashboardStatistics stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metricWidth = _metricWidth(constraints.maxWidth);
        final charts = _charts();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardSectionHeader(
              icon: Icons.analytics_outlined,
              color: FiconColors.logoBlue,
              title: 'Lectura estadística',
              subtitle:
                  'Métricas y gráficos derivados de las tablas operativas',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _metricCards(metricWidth),
            ),
            const SizedBox(height: 16),
            if (constraints.maxWidth >= 1000)
              _WideChartGrid(charts: charts)
            else
              _NarrowChartList(charts: charts),
          ],
        );
      },
    );
  }

  double _metricWidth(double availableWidth) {
    if (availableWidth >= 1000) return (availableWidth - 48) / 4;
    if (availableWidth >= 720) return (availableWidth - 16) / 2;
    return availableWidth;
  }

  List<Widget> _metricCards(double width) => [
    InsightMetricCard(
      width: width,
      title: 'Apagados registrados',
      value: '${stats.totalPowerOutages}',
      description: 'Cortes detectados en todos los medidores',
      icon: Icons.power_off_outlined,
      color: FiconColors.logoBlue,
    ),
    InsightMetricCard(
      width: width,
      title: 'Promedio semanal',
      value: stats.weeklyAverageText,
      description: 'Frecuencia de apagados en las últimas semanas',
      icon: Icons.date_range_outlined,
      color: StatusColors.offline,
    ),
    InsightMetricCard(
      width: width,
      title: 'Tiempo fuera acumulado',
      value: formatDashboardDuration(stats.totalDowntimeSeconds),
      description: 'Suma de downtime reportado por la flota',
      icon: Icons.timer_off_outlined,
      color: StatusColors.acknowledged,
    ),
    InsightMetricCard(
      width: width,
      title: 'Duración promedio',
      value: formatDashboardDuration(stats.averageIncidentSeconds),
      description: 'Tiempo promedio antes de volver la energía',
      icon: Icons.av_timer_outlined,
      color: FiconColors.cyan,
    ),
  ];

  List<Widget> _charts() => [
    FrequencyBarChart(
      title: 'Apagados por día',
      subtitle: 'Cuántas veces se apagaron medidores en los últimos 7 días',
      icon: Icons.calendar_view_week_outlined,
      color: FiconColors.logoBlue,
      points: stats.dailyIncidents,
    ),
    FrequencyBarChart(
      title: 'Apagados por semana',
      subtitle: 'Frecuencia semanal acumulada para todos los medidores',
      icon: Icons.stacked_bar_chart_outlined,
      color: StatusColors.offline,
      points: stats.weeklyIncidents,
    ),
    FrequencyBarChart(
      title: 'Apagados por mes',
      subtitle: 'Comparación mensual para ver estacionalidad',
      icon: Icons.calendar_month_outlined,
      color: FiconColors.cyanSoft,
      points: stats.monthlyIncidents,
    ),
    FrequencyBarChart(
      title: 'Días con más apagados',
      subtitle: 'Ayuda a detectar patrones por día de la semana',
      icon: Icons.event_repeat_outlined,
      color: StatusColors.acknowledged,
      points: stats.weekdayIncidents,
    ),
    RankingBarsCard(
      title: 'Medidores con más apagados',
      subtitle: 'Ranking para priorizar revisión técnica por equipo',
      icon: Icons.electric_meter_outlined,
      color: StatusColors.offline,
      emptyMessage: 'No hay apagados por medidor.',
      items: stats.deviceRankings
          .map(
            (device) => RankingBarItem(
              label: device.label,
              value: device.incidents,
              detail: formatDashboardDuration(device.downtimeSeconds),
            ),
          )
          .toList(growable: false),
    ),
    FrequencyBarChart(
      title: 'Apagados por horario',
      subtitle: 'En qué momento del día se concentran los cortes',
      icon: Icons.schedule_outlined,
      color: FiconColors.logoBlue,
      points: stats.timeOfDayIncidents,
    ),
  ];
}

class _WideChartGrid extends StatelessWidget {
  const _WideChartGrid({required this.charts});

  final List<Widget> charts;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var row = 0; row < charts.length; row += 2) ...[
        if (row > 0) const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts[row]),
            const SizedBox(width: 16),
            Expanded(child: charts[row + 1]),
          ],
        ),
      ],
    ],
  );
}

class _NarrowChartList extends StatelessWidget {
  const _NarrowChartList({required this.charts});

  final List<Widget> charts;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < charts.length; index++) ...[
        if (index > 0) const SizedBox(height: 16),
        charts[index],
      ],
    ],
  );
}

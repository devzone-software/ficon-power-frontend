import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_header.dart';
import 'frequency_bar_chart.dart';
import 'frequency_dot_chart.dart';
import 'insight_metric_card.dart';
import 'ranking_bars_card.dart';

enum _AnalyticsPeriod { weekly, monthly }

class DashboardAnalyticsSection extends StatefulWidget {
  const DashboardAnalyticsSection({super.key, required this.stats});

  final DashboardStatistics stats;

  @override
  State<DashboardAnalyticsSection> createState() =>
      _DashboardAnalyticsSectionState();
}

class _DashboardAnalyticsSectionState extends State<DashboardAnalyticsSection> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.monthly;

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
              spacing: constraints.maxWidth < 720 ? 10 : 16,
              runSpacing: constraints.maxWidth < 720 ? 10 : 16,
              children: _metricCards(metricWidth),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SegmentedButton<_AnalyticsPeriod>(
                segments: const [
                  ButtonSegment(
                    value: _AnalyticsPeriod.weekly,
                    icon: Icon(Icons.calendar_view_week_outlined),
                    label: Text('Semana'),
                  ),
                  ButtonSegment(
                    value: _AnalyticsPeriod.monthly,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('Mes'),
                  ),
                ],
                selected: {_period},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _period = selection.first),
              ),
            ),
            const SizedBox(height: 12),
            if (constraints.maxWidth < 720)
              _MobileChartCarousel(charts: charts)
            else if (constraints.maxWidth >= 1000)
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
    return (availableWidth - 10) / 2;
  }

  List<Widget> _metricCards(double width) => [
    InsightMetricCard(
      width: width,
      title: 'Apagados registrados',
      value: '${widget.stats.totalPowerOutages}',
      description: 'Cortes detectados en todos los medidores',
      icon: Icons.power_off_outlined,
      color: FiconColors.logoBlue,
    ),
    InsightMetricCard(
      width: width,
      title: 'Promedio semanal',
      value: widget.stats.weeklyAverageText,
      description: 'Frecuencia de apagados en las últimas semanas',
      icon: Icons.date_range_outlined,
      color: StatusColors.offline,
    ),
    InsightMetricCard(
      width: width,
      title: 'Tiempo fuera acumulado',
      value: formatDashboardDuration(widget.stats.totalDowntimeSeconds),
      description: 'Suma de downtime reportado por la flota',
      icon: Icons.timer_off_outlined,
      color: StatusColors.acknowledged,
    ),
    InsightMetricCard(
      width: width,
      title: 'Duración promedio',
      value: formatDashboardDuration(widget.stats.averageIncidentSeconds),
      description: 'Tiempo promedio antes de volver la energía',
      icon: Icons.av_timer_outlined,
      color: FiconColors.cyan,
    ),
  ];

  List<Widget> _charts() => [
    FrequencyDotChart(
      title: _period == _AnalyticsPeriod.monthly
          ? 'Cortes del mes'
          : 'Cortes de la semana',
      subtitle: _period == _AnalyticsPeriod.monthly
          ? 'Número de cortes por cada día del mes actual'
          : 'Número de cortes de lunes a domingo',
      points: _period == _AnalyticsPeriod.monthly
          ? widget.stats.currentMonthDailyIncidents
          : widget.stats.currentWeekDailyIncidents,
    ),
    FrequencyBarChart(
      title: 'Apagados por semana',
      subtitle: 'Frecuencia semanal acumulada para todos los medidores',
      icon: Icons.stacked_bar_chart_outlined,
      color: StatusColors.offline,
      points: widget.stats.weeklyIncidents,
    ),
    FrequencyBarChart(
      title: 'Apagados por mes',
      subtitle: 'Comparación mensual para ver estacionalidad',
      icon: Icons.calendar_month_outlined,
      color: FiconColors.cyanSoft,
      points: widget.stats.monthlyIncidents,
    ),
    FrequencyBarChart(
      title: 'Días con más apagados',
      subtitle: 'Ayuda a detectar patrones por día de la semana',
      icon: Icons.event_repeat_outlined,
      color: StatusColors.acknowledged,
      points: widget.stats.weekdayIncidents,
    ),
    RankingBarsCard(
      title: 'Medidores con más apagados',
      subtitle: 'Ranking para priorizar revisión técnica por equipo',
      icon: Icons.electric_meter_outlined,
      color: StatusColors.offline,
      emptyMessage: 'No hay apagados por medidor.',
      items: widget.stats.deviceRankings
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
      points: widget.stats.timeOfDayIncidents,
    ),
  ];
}

class _MobileChartCarousel extends StatelessWidget {
  const _MobileChartCarousel({required this.charts});

  final List<Widget> charts;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 48;
    return SizedBox(
      height: 310,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: charts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: width.clamp(280.0, 420.0).toDouble(),
          child: charts[index],
        ),
      ),
    );
  }
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

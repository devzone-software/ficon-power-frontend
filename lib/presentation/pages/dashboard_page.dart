import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../domain/notification_template.dart';
import '../../ports/input/get_monitoring_overview.dart';
import '../../ports/input/get_notification_templates.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Resumen general: KPIs, disponibilidad de la flota,
/// dispositivos fuera de línea e incidentes recientes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.getOverview,
    required this.getNotificationTemplates,
    required this.currentUser,
    required this.onLogout,
  });

  final GetMonitoringOverview getOverview;
  final GetNotificationTemplates getNotificationTemplates;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _autoRefreshInterval = Duration(seconds: 10);

  late Future<MonitoringOverview> _future;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = widget.getOverview();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = widget.getOverview());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.dashboard,
      title: 'Resumen',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<MonitoringOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _DashboardBody(
              data: snapshot.data!,
              getNotificationTemplates: widget.getNotificationTemplates,
              currentUser: widget.currentUser,
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado de resumen con el mismo lenguaje visual de las tarjetas KPI.
class _FiconOverviewHeader extends StatelessWidget {
  const _FiconOverviewHeader({
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
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FiconBrandMark(
                            height: 36,
                            showPowerLabel: false,
                          ),
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: FiconColors.slate,
                        ),
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
                        accent: openIncidents == 0
                            ? FiconColors.cyan
                            : FiconColors.warning,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip compacto para el encabezado de resumen.
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.getNotificationTemplates,
    required this.currentUser,
  });

  final MonitoringOverview data;
  final GetNotificationTemplates getNotificationTemplates;
  final AuthUser currentUser;

  @override
  Widget build(BuildContext context) {
    final offlineDevices = data.devices
        .where((d) => !d.isOnline && d.active)
        .toList();
    final recentIncidents = data.incidents.take(6).toList();
    final stats = _DashboardStats.from(data);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _FiconOverviewHeader(
                  online: data.onlineCount,
                  total: data.devices.length,
                  openIncidents: data.openIncidents,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 900
                        ? (width - 3 * 16) / 4
                        : width >= 560
                        ? (width - 16) / 2
                        : width;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _KpiCard(
                          title: 'Sedes',
                          value: '${data.sites.length}',
                          icon: Icons.business,
                          color: FiconColors.logoBlue,
                          width: cardWidth,
                        ),
                        _KpiCard(
                          title: 'Dispositivos',
                          value: '${data.devices.length}',
                          icon: Icons.electrical_services,
                          color: FiconColors.cyanSoft,
                          width: cardWidth,
                        ),
                        _KpiCard(
                          title: 'En línea',
                          value: '${data.onlineCount}',
                          icon: Icons.check_circle_outline,
                          color: StatusColors.online,
                          width: cardWidth,
                        ),
                        _KpiCard(
                          title: 'Incidentes activos',
                          value: '${data.openIncidents}',
                          icon: Icons.warning_amber,
                          color: data.openIncidents > 0
                              ? StatusColors.offline
                              : StatusColors.online,
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                const SizedBox(height: 24),
                _DashboardAnalyticsSection(stats: stats),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final lists = [
                      _OfflineDevicesCard(devices: offlineDevices),
                      _RecentIncidentsCard(incidents: recentIncidents),
                    ];
                    if (!wide) {
                      return Column(
                        children: [
                          lists[0],
                          const SizedBox(height: 24),
                          lists[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: lists[0]),
                        const SizedBox(width: 24),
                        Expanded(child: lists[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _NotificationTemplatesCard(
                  getNotificationTemplates: getNotificationTemplates,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 24),
                  const _MobileAppDownloadCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileAppDownloadCard extends StatelessWidget {
  const _MobileAppDownloadCard();

  static final Uri _apkUri = Uri(path: '/mobile/ficon-power.apk');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final header = const _SectionHeader(
              icon: Icons.phone_android_outlined,
              color: FiconColors.cyanSoft,
              title: 'App móvil',
              subtitle: 'Descarga la versión Android publicada en este VPS',
            );
            final button = FilledButton.icon(
              onPressed: () =>
                  launchUrl(_apkUri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar APK'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, const SizedBox(height: 16), button],
              );
            }

            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  color: FiconColors.slate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetHealthCard extends StatelessWidget {
  const _FleetHealthCard({required this.online, required this.total});

  final int online;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = total == 0
        ? 0.0
        : (online / total).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();
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
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.monitor_heart_outlined,
                    color: FiconColors.logoBlue,
                    title: 'Disponibilidad de dispositivos',
                    subtitle: 'Señal estable para la red monitoreada',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent %',
                  style: textTheme.headlineSmall?.copyWith(
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

/// Encabezado de sección reutilizable: ícono en recuadro teñido,
/// título y subtítulo.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: FiconColors.slate,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _OfflineDevicesCard extends StatelessWidget {
  const _OfflineDevicesCard({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final visible = devices.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.router_outlined,
              color: StatusColors.offline,
              title: 'Fuera de línea',
              subtitle: 'Dispositivos activos sin señal',
              trailing: devices.isNotEmpty
                  ? StatusChip(
                      label: '${devices.length}',
                      color: StatusColors.offline,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const EmptyNote('Todos los dispositivos están en línea.')
            else
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.power_off, color: StatusColors.offline),
                  title: Text(
                    visible[i].name.isNotEmpty
                        ? visible[i].name
                        : visible[i].externalId ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(visible[i].siteName ?? 'Sin sede'),
                  trailing: Text(
                    formatDateTime(visible[i].lastStatusChange),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RecentIncidentsCard extends StatelessWidget {
  const _RecentIncidentsCard({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.history,
              color: FiconColors.cyanSoft,
              title: 'Incidentes recientes',
              subtitle: 'Historial de cortes y retornos reportados',
            ),
            const SizedBox(height: 8),
            if (incidents.isEmpty)
              const EmptyNote('No hay incidentes registrados.')
            else
              for (var i = 0; i < incidents.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    incidents[i].isOpen ? Icons.error_outline : Icons.task_alt,
                    color: incidents[i].isOpen
                        ? StatusColors.offline
                        : StatusColors.online,
                  ),
                  title: Text(
                    incidents[i].deviceName ?? 'Dispositivo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${incidents[i].siteName ?? 'Sin sede'} · '
                    '${formatDateTime(incidents[i].startTime)}',
                  ),
                  trailing: IncidentStatusChip(status: incidents[i].status),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta para ver y editar las plantillas de los mensajes
/// de notificación (corte y retorno de energía).
class _NotificationTemplatesCard extends StatefulWidget {
  const _NotificationTemplatesCard({required this.getNotificationTemplates});

  final GetNotificationTemplates getNotificationTemplates;

  @override
  State<_NotificationTemplatesCard> createState() =>
      _NotificationTemplatesCardState();
}

class _NotificationTemplatesCardState
    extends State<_NotificationTemplatesCard> {
  late Future<List<NotificationTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getNotificationTemplates();
  }

  void _reload() {
    setState(() => _future = widget.getNotificationTemplates());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.notifications_active_outlined,
              color: FiconColors.cyanSoft,
              title: 'Plantillas Meta de WhatsApp',
              subtitle: 'Configuración activa para alertas de corte y retorno',
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<NotificationTemplate>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'No se pudieron cargar las plantillas.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reintentar',
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final templates = snapshot.data!;
                if (templates.isEmpty) {
                  return const EmptyNote('No hay plantillas configuradas.');
                }
                return Column(
                  children: [
                    for (var i = 0; i < templates.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: FiconColors.cardBorderSoft,
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.notifications_active_outlined,
                          color: StatusColors.acknowledged,
                        ),
                        title: Text(templates[i].displayName),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _TemplateModeChip(template: templates[i]),
                                  if (templates[i].usesMetaTemplate)
                                    for (final param
                                        in templates[i].metaTemplateParams)
                                      _VariableChip(
                                        label: templates[i].labelForVariable(
                                          param,
                                        ),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                templates[i].summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateModeChip extends StatelessWidget {
  const _TemplateModeChip({required this.template});

  final NotificationTemplate template;

  @override
  Widget build(BuildContext context) {
    final usesMeta = template.usesMetaTemplate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: usesMeta
            ? FiconColors.cyan.withValues(alpha: 0.12)
            : FiconColors.logoBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: usesMeta
              ? FiconColors.cyan.withValues(alpha: 0.35)
              : FiconColors.logoBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        usesMeta ? 'Plantilla Meta activa' : 'Plantilla Meta no configurada',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: usesMeta ? FiconColors.deepAlt : FiconColors.logoBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FiconColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: FiconColors.deep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

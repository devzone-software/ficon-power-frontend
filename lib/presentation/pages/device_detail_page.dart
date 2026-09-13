import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/device_detail.dart';
import '../../domain/incident.dart';
import '../../ports/input/get_device_detail.dart';
import '../dashboard/dashboard_section_header.dart';
import '../dashboard/frequency_bar_chart.dart';
import '../dashboard/insight_metric_card.dart';
import '../devices/device_detail_widgets.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({
    super.key,
    required this.deviceId,
    required this.initialDeviceName,
    required this.getDeviceDetail,
    required this.currentUser,
    required this.onLogout,
  });

  final String deviceId;
  final String initialDeviceName;
  final GetDeviceDetail getDeviceDetail;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  static const _refreshInterval = Duration(seconds: 30);

  late Future<DeviceDetail> _future;
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = widget.getDeviceDetail(widget.deviceId);
    _timer = Timer.periodic(_refreshInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = widget.getDeviceDetail(widget.deviceId));
    try {
      await _future;
    } catch (_) {
      // FutureBuilder presenta el error y permite reintentar.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.devices,
      title: widget.initialDeviceName.trim().isEmpty
          ? 'Detalle del dispositivo'
          : widget.initialDeviceName,
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<DeviceDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _DeviceDetailBody(detail: snapshot.data!, onRefresh: _refresh);
        },
      ),
    );
  }
}

class _DeviceDetailBody extends StatelessWidget {
  const _DeviceDetailBody({required this.detail, required this.onRefresh});

  final DeviceDetail detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final device = detail.device;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth.clamp(0, 1180).toDouble();
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver a dispositivos'),
                    ),
                    const SizedBox(height: 8),
                    _DeviceHeader(device: device),
                    const SizedBox(height: 16),
                    _Metrics(detail: detail),
                    const SizedBox(height: 16),
                    _Charts(detail: detail),
                    const SizedBox(height: 16),
                    _RecentDeviceIncidents(incidents: detail.recentIncidents),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final name = device.name.trim().isEmpty
        ? device.externalId ?? 'Dispositivo'
        : device.name;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color:
                        (device.isOnline
                                ? StatusColors.online
                                : StatusColors.offline)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.electric_meter_outlined,
                    color: device.isOnline
                        ? StatusColors.online
                        : StatusColors.offline,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: FiconColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.externalId ?? 'Sin ID externo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FiconColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                DeviceStatusChip(online: device.isOnline),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DeviceMiniChip(
                  icon: Icons.location_on_outlined,
                  label: _location(device),
                ),
                if (_showSite(device))
                  DeviceMiniChip(
                    icon: Icons.business_outlined,
                    label: device.siteName!,
                  ),
                if (device.provider?.trim().isNotEmpty == true)
                  DeviceMiniChip(
                    icon: Icons.cloud_outlined,
                    label: device.provider!,
                  ),
                if (device.category?.trim().isNotEmpty == true)
                  DeviceMiniChip(
                    icon: Icons.category_outlined,
                    label: device.category!,
                  ),
                if (device.model?.trim().isNotEmpty == true)
                  DeviceMiniChip(
                    icon: Icons.memory_outlined,
                    label: device.model!,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text(
                  'Último cambio: ${formatDateTime(device.lastStatusChange)}',
                ),
                if (device.currentIncidentStartedAt != null)
                  Text(
                    'Corte activo desde: '
                    '${formatDateTime(device.currentIncidentStartedAt)}',
                  ),
                Text('Eventos recibidos: ${device.eventCount}'),
                if (device.productId?.trim().isNotEmpty == true)
                  Text('Producto Tuya: ${device.productId}'),
                Text('Monitoreado: ${device.active ? 'Sí' : 'No'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _showSite(Device device) {
    final site = device.siteName?.trim();
    final district = device.district?.trim();
    return site?.isNotEmpty == true &&
        site!.toLowerCase() != district?.toLowerCase();
  }

  String _location(Device device) {
    final values = [device.district, device.province, device.department]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return values.isEmpty ? 'Sin ubicación' : values.join(', ');
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.detail});

  final DeviceDetail detail;

  @override
  Widget build(BuildContext context) {
    final device = detail.device;
    final metrics = detail.metrics;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            InsightMetricCard(
              width: width,
              title: 'Disponibilidad',
              value: '${metrics.availabilityLast30Days.toStringAsFixed(2)}%',
              description: 'Porcentaje disponible en los últimos 30 días',
              icon: Icons.verified_outlined,
              color: FiconColors.cyanSoft,
            ),
            InsightMetricCard(
              width: width,
              title: 'Incidentes totales',
              value: '${device.incidentCount}',
              description:
                  '${metrics.incidentsLast30Days} en los últimos 30 días',
              icon: Icons.warning_amber_rounded,
              color: FiconColors.logoBlue,
            ),
            InsightMetricCard(
              width: width,
              title: 'Indisponibilidad total',
              value: formatDurationSeconds(device.totalDowntimeSeconds),
              description: 'Tiempo acumulado sin energía',
              icon: Icons.power_off_outlined,
              color: StatusColors.offline,
            ),
            InsightMetricCard(
              width: width,
              title: 'Duración promedio',
              value: formatDurationSeconds(metrics.averageDowntimeSeconds),
              description: 'Promedio de todos los incidentes',
              icon: Icons.timer_outlined,
              color: FiconColors.cyanSoft,
            ),
            InsightMetricCard(
              width: width,
              title: 'Corte más largo',
              value: formatDurationSeconds(metrics.longestDowntimeSeconds),
              description: 'Mayor duración registrada',
              icon: Icons.hourglass_bottom_outlined,
              color: FiconColors.logoBlue,
            ),
            InsightMetricCard(
              width: width,
              title: 'Actividad reciente',
              value: '${metrics.incidentsLast7Days} / 7 días',
              description:
                  '${metrics.incidentsLast90Days} incidentes en 90 días',
              icon: Icons.monitor_heart_outlined,
              color: FiconColors.cyanSoft,
            ),
          ],
        );
      },
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.detail});

  final DeviceDetail detail;

  List<FrequencyPoint> _points(List<DeviceFrequencyPoint> values) => values
      .map((value) => FrequencyPoint(label: value.label, count: value.count))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 840
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: FrequencyBarChart(
                title: 'Últimos 7 días',
                subtitle: 'Frecuencia diaria de cortes',
                icon: Icons.calendar_view_week_outlined,
                color: FiconColors.logoBlue,
                points: _points(detail.dailyIncidents),
              ),
            ),
            SizedBox(
              width: width,
              child: FrequencyBarChart(
                title: 'Últimas 4 semanas',
                subtitle: 'Frecuencia semanal de cortes',
                icon: Icons.date_range_outlined,
                color: FiconColors.cyanSoft,
                points: _points(detail.weeklyIncidents),
              ),
            ),
            SizedBox(
              width: width,
              child: FrequencyBarChart(
                title: 'Últimos 6 meses',
                subtitle: 'Tendencia mensual de incidentes',
                icon: Icons.bar_chart_outlined,
                color: FiconColors.logoBlue,
                points: _points(detail.monthlyIncidents),
              ),
            ),
            SizedBox(
              width: width,
              child: FrequencyBarChart(
                title: 'Días de la semana',
                subtitle: 'Distribución histórica de cortes',
                icon: Icons.today_outlined,
                color: FiconColors.logoBlue,
                points: _points(detail.weekdayIncidents),
              ),
            ),
            SizedBox(
              width: width,
              child: FrequencyBarChart(
                title: 'Horario de ocurrencia',
                subtitle: 'Distribución histórica por franja horaria',
                icon: Icons.schedule_outlined,
                color: FiconColors.cyanSoft,
                points: _points(detail.timeOfDayIncidents),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentDeviceIncidents extends StatelessWidget {
  const _RecentDeviceIncidents({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardSectionHeader(
              icon: Icons.history,
              color: FiconColors.cyanSoft,
              title: 'Incidentes recientes',
              subtitle:
                  'Los últimos 10 cortes registrados para este dispositivo',
            ),
            const SizedBox(height: 8),
            if (incidents.isEmpty)
              const EmptyNote('No hay incidentes registrados.')
            else
              for (var index = 0; index < incidents.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    incidents[index].isOpen
                        ? Icons.error_outline
                        : Icons.task_alt,
                    color: incidents[index].isOpen
                        ? StatusColors.offline
                        : StatusColors.online,
                  ),
                  title: Text(
                    'Inicio: ${formatDateTime(incidents[index].startTime)}',
                  ),
                  subtitle: Text(
                    'Duración: ${formatDurationSeconds(incidents[index].durationSeconds)}',
                  ),
                  trailing: IncidentStatusChip(status: incidents[index].status),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

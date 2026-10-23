import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/device_detail.dart';
import '../../domain/realtime_change.dart';
import '../../ports/input/get_device_detail.dart';
import '../dashboard/dashboard_section_header.dart';
import '../dashboard/frequency_bar_chart.dart';
import '../dashboard/insight_metric_card.dart';
import '../devices/device_detail_widgets.dart';
import '../events/mobile/event_cards.dart';
import '../incidents/mobile/incident_cards.dart';
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
    this.realtimeChanges,
  });

  final String deviceId;
  final String initialDeviceName;
  final GetDeviceDetail getDeviceDetail;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  static const _refreshInterval = Duration(minutes: 3);

  late Future<DeviceDetail> _future;
  Timer? _timer;
  Timer? _realtimeDebounce;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = widget.getDeviceDetail(widget.deviceId);
    _timer = Timer.periodic(_refreshInterval, (_) => _refresh());
    _realtimeSubscription = widget.realtimeChanges
        ?.where(_affectsThisDevice)
        .listen(_scheduleRealtimeRefresh);
  }

  bool _affectsThisDevice(RealtimeChange change) {
    if (change.entityType == 'device' && change.entityId == widget.deviceId) {
      return true;
    }
    return const {'incident', 'event'}.contains(change.entityType) &&
        change.payload['deviceId']?.toString() == widget.deviceId;
  }

  void _scheduleRealtimeRefresh(RealtimeChange _) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_refresh()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() {
      _future = widget.getDeviceDetail(widget.deviceId);
    });
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
      realtimeChanges: widget.realtimeChanges,
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

enum _DeviceHistoryView { incidents, events }

class _DeviceDetailBody extends StatefulWidget {
  const _DeviceDetailBody({required this.detail, required this.onRefresh});

  final DeviceDetail detail;
  final Future<void> Function() onRefresh;

  @override
  State<_DeviceDetailBody> createState() => _DeviceDetailBodyState();
}

class _DeviceDetailBodyState extends State<_DeviceDetailBody> {
  _DeviceHistoryView _historyView = _DeviceHistoryView.incidents;

  @override
  Widget build(BuildContext context) {
    final device = widget.detail.device;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
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
                    _Metrics(detail: widget.detail),
                    const SizedBox(height: 16),
                    _Charts(detail: widget.detail),
                    const SizedBox(height: 16),
                    _DeviceHistory(
                      detail: widget.detail,
                      selection: _historyView,
                      onSelectionChanged: (value) =>
                          setState(() => _historyView = value),
                    ),
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
                compactDates: true,
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

class _DeviceHistory extends StatelessWidget {
  const _DeviceHistory({
    required this.detail,
    required this.selection,
    required this.onSelectionChanged,
  });

  final DeviceDetail detail;
  final _DeviceHistoryView selection;
  final ValueChanged<_DeviceHistoryView> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
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
                    icon: Icons.history,
                    color: FiconColors.cyanSoft,
                    title: 'Historial del dispositivo',
                    subtitle: 'Últimos incidentes y eventos recibidos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_DeviceHistoryView>(
                segments: const [
                  ButtonSegment(
                    value: _DeviceHistoryView.incidents,
                    icon: Icon(Icons.warning_amber_outlined),
                    label: Text('Incidentes'),
                  ),
                  ButtonSegment(
                    value: _DeviceHistoryView.events,
                    icon: Icon(Icons.event_note_outlined),
                    label: Text('Eventos'),
                  ),
                ],
                selected: {selection},
                showSelectedIcon: false,
                onSelectionChanged: (values) =>
                    onSelectionChanged(values.first),
              ),
            ),
            const SizedBox(height: 8),
            if (selection == _DeviceHistoryView.incidents)
              MobileIncidentList(
                incidents: detail.recentIncidents,
                emptyMessage:
                    'Este dispositivo todavía no tiene incidentes registrados.',
              )
            else
              MobileEventList(events: detail.recentEvents),
          ],
        ),
      ),
    );
  }
}

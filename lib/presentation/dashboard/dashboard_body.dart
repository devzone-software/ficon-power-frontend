import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../domain/operations_calendar.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_analytics_section.dart';
import 'dashboard_kpi_card.dart';
import 'fleet_health_card.dart';
import 'frequency_dot_chart.dart';
import 'mobile_app_download_card.dart';
import 'offline_devices_card.dart';
import 'recent_incidents_card.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.data,
    required this.tuyaPlans,
    required this.canAcknowledgeIncidents,
    required this.acknowledgingIncidentIds,
    required this.onAcknowledgeIncident,
  });

  final MonitoringOverview data;
  final List<TuyaPlan> tuyaPlans;
  final bool canAcknowledgeIncidents;
  final Set<String> acknowledgingIncidentIds;
  final ValueChanged<Incident> onAcknowledgeIncident;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final stats = DashboardStatistics.from(data);
    if (mobile) {
      return _MobileDashboard(
        stats: stats,
        plans: tuyaPlans,
        totalDevices: data.devices.length,
        onlineDevices: data.onlineCount,
      );
    }
    final offlineDevices = data.devices
        .where((device) => !device.isOnline && device.active)
        .toList();
    final recentIncidents = data.incidents.take(6).toList();
    final unresolvedIncidents = data.incidents
        .where((incident) => incident.isAwaitingAttention)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(mobile ? 12 : 24),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _KpiGrid(data: data),
                SizedBox(height: mobile ? 14 : 24),
                if (unresolvedIncidents.isNotEmpty) ...[
                  ActiveIncidentsActionCard(
                    incidents: unresolvedIncidents,
                    canAcknowledge: canAcknowledgeIncidents,
                    acknowledgingIncidentIds: acknowledgingIncidentIds,
                    onAcknowledge: onAcknowledgeIncident,
                  ),
                  SizedBox(height: mobile ? 14 : 24),
                ],
                FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                SizedBox(height: mobile ? 14 : 24),
                DashboardAnalyticsSection(stats: stats),
                SizedBox(height: mobile ? 14 : 24),
                _StatusLists(
                  offlineDevices: offlineDevices,
                  recentIncidents: recentIncidents,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 24),
                  const MobileAppDownloadCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.stats,
    required this.plans,
    required this.totalDevices,
    required this.onlineDevices,
  });

  final DashboardStatistics stats;
  final List<TuyaPlan> plans;
  final int totalDevices;
  final int onlineDevices;

  @override
  Widget build(BuildContext context) {
    final activePlans = plans.where((plan) => plan.active).toList()
      ..sort(
        (first, second) => first.nextRenewalOn.compareTo(second.nextRenewalOn),
      );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        _TuyaRenewalSummary(
          plan: activePlans.isEmpty ? null : activePlans.first,
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MobileMetricCard(
                  title: 'Apagados registrados',
                  value: '${stats.totalPowerOutages}',
                  icon: Icons.power_off_outlined,
                  color: FiconColors.logoBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileMetricCard(
                  title: 'Esta semana',
                  value: '${stats.currentWeekPowerOutages}',
                  icon: Icons.date_range_outlined,
                  color: FiconColors.cyanSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MobileFleetSummary(total: totalDevices, online: onlineDevices),
        const SizedBox(height: 12),
        FrequencyDotChart(
          title: 'Cortes del mes',
          subtitle: 'Número de cortes por cada día del mes actual',
          points: stats.currentMonthDailyIncidents,
        ),
      ],
    );
  }
}

class _MobileFleetSummary extends StatelessWidget {
  const _MobileFleetSummary({required this.total, required this.online});

  final int total;
  final int online;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0
        ? 0.0
        : (online / total).clamp(0.0, 1.0).toDouble();
    final percentage = (ratio * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _FleetValue(value: '$total', label: 'Dispositivos'),
                ),
                const _FleetDivider(),
                Expanded(
                  child: _FleetValue(value: '$online', label: 'En línea'),
                ),
                const _FleetDivider(),
                Expanded(
                  child: _FleetValue(
                    value: '$percentage %',
                    label: 'Disponibilidad',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: FiconColors.cardBorderSoft,
                color: FiconColors.logoBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetValue extends StatelessWidget {
  const _FleetValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: FiconColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: FiconColors.slate),
        ),
      ],
    );
  }
}

class _FleetDivider extends StatelessWidget {
  const _FleetDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 34,
    child: VerticalDivider(color: FiconColors.cardBorderSoft, width: 8),
  );
}

class _MobileMetricCard extends StatelessWidget {
  const _MobileMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: FiconColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: FiconColors.deepAlt,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuyaRenewalSummary extends StatelessWidget {
  const _TuyaRenewalSummary({required this.plan});

  final TuyaPlan? plan;

  @override
  Widget build(BuildContext context) {
    final current = plan;
    if (current == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.event_busy_outlined),
          title: Text('Renovación de Tuya Developer'),
          subtitle: Text('No hay una fecha de renovación registrada.'),
        ),
      );
    }
    final days = current.daysUntilRenewal();
    final date = current.nextRenewalOn;
    final daysText = switch (days) {
      < 0 => 'Venció hace ${-days} día${days == -1 ? '' : 's'}',
      0 => 'Vence hoy',
      _ => '$days día${days == 1 ? '' : 's'} restantes',
    };
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: FiconColors.cardBorderSoft,
          foregroundColor: FiconColors.logoBlue,
          child: Icon(Icons.event_available_outlined),
        ),
        title: const Text(
          'Renovación de Tuya Developer',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$daysText\nVencimiento: ${_date(date)}'),
        isThreeLine: true,
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final MonitoringOverview data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = width >= 560 ? 16.0 : 10.0;
        final cardWidth = width >= 900
            ? (width - 3 * spacing) / 4
            : (width - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            DashboardKpiCard(
              title: 'Sedes',
              value: '${data.sites.length}',
              icon: Icons.business,
              color: FiconColors.logoBlue,
              width: cardWidth,
              compact: width < 560,
            ),
            DashboardKpiCard(
              title: 'Dispositivos',
              value: '${data.devices.length}',
              icon: Icons.electrical_services,
              color: FiconColors.cyanSoft,
              width: cardWidth,
              compact: width < 560,
            ),
            DashboardKpiCard(
              title: 'En línea',
              value: '${data.onlineCount}',
              icon: Icons.check_circle_outline,
              color: StatusColors.online,
              width: cardWidth,
              compact: width < 560,
            ),
            DashboardKpiCard(
              title: 'Incidentes activos',
              value: '${data.openIncidents}',
              icon: Icons.warning_amber,
              color: data.openIncidents > 0
                  ? StatusColors.offline
                  : StatusColors.online,
              width: cardWidth,
              compact: width < 560,
            ),
          ],
        );
      },
    );
  }
}

class ActiveIncidentsActionCard extends StatelessWidget {
  const ActiveIncidentsActionCard({
    super.key,
    required this.incidents,
    required this.canAcknowledge,
    required this.acknowledgingIncidentIds,
    required this.onAcknowledge,
  });

  final List<Incident> incidents;
  final bool canAcknowledge;
  final Set<String> acknowledgingIncidentIds;
  final ValueChanged<Incident> onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: incidents.isEmpty
                        ? FiconColors.cyanSoft.withValues(alpha: 0.14)
                        : StatusColors.offline.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    incidents.isEmpty
                        ? Icons.task_alt_outlined
                        : Icons.notification_important_outlined,
                    color: incidents.isEmpty
                        ? StatusColors.online
                        : StatusColors.offline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidents.isEmpty
                            ? 'Sin incidentes pendientes'
                            : 'Incidentes no resueltos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        incidents.isEmpty
                            ? 'No hay cortes pendientes de resolución.'
                            : '${incidents.length} corte${incidents.length == 1 ? '' : 's'} pendiente${incidents.length == 1 ? '' : 's'} de resolución',
                        style: const TextStyle(color: FiconColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (incidents.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (var index = 0; index < incidents.length; index++) ...[
                if (index > 0)
                  const Divider(height: 18, color: FiconColors.cardBorderSoft),
                _ActiveIncidentTile(
                  incident: incidents[index],
                  canAcknowledge: canAcknowledge,
                  acknowledging: acknowledgingIncidentIds.contains(
                    incidents[index].id,
                  ),
                  onAcknowledge: onAcknowledge,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveIncidentTile extends StatelessWidget {
  const _ActiveIncidentTile({
    required this.incident,
    required this.canAcknowledge,
    required this.acknowledging,
    required this.onAcknowledge,
  });

  final Incident incident;
  final bool canAcknowledge;
  final bool acknowledging;
  final ValueChanged<Incident> onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final details = Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _IncidentMeta(
          icon: Icons.business_outlined,
          value: incident.siteName ?? 'Sin sede',
        ),
        _IncidentMeta(
          icon: Icons.schedule,
          value: formatDateTime(incident.startTime),
        ),
        _IncidentMeta(
          icon: Icons.timer_outlined,
          value: formatDurationSeconds(incident.durationSeconds),
        ),
      ],
    );
    final action = canAcknowledge
        ? FilledButton.tonalIcon(
            onPressed: acknowledging ? null : () => onAcknowledge(incident),
            icon: acknowledging
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt, size: 18),
            label: Text(acknowledging ? 'Atendiendo…' : 'Atender'),
          )
        : IncidentStatusChip(status: incident.status);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.deviceName ?? 'Dispositivo desconocido',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          details,
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: action),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.deviceName ?? 'Dispositivo desconocido',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              details,
            ],
          ),
        ),
        const SizedBox(width: 16),
        action,
      ],
    );
  }
}

class _IncidentMeta extends StatelessWidget {
  const _IncidentMeta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: FiconColors.deepAlt),
      const SizedBox(width: 5),
      Text(value, style: const TextStyle(color: FiconColors.slate)),
    ],
  );
}

class _StatusLists extends StatelessWidget {
  const _StatusLists({
    required this.offlineDevices,
    required this.recentIncidents,
  });

  final List<Device> offlineDevices;
  final List<Incident> recentIncidents;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final offline = OfflineDevicesCard(devices: offlineDevices);
        final incidents = RecentIncidentsCard(incidents: recentIncidents);
        if (constraints.maxWidth < 900) {
          return Column(
            children: [offline, const SizedBox(height: 24), incidents],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: offline),
            const SizedBox(width: 24),
            Expanded(child: incidents),
          ],
        );
      },
    );
  }
}

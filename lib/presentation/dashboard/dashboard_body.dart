import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/dashboard_statistics.dart';
import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../ports/input/get_notification_templates.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_analytics_section.dart';
import 'dashboard_kpi_card.dart';
import 'dashboard_overview_header.dart';
import 'fleet_health_card.dart';
import 'mobile_app_download_card.dart';
import 'notification_templates_card.dart';
import 'offline_devices_card.dart';
import 'recent_incidents_card.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.data,
    required this.getNotificationTemplates,
    required this.canAcknowledgeIncidents,
    required this.onAcknowledgeIncident,
  });

  final MonitoringOverview data;
  final GetNotificationTemplates getNotificationTemplates;
  final bool canAcknowledgeIncidents;
  final ValueChanged<Incident> onAcknowledgeIncident;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final offlineDevices = data.devices
        .where((device) => !device.isOnline && device.active)
        .toList();
    final recentIncidents = data.incidents.take(6).toList();
    final unresolvedIncidents = data.incidents
        .where((incident) => incident.isOpen)
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
                DashboardOverviewHeader(
                  online: data.onlineCount,
                  total: data.devices.length,
                  openIncidents: data.openIncidents,
                ),
                SizedBox(height: mobile ? 14 : 24),
                _KpiGrid(data: data),
                SizedBox(height: mobile ? 14 : 24),
                if (unresolvedIncidents.isNotEmpty) ...[
                  ActiveIncidentsActionCard(
                    incidents: unresolvedIncidents,
                    canAcknowledge: canAcknowledgeIncidents,
                    onAcknowledge: onAcknowledgeIncident,
                  ),
                  SizedBox(height: mobile ? 14 : 24),
                ],
                FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                SizedBox(height: mobile ? 14 : 24),
                DashboardAnalyticsSection(
                  stats: DashboardStatistics.from(data),
                ),
                SizedBox(height: mobile ? 14 : 24),
                _StatusLists(
                  offlineDevices: offlineDevices,
                  recentIncidents: recentIncidents,
                ),
                SizedBox(height: mobile ? 14 : 24),
                NotificationTemplatesCard(
                  getNotificationTemplates: getNotificationTemplates,
                ),
                if (kIsWeb) ...[
                  SizedBox(height: mobile ? 14 : 24),
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
    required this.onAcknowledge,
  });

  final List<Incident> incidents;
  final bool canAcknowledge;
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
    required this.onAcknowledge,
  });

  final Incident incident;
  final bool canAcknowledge;
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
            onPressed: () => onAcknowledge(incident),
            icon: const Icon(Icons.task_alt, size: 18),
            label: const Text('Atender'),
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

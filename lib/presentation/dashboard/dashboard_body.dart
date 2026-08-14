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
  });

  final MonitoringOverview data;
  final GetNotificationTemplates getNotificationTemplates;

  @override
  Widget build(BuildContext context) {
    final offlineDevices = data.devices
        .where((device) => !device.isOnline && device.active)
        .toList();
    final recentIncidents = data.incidents.take(6).toList();

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
                DashboardOverviewHeader(
                  online: data.onlineCount,
                  total: data.devices.length,
                  openIncidents: data.openIncidents,
                ),
                const SizedBox(height: 24),
                _KpiGrid(data: data),
                const SizedBox(height: 24),
                FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                const SizedBox(height: 24),
                DashboardAnalyticsSection(
                  stats: DashboardStatistics.from(data),
                ),
                const SizedBox(height: 24),
                _StatusLists(
                  offlineDevices: offlineDevices,
                  recentIncidents: recentIncidents,
                ),
                const SizedBox(height: 24),
                NotificationTemplatesCard(
                  getNotificationTemplates: getNotificationTemplates,
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

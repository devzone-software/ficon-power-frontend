import 'package:flutter/material.dart';

import '../../domain/incident.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_section_header.dart';

class RecentIncidentsCard extends StatelessWidget {
  const RecentIncidentsCard({super.key, required this.incidents});

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
              subtitle: 'Historial de cortes y retornos reportados',
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
                    incidents[index].deviceName ?? 'Dispositivo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${incidents[index].siteName ?? 'Sin sede'} · '
                    '${formatDateTime(incidents[index].startTime)}',
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

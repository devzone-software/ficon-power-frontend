import 'package:flutter/material.dart';

import '../../../domain/incident.dart';
import '../../theme/ficon_theme.dart';
import '../../widgets/common.dart';

class MobileIncidentList extends StatelessWidget {
  const MobileIncidentList({
    super.key,
    required this.incidents,
  });

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('No hay incidentes con esos filtros.'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
      itemCount: incidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: StatusColors.offline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        incident.deviceName ?? 'Dispositivo desconocido',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IncidentStatusChip(status: incident.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(incident.siteName ?? 'Sin sede'),
                const Divider(height: 22),
                _IncidentDetail(
                  label: 'Inicio',
                  value: formatDateTime(incident.startTime),
                ),
                _IncidentDetail(
                  label: 'Fin',
                  value: formatDateTime(incident.endTime),
                ),
                _IncidentDetail(
                  label: 'Duración',
                  value: formatDurationSeconds(incident.durationSeconds),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IncidentDetail extends StatelessWidget {
  const _IncidentDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(label, style: const TextStyle(color: FiconColors.slate)),
        ),
        Expanded(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}

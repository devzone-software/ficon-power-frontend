import 'package:flutter/material.dart';

import '../../../domain/event.dart';
import '../../theme/ficon_theme.dart';
import '../../widgets/common.dart';

class MobileEventList extends StatelessWidget {
  const MobileEventList({super.key, required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('No hay eventos registrados para este dispositivo.'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = events[index];
        final outage = event.eventType == 'power_outage';
        return Card(
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor:
                  (outage ? StatusColors.offline : FiconColors.cyan).withValues(
                    alpha: 0.12,
                  ),
              child: Icon(
                outage ? Icons.power_off_outlined : Icons.power_outlined,
                color: outage ? StatusColors.offline : FiconColors.cyan,
              ),
            ),
            title: Text(
              event.deviceName ?? 'Dispositivo desconocido',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.siteName ?? 'Sin sede'),
                  Text(formatDateTime(event.occurredAt)),
                  Text('Latencia: ${event.deliveryLatencyMillis} ms'),
                ],
              ),
            ),
            trailing: Text(
              event.eventType,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      },
    );
  }
}

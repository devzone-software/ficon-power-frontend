import 'package:flutter/material.dart';

import '../../domain/event.dart';
import '../../ports/input/get_events.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Tabla de eventos Tuya recibidos por el backend.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.getEvents});

  final GetEvents getEvents;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getEvents();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.getEvents());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.events,
      title: 'Eventos',
      body: FutureBuilder<List<Event>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('No hay eventos registrados.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: _EventsTable(events: events),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventsTable extends StatelessWidget {
  const _EventsTable({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Tipo')),
        DataColumn(label: Text('Dispositivo')),
        DataColumn(label: Text('Sede')),
        DataColumn(label: Text('Ocurrió')),
        DataColumn(label: Text('Latencia'), numeric: true),
      ],
      rows: [
        for (final event in events)
          DataRow(
            cells: [
              DataCell(Text(event.eventType)),
              DataCell(Text(event.deviceName ?? '—')),
              DataCell(Text(event.siteName ?? '—')),
              DataCell(Text(formatDateTime(event.occurredAt))),
              DataCell(Text('${event.deliveryLatencyMillis} ms')),
            ],
          ),
      ],
    );
  }
}

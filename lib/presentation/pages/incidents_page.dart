import 'package:flutter/material.dart';

import '../../domain/incident.dart';
import '../../ports/input/get_incidents.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Tabla de incidentes de corte de energía.
class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key, required this.getIncidents});

  final GetIncidents getIncidents;

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  late Future<List<Incident>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getIncidents();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.getIncidents());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.incidents,
      title: 'Incidentes',
      body: FutureBuilder<List<Incident>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final incidents = snapshot.data!;
          if (incidents.isEmpty) {
            return const Center(
              child: Text('No hay incidentes registrados.'),
            );
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
                    child: _IncidentsTable(incidents: incidents),
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

class _IncidentsTable extends StatelessWidget {
  const _IncidentsTable({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Dispositivo')),
        DataColumn(label: Text('Sede')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Inicio')),
        DataColumn(label: Text('Fin')),
        DataColumn(label: Text('Duración')),
      ],
      rows: [
        for (final incident in incidents)
          DataRow(
            cells: [
              DataCell(Text(incident.deviceName ?? '—')),
              DataCell(Text(incident.siteName ?? '—')),
              DataCell(IncidentStatusChip(status: incident.status)),
              DataCell(Text(formatDateTime(incident.startTime))),
              DataCell(Text(formatDateTime(incident.endTime))),
              DataCell(
                Text(formatDurationSeconds(incident.durationSeconds)),
              ),
            ],
          ),
      ],
    );
  }
}

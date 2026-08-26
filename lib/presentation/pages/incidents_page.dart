import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/incident.dart';
import '../../ports/input/get_incidents.dart';
import '../incidents/mobile/incident_cards.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/table_filters.dart';

/// Tabla de incidentes de corte de energía.
class IncidentsPage extends StatefulWidget {
  const IncidentsPage({
    super.key,
    required this.getIncidents,
    required this.currentUser,
    required this.onLogout,
  });

  final GetIncidents getIncidents;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  static const _autoRefreshInterval = Duration(seconds: 10);

  late Future<List<Incident>> _future;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;
  final ColumnFilterState _columnFilters = ColumnFilterState();

  @override
  void initState() {
    super.initState();
    _future = widget.getIncidents();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = widget.getIncidents());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.incidents,
      title: 'Incidentes',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
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
          final filteredIncidents = _columnFilters.sortedNumeric(
            'duration',
            incidents.where(_matchesFilters),
            (incident) => incident.durationSeconds ?? 0,
          );
          if (incidents.isEmpty) {
            return const Center(child: Text('No hay incidentes registrados.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableFiltersBar(filters: _filters(incidents)),
                    if (constraints.maxWidth < 720)
                      MobileIncidentList(incidents: filteredIncidents)
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: _IncidentsTable(incidents: filteredIncidents),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _filters(List<Incident> incidents) {
    if (MediaQuery.sizeOf(context).width < 720) {
      return [
        TextColumnFilter(
          label: 'Buscar incidente',
          hint: 'Dispositivo o sede',
          value: _columnFilters.text('query'),
          options: mergeFilterOptions([
            uniqueColumnOptions(incidents, (incident) => incident.deviceName),
            uniqueColumnOptions(incidents, (incident) => incident.siteName),
          ]),
          wideOnMobile: true,
          onChanged: (value) =>
              setState(() => _columnFilters.setText('query', value)),
        ),
        _statusFilter(),
        OptionsChipFilter(
          label: 'Sede',
          value: _columnFilters.text('site'),
          options: uniqueColumnOptions(
            incidents,
            (incident) => incident.siteName,
          ),
          onChanged: (value) =>
              setState(() => _columnFilters.setText('site', value)),
        ),
        DateColumnFilter(
          label: 'Inicio',
          value: _columnFilters.date('startTime'),
          onChanged: (value) =>
              setState(() => _columnFilters.setDate('startTime', value)),
        ),
        DateColumnFilter(
          label: 'Fin',
          value: _columnFilters.date('endTime'),
          onChanged: (value) =>
              setState(() => _columnFilters.setDate('endTime', value)),
        ),
        _durationSort(),
      ];
    }
    return [
      _textFilter(
        keyName: 'device',
        label: 'Dispositivo',
        options: uniqueColumnOptions(
          incidents,
          (incident) => incident.deviceName,
        ),
      ),
      _selectFilter(
        keyName: 'site',
        label: 'Sede',
        options: uniqueColumnOptions(
          incidents,
          (incident) => incident.siteName,
        ),
      ),
      _statusFilter(),
      DateColumnFilter(
        label: 'Inicio',
        value: _columnFilters.date('startTime'),
        onChanged: (value) =>
            setState(() => _columnFilters.setDate('startTime', value)),
      ),
      DateColumnFilter(
        label: 'Fin',
        value: _columnFilters.date('endTime'),
        onChanged: (value) =>
            setState(() => _columnFilters.setDate('endTime', value)),
      ),
      _durationSort(),
    ];
  }

  Widget _statusFilter() => ChoiceColumnFilter(
    label: 'Estado',
    value: _columnFilters.text('status'),
    options: const ['Activo', 'Atendido', 'Resuelto'],
    onChanged: (value) =>
        setState(() => _columnFilters.setText('status', value)),
  );

  Widget _durationSort() => SortColumnControl(
    label: 'Ordenar por duración',
    value: _columnFilters.sort('duration'),
    onChanged: (value) =>
        setState(() => _columnFilters.setSort('duration', value)),
  );

  Widget _textFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return TextColumnFilter(
      label: label,
      value: _columnFilters.text(keyName),
      options: options,
      width: width,
      onChanged: (value) =>
          setState(() => _columnFilters.setText(keyName, value)),
    );
  }

  Widget _selectFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return SelectColumnFilter(
      label: label,
      value: _columnFilters.text(keyName),
      options: options,
      width: width,
      onChanged: (value) =>
          setState(() => _columnFilters.setText(keyName, value)),
    );
  }

  bool _matchesFilters(Incident incident) {
    return _columnFilters.matchesAnyText('query', [
          incident.deviceName,
          incident.siteName,
        ]) &&
        _columnFilters.matchesText('device', incident.deviceName) &&
        _columnFilters.matchesChoice('site', incident.siteName) &&
        _columnFilters.matchesChoice(
          'status',
          _incidentStatusLabel(incident.status),
        ) &&
        _columnFilters.matchesDate('startTime', incident.startTime) &&
        _columnFilters.matchesDate('endTime', incident.endTime);
  }
}

String _incidentStatusLabel(String status) => switch (status) {
  'active' => 'Activo',
  'acknowledged' => 'Atendido',
  'resolved' => 'Resuelto',
  _ => status,
};

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
              DataCell(Text(formatDurationSeconds(incident.durationSeconds))),
            ],
          ),
      ],
    );
  }
}

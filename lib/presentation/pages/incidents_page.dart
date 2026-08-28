import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/incident.dart';
import '../../domain/paged_result.dart';
import '../../ports/input/get_incidents.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/pagination_controls.dart';
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
  static const _pageSize = 10;

  late Future<PagedResult<Incident>> _future;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;
  int _page = 0;
  final Map<String, String> _textFilters = {};
  final Map<String, DateTime?> _dateFilters = {};

  @override
  void initState() {
    super.initState();
    _future = _loadPage();
    _autoRefreshTimer = Timer.periodic(
      _autoRefreshInterval,
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = _loadPage());
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
      body: FutureBuilder<PagedResult<Incident>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          final incidents = result.items;
          if (incidents.isEmpty && result.totalItems == 0) {
            return const Center(
              child: Text('No hay incidentes registrados.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableFiltersBar(filters: _filters(incidents)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: _IncidentsTable(incidents: incidents),
                      ),
                    ),
                    PaginationControls<Incident>(
                      page: result,
                      onPageChanged: _changePage,
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

  Future<PagedResult<Incident>> _loadPage() {
    return widget.getIncidents.page(
      page: _page,
      size: _pageSize,
      search: _textFilters['search'] ?? '',
      status: _statusValue(_textFilters['status'] ?? ''),
      deviceName: _textFilters['device'] ?? '',
      siteName: _textFilters['site'] ?? '',
      startDate: _dateFilters['startTime'],
      endDate: _dateFilters['endTime'],
    );
  }

  void _changePage(int page) {
    if (page == _page || page < 0) return;
    setState(() {
      _page = page;
      _future = _loadPage();
    });
  }

  void _updateTextFilter(String keyName, String value) {
    setState(() {
      _page = 0;
      _textFilters[keyName] = value;
      _future = _loadPage();
    });
  }

  void _updateDateFilter(String keyName, DateTime? value) {
    setState(() {
      _page = 0;
      _dateFilters[keyName] = value;
      _future = _loadPage();
    });
  }

  List<Widget> _filters(List<Incident> incidents) => [
        _textFilter(
          keyName: 'search',
          label: 'Buscar',
          options: uniqueColumnOptions(
            incidents,
            (incident) => '${incident.deviceName ?? ''} ${incident.siteName ?? ''} ${_incidentStatusLabel(incident.status)}',
          ),
        ),
        _textFilter(
          keyName: 'device',
          label: 'Dispositivo',
          options: uniqueColumnOptions(incidents, (incident) => incident.deviceName),
        ),
        _textFilter(
          keyName: 'site',
          label: 'Sede',
          options: uniqueColumnOptions(incidents, (incident) => incident.siteName),
        ),
        _textFilter(
          keyName: 'status',
          label: 'Estado',
          options: uniqueColumnOptions(incidents, (incident) => _incidentStatusLabel(incident.status)),
        ),
        DateColumnFilter(
          label: 'Inicio',
          value: _dateFilters['startTime'],
          onChanged: (value) => _updateDateFilter('startTime', value),
        ),
        DateColumnFilter(
          label: 'Fin',
          value: _dateFilters['endTime'],
          onChanged: (value) => _updateDateFilter('endTime', value),
        ),
      ];

  Widget _textFilter({
    required String keyName,
    required String label,
    required List<String> options,
    double width = 220,
  }) {
    return TextColumnFilter(
      label: label,
      value: _textFilters[keyName] ?? '',
      options: options,
      width: width,
      onChanged: (value) => _updateTextFilter(keyName, value),
    );
  }
}

String _incidentStatusLabel(String status) => switch (status) {
      'active' => 'Activo',
      'acknowledged' => 'Atendido',
      'resolved' => 'Resuelto',
      _ => status,
    };

String _statusValue(String label) => switch (label) {
      'Activo' => 'active',
      'Atendido' => 'acknowledged',
      'Resuelto' => 'resolved',
      _ => label,
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
              DataCell(
                Text(formatDurationSeconds(incident.durationSeconds)),
              ),
            ],
          ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/incident.dart';
import '../../domain/paged_result.dart';
import '../../ports/input/get_incidents.dart';
import '../incidents/mobile/incident_cards.dart';
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
  Timer? _filterDebounce;
  bool _refreshing = false;
  int _page = 0;
  final ColumnFilterState _columnFilters = ColumnFilterState();

  @override
  void initState() {
    super.initState();
    _future = _loadPage();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
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
    _filterDebounce?.cancel();
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
          final filteredIncidents = _columnFilters.sortedNumeric(
            'duration',
            incidents,
            (incident) => incident.durationSeconds ?? 0,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableFiltersBar(filters: _filters(incidents)),
                    if (incidents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No hay incidentes registrados.'),
                      )
                    else if (constraints.maxWidth < 720)
                      MobileIncidentList(
                        incidents: filteredIncidents,
                        onAcknowledge: widget.currentUser.canAccessAdmin
                            ? _acknowledgeIncident
                            : null,
                      )
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
          onChanged: (value) => _setTextFilter('query', value),
        ),
        _statusFilter(),
        OptionsChipFilter(
          label: 'Sede',
          value: _columnFilters.text('site'),
          options: uniqueColumnOptions(
            incidents,
            (incident) => incident.siteName,
          ),
          onChanged: (value) => _setTextFilter('site', value),
        ),
        DateColumnFilter(
          label: 'Inicio',
          value: _columnFilters.date('startTime'),
          onChanged: (value) => _setDateFilter('startTime', value),
        ),
        DateColumnFilter(
          label: 'Fin',
          value: _columnFilters.date('endTime'),
          onChanged: (value) => _setDateFilter('endTime', value),
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
        onChanged: (value) => _setDateFilter('startTime', value),
      ),
      DateColumnFilter(
        label: 'Fin',
        value: _columnFilters.date('endTime'),
        onChanged: (value) => _setDateFilter('endTime', value),
      ),
      _durationSort(),
    ];
  }

  Widget _statusFilter() => ChoiceColumnFilter(
    label: 'Estado',
    value: _columnFilters.text('status'),
    options: const ['Activo', 'Atendido', 'Resuelto'],
    onChanged: (value) => _setTextFilter('status', value),
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
      onChanged: (value) => _setTextFilter(keyName, value),
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
      onChanged: (value) => _setTextFilter(keyName, value),
    );
  }

  Future<PagedResult<Incident>> _loadPage() {
    return widget.getIncidents.page(
      page: _page,
      size: _pageSize,
      search: _columnFilters.text('query'),
      status: _statusQueryValue(_columnFilters.text('status')),
      deviceName: _columnFilters.text('device'),
      siteName: _columnFilters.text('site'),
      startDate: _columnFilters.date('startTime'),
      endDate: _columnFilters.date('endTime'),
    );
  }

  void _changePage(int page) {
    setState(() {
      _page = page;
      _future = _loadPage();
    });
  }

  void _setTextFilter(String key, String value) {
    setState(() => _columnFilters.setText(key, value));
    _queueFilterRefresh();
  }

  void _setDateFilter(String key, DateTime? value) {
    setState(() => _columnFilters.setDate(key, value));
    _applyFiltersNow();
  }

  void _queueFilterRefresh() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(
      const Duration(milliseconds: 350),
      _applyFiltersNow,
    );
  }

  void _applyFiltersNow() {
    if (!mounted) return;
    setState(() {
      _page = 0;
      _future = _loadPage();
    });
  }

  Future<void> _acknowledgeIncident(Incident incident) async {
    try {
      await widget.getIncidents.acknowledge(incident.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Incidente atendido: ${incident.deviceName ?? 'dispositivo'}',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo atender el incidente: $error')),
      );
    }
  }
}

String _statusQueryValue(String label) => switch (label) {
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
              DataCell(Text(formatDurationSeconds(incident.durationSeconds))),
            ],
          ),
      ],
    );
  }
}

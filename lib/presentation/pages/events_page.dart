import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/event.dart';
import '../../domain/paged_result.dart';
import '../../ports/input/get_events.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/table_filters.dart';

/// Tabla de eventos Tuya recibidos por el backend.
class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
    required this.getEvents,
    required this.currentUser,
    required this.onLogout,
  });

  final GetEvents getEvents;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const _autoRefreshInterval = Duration(seconds: 10);
  static const _pageSize = 10;

  late Future<PagedResult<Event>> _future;
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
      currentRoute: AppRoutes.events,
      title: 'Eventos',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<PagedResult<Event>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          final events = result.items;
          if (events.isEmpty && result.totalItems == 0) {
            return const Center(child: Text('No hay eventos registrados.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableFiltersBar(filters: _filters(events)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: _EventsTable(events: events),
                      ),
                    ),
                    PaginationControls<Event>(
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

  Future<PagedResult<Event>> _loadPage() {
    return widget.getEvents.page(
      page: _page,
      size: _pageSize,
      search: _textFilters['search'] ?? '',
      eventType: _textFilters['type'] ?? '',
      deviceName: _textFilters['device'] ?? '',
      siteName: _textFilters['site'] ?? '',
      occurredDate: _dateFilters['occurredAt'],
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

  List<Widget> _filters(List<Event> events) => [
        _textFilter(
          keyName: 'search',
          label: 'Buscar',
          options: uniqueColumnOptions(
            events,
            (event) => '${event.eventType} ${event.deviceName ?? ''} ${event.siteName ?? ''}',
          ),
        ),
        _textFilter(
          keyName: 'type',
          label: 'Tipo',
          options: uniqueColumnOptions(events, (event) => event.eventType),
        ),
        _textFilter(
          keyName: 'device',
          label: 'Dispositivo',
          options: uniqueColumnOptions(events, (event) => event.deviceName),
        ),
        _textFilter(
          keyName: 'site',
          label: 'Sede',
          options: uniqueColumnOptions(events, (event) => event.siteName),
        ),
        DateColumnFilter(
          label: 'Ocurrió',
          value: _dateFilters['occurredAt'],
          onChanged: (value) => _updateDateFilter('occurredAt', value),
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

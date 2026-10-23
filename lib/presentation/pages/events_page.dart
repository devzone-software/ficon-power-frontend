import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../../domain/event.dart';
import '../../domain/paged_result.dart';
import '../../domain/realtime_change.dart';
import '../../ports/input/get_events.dart';
import '../events/mobile/event_cards.dart';
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
    this.realtimeChanges,
  });

  final GetEvents getEvents;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const _autoRefreshInterval = Duration(minutes: 3);
  static const _pageSize = 10;

  late Future<PagedResult<Event>> _future;
  Timer? _autoRefreshTimer;
  Timer? _filterDebounce;
  Timer? _realtimeDebounce;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  bool _refreshing = false;
  int _page = 0;
  final ColumnFilterState _columnFilters = ColumnFilterState();

  @override
  void initState() {
    super.initState();
    _future = _loadPage();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
    _realtimeSubscription = widget.realtimeChanges
        ?.where((change) => change.entityType == 'event')
        .listen(_scheduleRealtimeRefresh);
  }

  void _scheduleRealtimeRefresh(RealtimeChange _) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_refresh()),
    );
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() {
      _future = _loadPage();
    });
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
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.events,
      title: 'Eventos',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      realtimeChanges: widget.realtimeChanges,
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
          final filteredEvents = _columnFilters.sortedNumeric(
            'latency',
            events,
            (event) => event.deliveryLatencyMillis,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableFiltersBar(filters: _filters(events)),
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No hay eventos registrados.'),
                      )
                    else if (constraints.maxWidth < 720)
                      MobileEventList(events: filteredEvents)
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: _EventsTable(events: filteredEvents),
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

  List<Widget> _filters(List<Event> events) {
    if (MediaQuery.sizeOf(context).width < 720) {
      return [
        TextColumnFilter(
          label: 'Buscar evento',
          hint: 'Dispositivo o sede',
          value: _columnFilters.text('query'),
          options: mergeFilterOptions([
            uniqueColumnOptions(events, (event) => event.deviceName),
            uniqueColumnOptions(events, (event) => event.siteName),
          ]),
          wideOnMobile: true,
          onChanged: (value) => _setTextFilter('query', value),
        ),
        _typeFilter(),
        OptionsChipFilter(
          label: 'Sede',
          value: _columnFilters.text('site'),
          options: uniqueColumnOptions(events, (event) => event.siteName),
          onChanged: (value) => _setTextFilter('site', value),
        ),
        DateColumnFilter(
          label: 'Ocurrió',
          value: _columnFilters.date('occurredAt'),
          wideOnMobile: true,
          onChanged: (value) => _setDateFilter('occurredAt', value),
        ),
        _latencySort(),
      ];
    }
    return [
      _typeFilter(),
      _textFilter(
        keyName: 'device',
        label: 'Dispositivo',
        options: uniqueColumnOptions(events, (event) => event.deviceName),
      ),
      _selectFilter(
        keyName: 'site',
        label: 'Sede',
        options: uniqueColumnOptions(events, (event) => event.siteName),
      ),
      DateColumnFilter(
        label: 'Ocurrió',
        value: _columnFilters.date('occurredAt'),
        onChanged: (value) => _setDateFilter('occurredAt', value),
      ),
      _latencySort(),
    ];
  }

  Widget _typeFilter() => ChoiceColumnFilter(
    label: 'Estado',
    value: _columnFilters.text('type'),
    options: const ['deviceOffline', 'deviceOnline'],
    labels: const {'deviceOffline': 'Offline', 'deviceOnline': 'Online'},
    onChanged: (value) => _setTextFilter('type', value),
  );

  Widget _latencySort() => SortColumnControl(
    label: 'Ordenar por latencia',
    value: _columnFilters.sort('latency'),
    onChanged: (value) =>
        setState(() => _columnFilters.setSort('latency', value)),
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

  Future<PagedResult<Event>> _loadPage() {
    return widget.getEvents.page(
      page: _page,
      size: _pageSize,
      search: _columnFilters.text('query'),
      eventType: _columnFilters.text('type'),
      deviceName: _columnFilters.text('device'),
      siteName: _columnFilters.text('site'),
      occurredDate: _columnFilters.date('occurredAt'),
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

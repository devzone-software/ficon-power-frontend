import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/user_error_message.dart';
import '../../domain/auth_user.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../domain/operations_calendar.dart';
import '../../domain/realtime_change.dart';
import '../../ports/input/get_incidents.dart';
import '../../ports/input/get_monitoring_overview.dart';
import '../../ports/input/manage_tuya_plans.dart';
import '../dashboard/dashboard_body.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Resumen general: KPIs, disponibilidad de la flota,
/// dispositivos fuera de línea e incidentes recientes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.getOverview,
    required this.getIncidents,
    required this.manageTuyaPlans,
    required this.currentUser,
    required this.onLogout,
    this.realtimeChanges,
  });

  final GetMonitoringOverview getOverview;
  final GetIncidents getIncidents;
  final ManageTuyaPlans manageTuyaPlans;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _autoRefreshInterval = Duration(minutes: 3);

  late Future<_DashboardData> _future;
  Timer? _autoRefreshTimer;
  Timer? _realtimeDebounce;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  bool _refreshing = false;
  final Set<String> _acknowledgingIncidentIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
    _realtimeSubscription = widget.realtimeChanges
        ?.where(
          (change) => const {
            'device',
            'incident',
            'event',
            'site',
            'notification_template',
            'calendar',
          }.contains(change.entityType),
        )
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
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    } finally {
      _refreshing = false;
    }
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      widget.getOverview(),
      widget.manageTuyaPlans.list(),
    ]);
    return _DashboardData(
      overview: results[0] as MonitoringOverview,
      tuyaPlans: results[1] as List<TuyaPlan>,
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.dashboard,
      title: 'Resumen',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      realtimeChanges: widget.realtimeChanges,
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: DashboardBody(
              data: snapshot.data!.overview,
              tuyaPlans: snapshot.data!.tuyaPlans,
              canAcknowledgeIncidents: widget.currentUser.canAccessAdmin,
              acknowledgingIncidentIds: _acknowledgingIncidentIds,
              onAcknowledgeIncident: _acknowledgeIncident,
            ),
          );
        },
      ),
    );
  }

  Future<void> _acknowledgeIncident(Incident incident) async {
    if (!incident.isAwaitingAttention ||
        _acknowledgingIncidentIds.contains(incident.id)) {
      return;
    }
    final confirmed = await _confirmAcknowledge(incident);
    if (!confirmed || !mounted) return;
    setState(() => _acknowledgingIncidentIds.add(incident.id));
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
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.incidents);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.forAction(
              'No se pudo atender el incidente',
              error,
            ),
          ),
        ),
      );
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _acknowledgingIncidentIds.remove(incident.id));
      }
    }
  }

  Future<bool> _confirmAcknowledge(Incident incident) async {
    final deviceName = incident.deviceName ?? 'este dispositivo';
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar atención'),
            content: Text(
              '¿Deseas marcar como atendido el incidente de $deviceName?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Atender'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _DashboardData {
  const _DashboardData({required this.overview, required this.tuyaPlans});

  final MonitoringOverview overview;
  final List<TuyaPlan> tuyaPlans;
}

/// Encabezado de resumen con el mismo lenguaje visual de las tarjetas KPI.

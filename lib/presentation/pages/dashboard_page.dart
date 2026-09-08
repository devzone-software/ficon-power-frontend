import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/user_error_message.dart';
import '../../domain/auth_user.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../ports/input/get_incidents.dart';
import '../../ports/input/get_monitoring_overview.dart';
import '../../ports/input/get_notification_templates.dart';
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
    required this.getNotificationTemplates,
    required this.currentUser,
    required this.onLogout,
  });

  final GetMonitoringOverview getOverview;
  final GetIncidents getIncidents;
  final GetNotificationTemplates getNotificationTemplates;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _autoRefreshInterval = Duration(seconds: 10);

  late Future<MonitoringOverview> _future;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;
  final Set<String> _acknowledgingIncidentIds = {};

  @override
  void initState() {
    super.initState();
    _future = widget.getOverview();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    setState(() => _future = widget.getOverview());
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
      currentRoute: AppRoutes.dashboard,
      title: 'Resumen',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<MonitoringOverview>(
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
              data: snapshot.data!,
              getNotificationTemplates: widget.getNotificationTemplates,
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

/// Encabezado de resumen con el mismo lenguaje visual de las tarjetas KPI.

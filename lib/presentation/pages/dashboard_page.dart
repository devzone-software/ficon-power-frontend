import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../domain/notification_template.dart';
import '../../ports/input/get_monitoring_overview.dart';
import '../../ports/input/get_notification_templates.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

part '../dashboard/dashboard_analytics.dart';
part '../dashboard/dashboard_overview_widgets.dart';
part '../dashboard/dashboard_status_widgets.dart';

/// Resumen general: KPIs, disponibilidad de la flota,
/// dispositivos fuera de línea e incidentes recientes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.getOverview,
    required this.getNotificationTemplates,
    required this.currentUser,
    required this.onLogout,
  });

  final GetMonitoringOverview getOverview;
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
            child: _DashboardBody(
              data: snapshot.data!,
              getNotificationTemplates: widget.getNotificationTemplates,
              currentUser: widget.currentUser,
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado de resumen con el mismo lenguaje visual de las tarjetas KPI.

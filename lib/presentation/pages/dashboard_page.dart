import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/monitoring_overview.dart';
import '../../domain/notification_template.dart';
import '../../ports/input/get_monitoring_overview.dart';
import '../../ports/input/get_notification_templates.dart';
import '../../ports/input/update_notification_template.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

/// Resumen general: KPIs, disponibilidad de la flota,
/// dispositivos fuera de línea e incidentes recientes.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.getOverview,
    required this.getNotificationTemplates,
    required this.updateNotificationTemplate,
  });

  final GetMonitoringOverview getOverview;
  final GetNotificationTemplates getNotificationTemplates;
  final UpdateNotificationTemplate updateNotificationTemplate;

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
    _autoRefreshTimer = Timer.periodic(
      _autoRefreshInterval,
      (_) => _refresh(),
    );
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
              updateNotificationTemplate: widget.updateNotificationTemplate,
            ),
          );
        },
      ),
    );
  }
}

class _FiconOverviewHeader extends StatelessWidget {
  const _FiconOverviewHeader({
    required this.online,
    required this.total,
    required this.openIncidents,
  });

  final int online;
  final int total;
  final int openIncidents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onlineText = total == 0 ? 'Sin dispositivos' : '$online/$total online';
    final incidentText =
        openIncidents == 0 ? 'Operación estable' : '$openIncidents incidentes';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage(FiconAssets.background),
          fit: BoxFit.cover,
          opacity: 0.95,
        ),
        boxShadow: [
          BoxShadow(
            color: FiconColors.ink.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FiconBrandMark(height: 34, showPowerLabel: false),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Panel de continuidad FICON',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Monitoreo eléctrico para mantener tu red estable, veloz y conectada.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          );
          final chips = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(
                icon: Icons.wifi_tethering,
                label: onlineText,
                color: FiconColors.cyan,
              ),
              _HeaderChip(
                icon: openIncidents == 0
                    ? Icons.verified_outlined
                    : Icons.bolt_outlined,
                label: incidentText,
                color: openIncidents == 0
                    ? FiconColors.cyan
                    : FiconColors.cyanSoft,
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 16),
                chips,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: intro),
              const SizedBox(width: 16),
              chips,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.getNotificationTemplates,
    required this.updateNotificationTemplate,
  });

  final MonitoringOverview data;
  final GetNotificationTemplates getNotificationTemplates;
  final UpdateNotificationTemplate updateNotificationTemplate;

  @override
  Widget build(BuildContext context) {
    final offlineDevices =
        data.devices.where((d) => !d.isOnline && d.active).toList();
    final recentIncidents = data.incidents.take(6).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _FiconOverviewHeader(
          online: data.onlineCount,
          total: data.devices.length,
          openIncidents: data.openIncidents,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = width >= 900
                ? (width - 3 * 16) / 4
                : width >= 560
                    ? (width - 16) / 2
                    : width;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  title: 'Sedes',
                  value: '${data.sites.length}',
                  icon: Icons.business,
                  color: FiconColors.deep,
                  width: cardWidth,
                ),
                _KpiCard(
                  title: 'Dispositivos',
                  value: '${data.devices.length}',
                  icon: Icons.electrical_services,
                  color: FiconColors.logoBlue,
                  width: cardWidth,
                ),
                _KpiCard(
                  title: 'En línea',
                  value: '${data.onlineCount}',
                  icon: Icons.check_circle_outline,
                  color: StatusColors.online,
                  width: cardWidth,
                ),
                _KpiCard(
                  title: 'Incidentes activos',
                  value: '${data.openIncidents}',
                  icon: Icons.warning_amber,
                  color: data.openIncidents > 0
                      ? StatusColors.offline
                      : StatusColors.resolved,
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _FleetHealthCard(
          online: data.onlineCount,
          total: data.devices.length,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final lists = [
              _OfflineDevicesCard(devices: offlineDevices),
              _RecentIncidentsCard(incidents: recentIncidents),
            ];
            if (!wide) {
              return Column(
                children: [
                  lists[0],
                  const SizedBox(height: 20),
                  lists[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lists[0]),
                const SizedBox(width: 20),
                Expanded(child: lists[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _NotificationTemplatesCard(
          getNotificationTemplates: getNotificationTemplates,
          updateNotificationTemplate: updateNotificationTemplate,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.18),
                            color.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: textTheme.headlineSmall?.copyWith(
                              color: FiconColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(title, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetHealthCard extends StatelessWidget {
  const _FleetHealthCard({required this.online, required this.total});

  final int online;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : online / total;
    final percent = (ratio * 100).round();
    final color = ratio >= 0.9
        ? StatusColors.online
        : ratio >= 0.5
            ? StatusColors.acknowledged
            : StatusColors.offline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponibilidad de dispositivos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Señal estable para la red monitoreada',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: FiconColors.deepAlt,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent %',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: color,
                backgroundColor: FiconColors.cardBorder,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$online de $total dispositivos en línea',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineDevicesCard extends StatelessWidget {
  const _OfflineDevicesCard({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router_outlined, color: FiconColors.logoBlue),
                const SizedBox(width: 8),
                Text(
                  'Fuera de línea',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                if (devices.isNotEmpty)
                  StatusChip(
                    label: '${devices.length}',
                    color: StatusColors.offline,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const EmptyNote('Todos los dispositivos están en línea.')
            else
              ...devices.take(6).map(
                    (d) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Icon(Icons.power_off, color: StatusColors.offline),
                      title: Text(
                        d.name.isNotEmpty ? d.name : d.externalId ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(d.siteName ?? 'Sin sede'),
                      trailing: Text(
                        formatDateTime(d.lastStatusChange),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RecentIncidentsCard extends StatelessWidget {
  const _RecentIncidentsCard({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incidentes recientes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Historial de cortes y retornos reportados',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: FiconColors.deepAlt),
            ),
            const SizedBox(height: 8),
            if (incidents.isEmpty)
              const EmptyNote('No hay incidentes registrados.')
            else
              ...incidents.map(
                (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    i.isOpen ? Icons.error_outline : Icons.task_alt,
                    color: i.isOpen
                        ? StatusColors.offline
                        : StatusColors.resolved,
                  ),
                  title: Text(
                    i.deviceName ?? 'Dispositivo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${i.siteName ?? 'Sin sede'} · '
                    '${formatDateTime(i.startTime)}',
                  ),
                  trailing: IncidentStatusChip(status: i.status),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta para ver y editar las plantillas de los mensajes
/// de notificación (corte y retorno de energía).
class _NotificationTemplatesCard extends StatefulWidget {
  const _NotificationTemplatesCard({
    required this.getNotificationTemplates,
    required this.updateNotificationTemplate,
  });

  final GetNotificationTemplates getNotificationTemplates;
  final UpdateNotificationTemplate updateNotificationTemplate;

  @override
  State<_NotificationTemplatesCard> createState() =>
      _NotificationTemplatesCardState();
}

class _NotificationTemplatesCardState
    extends State<_NotificationTemplatesCard> {
  late Future<List<NotificationTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getNotificationTemplates();
  }

  void _reload() {
    setState(() => _future = widget.getNotificationTemplates());
  }

  Future<void> _edit(NotificationTemplate template) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditTemplateDialog(
        template: template,
        updateNotificationTemplate: widget.updateNotificationTemplate,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla actualizada.')),
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: FiconColors.cyanSoft,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mensajes de notificación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Plantillas que se envían por WhatsApp ante corte o retorno',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: FiconColors.deepAlt),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<NotificationTemplate>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'No se pudieron cargar las plantillas.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reintentar',
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final templates = snapshot.data!;
                if (templates.isEmpty) {
                  return const EmptyNote('No hay plantillas configuradas.');
                }
                return Column(
                  children: templates
                      .map(
                        (t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.notifications_active_outlined,
                            color: StatusColors.acknowledged,
                          ),
                          title: Text(t.displayName),
                          subtitle: Text(
                            t.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _edit(t),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar mensaje',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para editar el texto de una plantilla de notificación.
/// Devuelve `true` al cerrarse si el guardado fue exitoso.
class _EditTemplateDialog extends StatefulWidget {
  const _EditTemplateDialog({
    required this.template,
    required this.updateNotificationTemplate,
  });

  final NotificationTemplate template;
  final UpdateNotificationTemplate updateNotificationTemplate;

  @override
  State<_EditTemplateDialog> createState() => _EditTemplateDialogState();
}

class _EditTemplateDialogState extends State<_EditTemplateDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.template.body);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Placeholders disponibles según el evento de la plantilla.
  String get _placeholdersLegend {
    const base = 'Puedes usar: {dispositivo}, {fechaCorte}';
    return widget.template.eventType == 'power_restored'
        ? '$base, {fechaRetorno}'
        : base;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.updateNotificationTemplate(
        widget.template.eventType,
        _controller.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template.displayName),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: null,
              enabled: !_saving,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _placeholdersLegend,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

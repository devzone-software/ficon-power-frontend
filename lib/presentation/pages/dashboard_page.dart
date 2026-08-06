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

/// Encabezado de resumen con el mismo lenguaje visual de las tarjetas KPI.
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FiconColors.cardBorderSoft),
        boxShadow: [
          BoxShadow(
            color: FiconColors.logoBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: FiconColors.logoBlue),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FiconBrandMark(
                            height: 36,
                            showPowerLabel: false,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Panel de continuidad FICON',
                              style: textTheme.titleLarge?.copyWith(
                                color: FiconColors.ink,
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
                          color: FiconColors.slate,
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
                        accent: FiconColors.cyan,
                      ),
                      _HeaderChip(
                        icon: openIncidents == 0
                            ? Icons.verified_outlined
                            : Icons.bolt_outlined,
                        label: incidentText,
                        accent: openIncidents == 0
                            ? FiconColors.cyan
                            : FiconColors.warning,
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        intro,
                        const SizedBox(height: 18),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip compacto para el encabezado de resumen.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: FiconColors.ink,
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
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _FiconOverviewHeader(
                  online: data.onlineCount,
                  total: data.devices.length,
                  openIncidents: data.openIncidents,
                ),
                const SizedBox(height: 24),
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
                          color: FiconColors.logoBlue,
                          width: cardWidth,
                        ),
                        _KpiCard(
                          title: 'Dispositivos',
                          value: '${data.devices.length}',
                          icon: Icons.electrical_services,
                          color: FiconColors.cyanSoft,
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
                              : StatusColors.online,
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _FleetHealthCard(
                  online: data.onlineCount,
                  total: data.devices.length,
                ),
                const SizedBox(height: 24),
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
                          const SizedBox(height: 24),
                          lists[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: lists[0]),
                        const SizedBox(width: 24),
                        Expanded(child: lists[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _NotificationTemplatesCard(
                  getNotificationTemplates: getNotificationTemplates,
                  updateNotificationTemplate: updateNotificationTemplate,
                ),
              ],
            ),
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  color: FiconColors.slate,
                  fontWeight: FontWeight.w600,
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
    final textTheme = Theme.of(context).textTheme;
    final ratio = total == 0
        ? 0.0
        : (online / total).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();
    final offline = total > online ? total - online : 0;
    final color = ratio >= 0.9
        ? StatusColors.online
        : ratio >= 0.5
            ? StatusColors.acknowledged
            : StatusColors.offline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.monitor_heart_outlined,
                    color: FiconColors.logoBlue,
                    title: 'Disponibilidad de dispositivos',
                    subtitle: 'Señal estable para la red monitoreada',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent %',
                  style: textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Container(color: FiconColors.cardBorderSoft),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendDot(
                  color: StatusColors.online,
                  label: '$online en línea',
                ),
                _LegendDot(
                  color: StatusColors.offline,
                  label: '$offline fuera de línea',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Encabezado de sección reutilizable: ícono en recuadro teñido,
/// título y subtítulo.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: FiconColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: FiconColors.slate,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _OfflineDevicesCard extends StatelessWidget {
  const _OfflineDevicesCard({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final visible = devices.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.router_outlined,
              color: StatusColors.offline,
              title: 'Fuera de línea',
              subtitle: 'Dispositivos activos sin señal',
              trailing: devices.isNotEmpty
                  ? StatusChip(
                      label: '${devices.length}',
                      color: StatusColors.offline,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const EmptyNote('Todos los dispositivos están en línea.')
            else
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.power_off, color: StatusColors.offline),
                  title: Text(
                    visible[i].name.isNotEmpty
                        ? visible[i].name
                        : visible[i].externalId ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(visible[i].siteName ?? 'Sin sede'),
                  trailing: Text(
                    formatDateTime(visible[i].lastStatusChange),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.history,
              color: FiconColors.cyanSoft,
              title: 'Incidentes recientes',
              subtitle: 'Historial de cortes y retornos reportados',
            ),
            const SizedBox(height: 8),
            if (incidents.isEmpty)
              const EmptyNote('No hay incidentes registrados.')
            else
              for (var i = 0; i < incidents.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: FiconColors.cardBorderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    incidents[i].isOpen ? Icons.error_outline : Icons.task_alt,
                    color: incidents[i].isOpen
                        ? StatusColors.offline
                        : StatusColors.online,
                  ),
                  title: Text(
                    incidents[i].deviceName ?? 'Dispositivo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${incidents[i].siteName ?? 'Sin sede'} · '
                    '${formatDateTime(incidents[i].startTime)}',
                  ),
                  trailing: IncidentStatusChip(status: incidents[i].status),
                ),
              ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.notifications_active_outlined,
              color: FiconColors.cyanSoft,
              title: 'Mensajes de notificación',
              subtitle: 'Plantillas que se envían por WhatsApp ante corte o retorno',
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
                  children: [
                    for (var i = 0; i < templates.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          color: FiconColors.cardBorderSoft,
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.notifications_active_outlined,
                          color: StatusColors.acknowledged,
                        ),
                        title: Text(templates[i].displayName),
                        subtitle: Text(
                          templates[i].body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _edit(templates[i]),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar mensaje',
                        ),
                      ),
                    ],
                  ],
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

part of '../pages/dashboard_page.dart';

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
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
  const _NotificationTemplatesCard({required this.getNotificationTemplates});

  final GetNotificationTemplates getNotificationTemplates;

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
              title: 'Plantillas Meta de WhatsApp',
              subtitle: 'Configuración activa para alertas de corte y retorno',
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
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _TemplateModeChip(template: templates[i]),
                                  if (templates[i].usesMetaTemplate)
                                    for (final param
                                        in templates[i].metaTemplateParams)
                                      _VariableChip(
                                        label: templates[i].labelForVariable(
                                          param,
                                        ),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                templates[i].summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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

class _TemplateModeChip extends StatelessWidget {
  const _TemplateModeChip({required this.template});

  final NotificationTemplate template;

  @override
  Widget build(BuildContext context) {
    final usesMeta = template.usesMetaTemplate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: usesMeta
            ? FiconColors.cyan.withValues(alpha: 0.12)
            : FiconColors.logoBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: usesMeta
              ? FiconColors.cyan.withValues(alpha: 0.35)
              : FiconColors.logoBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        usesMeta ? 'Plantilla Meta activa' : 'Plantilla Meta no configurada',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: usesMeta ? FiconColors.deepAlt : FiconColors.logoBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FiconColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: FiconColors.deep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

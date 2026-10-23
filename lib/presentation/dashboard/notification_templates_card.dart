import 'package:flutter/material.dart';

import '../../domain/notification_template.dart';
import '../../ports/input/get_notification_templates.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';
import 'dashboard_section_header.dart';

class NotificationTemplatesCard extends StatefulWidget {
  const NotificationTemplatesCard({
    super.key,
    required this.getNotificationTemplates,
  });

  final GetNotificationTemplates getNotificationTemplates;

  @override
  State<NotificationTemplatesCard> createState() =>
      _NotificationTemplatesCardState();
}

class _NotificationTemplatesCardState extends State<NotificationTemplatesCard> {
  late Future<List<NotificationTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getNotificationTemplates();
  }

  void _reload() {
    setState(() {
      _future = widget.getNotificationTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardSectionHeader(
              icon: Icons.notifications_active_outlined,
              color: FiconColors.cyanSoft,
              title: 'Plantillas Meta de WhatsApp',
              subtitle: 'Configuración activa para alertas de corte y retorno',
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<NotificationTemplate>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _ErrorContent(onRetry: _reload);
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
                return _TemplateList(templates: templates);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'No se pudieron cargar las plantillas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reintentar',
        ),
      ],
    );
  }
}

class _TemplateList extends StatelessWidget {
  const _TemplateList({required this.templates});

  final List<NotificationTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < templates.length; index++) ...[
          if (index > 0)
            const Divider(height: 1, color: FiconColors.cardBorderSoft),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications_active_outlined,
              color: StatusColors.acknowledged,
            ),
            title: Text(templates[index].displayName),
            subtitle: _TemplateSummary(template: templates[index]),
          ),
        ],
      ],
    );
  }
}

class _TemplateSummary extends StatelessWidget {
  const _TemplateSummary({required this.template});

  final NotificationTemplate template;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TemplateModeChip(template: template),
              if (template.usesMetaTemplate)
                for (final param in template.metaTemplateParams)
                  _VariableChip(label: template.labelForVariable(param)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
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
    final color = usesMeta ? FiconColors.cyan : FiconColors.logoBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: usesMeta ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: usesMeta ? 0.35 : 0.25),
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

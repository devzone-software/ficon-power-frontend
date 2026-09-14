import 'dart:async';

import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../application/user_error_message.dart';
import '../../domain/site.dart';
import '../../domain/realtime_change.dart';
import '../../domain/whatsapp_recipient.dart';
import '../theme/ficon_theme.dart';
import '../widgets/common.dart';

class WhatsAppRecipientsTab extends StatefulWidget {
  const WhatsAppRecipientsTab({
    super.key,
    required this.repository,
    this.realtimeChanges,
  });

  final FiconMonitoringRepository repository;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<WhatsAppRecipientsTab> createState() => _WhatsAppRecipientsTabState();
}

class _WhatsAppRecipientsTabState extends State<WhatsAppRecipientsTab> {
  late Future<(List<WhatsAppRecipient>, List<Site>)> _future;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  Timer? _realtimeDebounce;

  @override
  void initState() {
    super.initState();
    _reload();
    _realtimeSubscription = widget.realtimeChanges
        ?.where(
          (change) =>
              const {'whatsapp_recipient', 'site'}.contains(change.entityType),
        )
        .listen((_) {
          _realtimeDebounce?.cancel();
          _realtimeDebounce = Timer(
            const Duration(milliseconds: 450),
            () => unawaited(_refresh()),
          );
        });
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    super.dispose();
  }

  void _reload() => _future = _load();

  Future<(List<WhatsAppRecipient>, List<Site>)> _load() async {
    final values = await Future.wait([
      widget.repository.fetchWhatsAppRecipients(),
      widget.repository.fetchSites(),
    ]);
    return (values[0] as List<WhatsAppRecipient>, values[1] as List<Site>);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _edit(List<Site> sites, [WhatsAppRecipient? recipient]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _RecipientDialog(
        repository: widget.repository,
        sites: sites,
        recipient: recipient,
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _delete(WhatsAppRecipient recipient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar destinatario'),
        content: Text('¿Eliminar a ${recipient.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteWhatsAppRecipient(recipient.id);
      if (mounted) await _refresh();
    } catch (error) {
      _show(UserErrorMessage.forAction('No se pudo eliminar', error));
    }
  }

  Future<void> _test(WhatsAppRecipient recipient) async {
    try {
      final result = await widget.repository.testWhatsAppRecipient(
        recipient.id,
      );
      _show(result.message);
      if (mounted) await _refresh();
    } catch (error) {
      _show(UserErrorMessage.forAction('No se pudo enviar la prueba', error));
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<WhatsAppRecipient>, List<Site>)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(error: snapshot.error, onRetry: _refresh);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final recipients = snapshot.data!.$1;
        final sites = snapshot.data!.$2;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Destinatarios de WhatsApp',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _edit(sites),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Los destinatarios globales reciben alertas de todas las sedes. '
                'Las credenciales y el número emisor permanecen en el servidor.',
              ),
              const SizedBox(height: 16),
              if (recipients.isEmpty)
                const EmptyNote('Todavía no hay destinatarios configurados.'),
              for (final recipient in recipients) ...[
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (recipient.active
                                  ? FiconColors.cyan
                                  : FiconColors.cardBorderSoft)
                              .withValues(alpha: 0.18),
                      child: const Icon(Icons.chat_outlined),
                    ),
                    title: Text(recipient.label),
                    subtitle: Text(
                      '+${recipient.phone} · '
                      '${recipient.siteName ?? 'Todas las sedes'}\n'
                      '${recipient.notifyOutage ? 'Cortes' : ''}'
                      '${recipient.notifyOutage && recipient.notifyRestored ? ' y ' : ''}'
                      '${recipient.notifyRestored ? 'Reconexiones' : ''}'
                      '${recipient.lastTestMessage == null ? '' : ' · ${recipient.lastTestMessage}'}',
                    ),
                    isThreeLine: recipient.lastTestMessage != null,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Enviar prueba',
                          onPressed: () => _test(recipient),
                          icon: const Icon(Icons.send_outlined),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _edit(sites, recipient),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => _delete(recipient),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecipientDialog extends StatefulWidget {
  const _RecipientDialog({
    required this.repository,
    required this.sites,
    this.recipient,
  });

  final FiconMonitoringRepository repository;
  final List<Site> sites;
  final WhatsAppRecipient? recipient;

  @override
  State<_RecipientDialog> createState() => _RecipientDialogState();
}

class _RecipientDialogState extends State<_RecipientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _phone;
  String? _siteId;
  late bool _outage;
  late bool _restored;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final recipient = widget.recipient;
    _label = TextEditingController(text: recipient?.label);
    _phone = TextEditingController(text: recipient?.phone);
    _siteId = recipient?.siteId;
    _outage = recipient?.notifyOutage ?? true;
    _restored = recipient?.notifyRestored ?? true;
    _active = recipient?.active ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_outage && !_restored) {
      setState(() => _error = 'Selecciona al menos un tipo de alerta.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveWhatsAppRecipient(
        id: widget.recipient?.id,
        label: _label.text,
        phone: _phone.text,
        siteId: _siteId,
        notifyOutage: _outage,
        notifyRestored: _restored,
        active: _active,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = UserErrorMessage.from(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.recipient == null
            ? 'Agregar destinatario'
            : 'Editar destinatario',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número internacional',
                    hintText: '51987654321',
                    prefixText: '+',
                  ),
                  validator: (value) =>
                      RegExp(
                        r'^[1-9][0-9]{7,14}$',
                      ).hasMatch(value?.trim().replaceFirst('+', '') ?? '')
                      ? null
                      : 'Usa entre 8 y 15 dígitos con código de país.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _siteId,
                  decoration: const InputDecoration(labelText: 'Alcance'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las sedes'),
                    ),
                    for (final site in widget.sites)
                      DropdownMenuItem<String?>(
                        value: site.id,
                        child: Text(site.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _siteId = value),
                ),
                CheckboxListTile(
                  value: _outage,
                  onChanged: (value) =>
                      setState(() => _outage = value ?? false),
                  title: const Text('Alertas de corte'),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _restored,
                  onChanged: (value) =>
                      setState(() => _restored = value ?? false),
                  title: const Text('Alertas de reconexión'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Destinatario activo'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

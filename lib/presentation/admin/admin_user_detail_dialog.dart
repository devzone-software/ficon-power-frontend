part of '../pages/admin_page.dart';

class _UserDetailDialog extends StatefulWidget {
  const _UserDetailDialog({required this.repository, required this.user});

  final FiconMonitoringRepository repository;
  final ManagedUser user;

  @override
  State<_UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<_UserDetailDialog> {
  late Future<List<UserWhatsAppDelivery>> _deliveries;
  bool _testing = false;
  bool _updatingAlerts = false;
  late bool _whatsappEnabled;

  @override
  void initState() {
    super.initState();
    _deliveries = widget.repository.fetchUserWhatsAppDeliveries(widget.user.id);
    _whatsappEnabled = widget.user.whatsappEnabled;
  }

  Future<void> _testWhatsApp() async {
    setState(() => _testing = true);
    try {
      final result = await widget.repository.testUserWhatsApp(widget.user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      setState(() {
        _deliveries = widget.repository.fetchUserWhatsAppDeliveries(
          widget.user.id,
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.forAction('No se pudo enviar la prueba', error),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _setWhatsAppEnabled(bool enabled) async {
    final user = widget.user;
    setState(() => _updatingAlerts = true);
    try {
      await widget.repository.updateUser(
        user.id,
        role: user.role,
        displayName: user.displayName,
        email: user.email,
        whatsappPhone: user.whatsappPhone,
        whatsappEnabled: enabled,
        active: user.active,
      );
      if (!mounted) return;
      setState(() => _whatsappEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Alertas de WhatsApp habilitadas.'
                : 'Alertas de WhatsApp deshabilitadas.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.forAction('No se pudo actualizar WhatsApp', error),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAlerts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del usuario'),
          leading: IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          actions: [
            IconButton(
              tooltip: 'Editar usuario',
              onPressed: () => Navigator.pop(context, 'edit'),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: FiconColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _UserInfoRow(
                      icon: Icons.person_outline,
                      label: 'Usuario',
                      value: user.username,
                    ),
                    _UserInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Rol',
                      value: user.role,
                    ),
                    _UserInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo',
                      value: user.email ?? 'No registrado',
                    ),
                    _UserInfoRow(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      value: user.whatsappPhone == null
                          ? 'No registrado'
                          : formatPeruMobilePhone(user.whatsappPhone!),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(
                        Icons.chat_outlined,
                        color: FiconColors.logoBlue,
                      ),
                      title: const Text('Alertas por WhatsApp'),
                      subtitle: Text(
                        user.hasWhatsapp
                            ? 'Cortes y restablecimientos'
                            : 'Primero registra un número',
                      ),
                      value: _whatsappEnabled,
                      onChanged: !user.hasWhatsapp || _updatingAlerts
                          ? null
                          : _setWhatsAppEnabled,
                    ),
                    _UserInfoRow(
                      icon: user.active
                          ? Icons.verified_user_outlined
                          : Icons.person_off_outlined,
                      label: 'Acceso',
                      value: user.active ? 'Activo' : 'Revocado',
                    ),
                    if (user.hasWhatsapp) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _testing ? null : _testWhatsApp,
                        icon: const Icon(Icons.send_outlined),
                        label: Text(
                          _testing ? 'Enviando...' : 'Enviar mensaje de prueba',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de mensajes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FiconColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar historial',
                  onPressed: () => setState(() {
                    _deliveries = widget.repository.fetchUserWhatsAppDeliveries(
                      user.id,
                    );
                  }),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<UserWhatsAppDelivery>>(
              future: _deliveries,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(
                    error: snapshot.error,
                    onRetry: () => setState(() {
                      _deliveries = widget.repository
                          .fetchUserWhatsAppDeliveries(user.id);
                    }),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final deliveries = snapshot.data!;
                if (deliveries.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Todavía no se enviaron mensajes a este usuario.',
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final delivery in deliveries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DeliveryCard(delivery: delivery),
                      ),
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

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: FiconColors.logoBlue),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(label, style: const TextStyle(color: FiconColors.slate)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final UserWhatsAppDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final sent = delivery.status == 'SENT' || delivery.status == 'DELIVERED';
    return Card(
      child: ListTile(
        leading: Icon(
          sent ? Icons.check_circle_outline : Icons.error_outline,
          color: sent ? FiconColors.cyanSoft : FiconColors.logoBlue,
        ),
        title: Text(_eventLabel(delivery.eventType)),
        subtitle: Text(
          delivery.errorMessage?.isNotEmpty == true
              ? delivery.errorMessage!
              : _formatDateTime(context, delivery.sentAt ?? delivery.createdAt),
        ),
        trailing: Text(
          delivery.status == 'SIMULATED'
              ? 'Simulado'
              : sent
              ? 'Enviado'
              : 'Falló',
        ),
      ),
    );
  }

  String _eventLabel(String? value) => switch (value) {
    'power_outage' => 'Corte de energía',
    'power_restored' => 'Energía restablecida',
    _ => 'Mensaje de WhatsApp',
  };

  String _formatDateTime(BuildContext context, DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date · $time';
  }
}

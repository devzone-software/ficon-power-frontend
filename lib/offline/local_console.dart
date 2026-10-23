import 'package:flutter/material.dart' hide Row;
import '../config/auth_session.dart';
import '../adapters/http/ficon_api_client.dart';
import '../application/mobile_data_export.dart';
import '../application/ficon_repository_scope.dart';
import '../presentation/mobile/overlays/mobile_export_sheet.dart';
import '../mobile/notifications/mobile_notification_navigation.dart';
import 'local_engine.dart';

class LocalConsole extends StatefulWidget {
  const LocalConsole({super.key});
  static late LocalEngine engine;
  static AuthSession session = AuthSession();
  static final navigatorKey = GlobalKey<NavigatorState>();
  static Map<String, dynamic>? pendingNotification;
  static void openNotification(Map<String, dynamic> data) {
    pendingNotification = data;
    flushNotification();
  }

  static void flushNotification() {
    if (!session.isAuthenticated || pendingNotification == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      final destination = MobileNotificationDestination.fromData(
        pendingNotification ?? {},
      );
      if (navigator == null || destination == null) return;
      pendingNotification = null;
      navigator.pushNamed(destination.route, arguments: destination);
    });
  }

  static void open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const LocalConsole()));
  @override
  State<LocalConsole> createState() => _LocalConsoleState();
}

class _LocalConsoleState extends State<LocalConsole> {
  List<Row> devices = [];
  List<Row> sites = [];
  bool busy = false;
  String? error;
  String get token => LocalConsole.session.token ?? '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<dynamic> _call(String method, String path, [Row body = const {}]) =>
      LocalConsole.engine.request(
        method,
        Uri.parse('http://local.ficon$path'),
        body,
        token,
      );

  Future<void> _refresh() async {
    try {
      final result = await Future.wait([
        _call('GET', '/api/devices'),
        _call('GET', '/api/sites'),
      ]);
      if (mounted) {
        setState(() {
          devices = (result[0] as List).cast<Row>();
          sites = (result[1] as List).cast<Row>();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    }
  }

  String _message(Object e) => e is LocalFailure
      ? e.message
      : e is ApiException
      ? e.message
      : 'No se pudo guardar el cambio local.';

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await operation();
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _addDevice() async {
    final name = TextEditingController();
    var siteId = sites.first['id'] as String;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Agregar dispositivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: siteId,
                decoration: const InputDecoration(labelText: 'Distrito'),
                items: sites
                    .map(
                      (s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name']),
                      ),
                    )
                    .toList(),
                onChanged: (value) => update(() => siteId = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      await _run(() async {
        await _call('POST', '/api/local/devices', {
          'name': name.text,
          'siteId': siteId,
        });
      });
    }
    // Controller remains alive until the dialog's exit animation finishes.
  }

  Future<void> _export() async {
    final request = await showModalBottomSheet<MobileExportRequest>(
      context: context,
      builder: (_) => const MobileExportSheet(),
    );
    if (request == null || !mounted) return;
    final repository = FiconRepositoryScope.of(context);
    await _run(() => MobileDataExportService(repository).share(request));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Operaciones'),
      actions: [
        IconButton(
          tooltip: 'Exportar datos',
          onPressed: busy ? null : _export,
          icon: const Icon(Icons.ios_share),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Control de energía',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Registra un corte o un retorno para actualizar los incidentes, el historial y los gráficos de esta instalación.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy || sites.isEmpty ? null : _addDevice,
          icon: const Icon(Icons.add),
          label: const Text('Agregar dispositivo'),
        ),
        for (final device in devices)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${device['district']} · ${device['status'] == 'online' ? 'En línea' : 'Corte activo'}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: busy
                            ? null
                            : () => _run(() async {
                                await _call(
                                  'POST',
                                  '/api/local/devices/${device['id']}/power',
                                  {'online': device['status'] != 'online'},
                                );
                              }),
                        icon: Icon(
                          device['status'] == 'online'
                              ? Icons.power_off
                              : Icons.power,
                        ),
                        label: Text(
                          device['status'] == 'online'
                              ? 'Registrar corte'
                              : 'Restaurar energía',
                        ),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (await _confirm(
                                      '¿Retirar ${device['name']}? Su historial se conservará.',
                                    ) &&
                                    mounted) {
                                  await _run(() async {
                                    await _call(
                                      'POST',
                                      '/api/local/devices/${device['id']}/archive',
                                    );
                                  });
                                }
                              },
                        child: const Text('Retirar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (LocalConsole.session.user?.canManageUsers == true)
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    if (!await _confirm(
                      'Se reemplazarán todos los datos de esta instalación por el escenario inicial y se cerrará la sesión. Esta acción no se puede deshacer.',
                    )) {
                      return;
                    }
                    if (!mounted) return;
                    await _run(() async {
                      await _call('POST', '/api/local/reset');
                      LocalConsole.session.clear();
                      if (mounted) {
                        Navigator.of(
                          this.context,
                        ).popUntil((route) => route.isFirst);
                      }
                    });
                  },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restablecer escenario'),
          ),
      ],
    ),
  );
}

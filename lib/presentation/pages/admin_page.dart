import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onLogout,
  });

  final FiconMonitoringRepository repository;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<_AdminData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchUsers(),
      widget.repository.fetchAuditLogs(),
      widget.repository.fetchLoginAttempts(),
      widget.repository.fetchAdminSessions(),
    ]);
    return _AdminData(
      users: results[0] as List<ManagedUser>,
      auditLogs: results[1] as List<AuditLogEntry>,
      loginAttempts: results[2] as List<LoginAttempt>,
      sessions: results[3] as List<AdminSession>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openUserDialog([ManagedUser? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(repository: widget.repository, user: user),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(user == null ? 'Usuario creado.' : 'Usuario actualizado.')),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.admin,
      title: 'Administración',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: FutureBuilder<_AdminData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _refresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: FiconColors.logoBlue,
                    unselectedLabelColor: FiconColors.deepAlt,
                    tabs: const [
                      Tab(text: 'Usuarios'),
                      Tab(text: 'Audit logs'),
                      Tab(text: 'Logins'),
                      Tab(text: 'Sesiones'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _UsersTab(
                        users: data.users,
                        onCreate: () => _openUserDialog(),
                        onEdit: _openUserDialog,
                        onRefresh: _refresh,
                      ),
                      _AuditTab(logs: data.auditLogs, onRefresh: _refresh),
                      _LoginAttemptsTab(
                        attempts: data.loginAttempts,
                        onRefresh: _refresh,
                      ),
                      _SessionsTab(sessions: data.sessions, onRefresh: _refresh),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminData {
  const _AdminData({
    required this.users,
    required this.auditLogs,
    required this.loginAttempts,
    required this.sessions,
  });

  final List<ManagedUser> users;
  final List<AuditLogEntry> auditLogs;
  final List<LoginAttempt> loginAttempts;
  final List<AdminSession> sessions;
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({
    required this.users,
    required this.onCreate,
    required this.onEdit,
    required this.onRefresh,
  });

  final List<ManagedUser> users;
  final VoidCallback onCreate;
  final ValueChanged<ManagedUser> onEdit;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      action: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Crear usuario'),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final user in users)
            DataRow(
              cells: [
                DataCell(Text(user.username)),
                DataCell(Text(user.displayName)),
                DataCell(StatusChip(label: user.role, color: FiconColors.logoBlue)),
                DataCell(
                  StatusChip(
                    label: user.active ? 'Activo' : 'Revocado',
                    color: user.active ? FiconColors.cyan : FiconColors.deepAlt,
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: 'Editar rol, estado o contraseña',
                    onPressed: () => onEdit(user),
                    icon: const Icon(Icons.manage_accounts_outlined),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.logs, required this.onRefresh});

  final List<AuditLogEntry> logs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Acción')),
          DataColumn(label: Text('Entidad')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final log in logs)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(log.createdAt))),
                DataCell(Text('${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}')),
                DataCell(Text(log.action)),
                DataCell(Text('${log.entityType} ${log.entityId ?? ''}')),
                DataCell(Text(log.ipAddress ?? '—')),
                DataCell(_EllipsisText(log.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _LoginAttemptsTab extends StatelessWidget {
  const _LoginAttemptsTab({required this.attempts, required this.onRefresh});

  final List<LoginAttempt> attempts;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Resultado')),
          DataColumn(label: Text('Motivo')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final attempt in attempts)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(attempt.createdAt))),
                DataCell(Text(attempt.username ?? '—')),
                DataCell(
                  StatusChip(
                    label: attempt.success ? 'Correcto' : 'Fallido',
                    color: attempt.success ? FiconColors.cyan : FiconColors.logoBlue,
                  ),
                ),
                DataCell(Text(attempt.reason ?? '—')),
                DataCell(Text(attempt.ipAddress ?? '—')),
                DataCell(_EllipsisText(attempt.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.sessions, required this.onRefresh});

  final List<AdminSession> sessions;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Creada')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Expira')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Navegador')),
        ],
        rows: [
          for (final session in sessions)
            DataRow(
              cells: [
                DataCell(Text(formatDateTime(session.createdAt))),
                DataCell(Text(session.username)),
                DataCell(Text(session.role)),
                DataCell(
                  StatusChip(
                    label: session.active ? 'Activa' : 'Cerrada/expirada',
                    color: session.active ? FiconColors.cyan : FiconColors.deepAlt,
                  ),
                ),
                DataCell(Text(formatDateTime(session.expiresAt))),
                DataCell(Text(session.ipAddress ?? '—')),
                DataCell(_EllipsisText(session.userAgent ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({required this.child, required this.onRefresh, this.action});

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (action != null) ...[
                  Align(alignment: Alignment.centerRight, child: action),
                  const SizedBox(height: 12),
                ],
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({required this.repository, this.user});

  final FiconMonitoringRepository repository;
  final ManagedUser? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _password;
  late String _role;
  late bool _active;
  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    _displayName = TextEditingController(text: widget.user?.displayName ?? '');
    _password = TextEditingController();
    _role = widget.user?.role ?? 'USER';
    _active = widget.user?.active ?? true;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await widget.repository.updateUser(
          widget.user!.id,
          role: _role,
          displayName: _displayName.text.trim(),
          active: _active,
          password: _password.text.trim(),
        );
      } else {
        await widget.repository.createUser(
          username: _username.text.trim(),
          password: _password.text.trim(),
          role: _role,
          displayName: _displayName.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar usuario' : 'Crear usuario'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _username,
                enabled: !_isEdit && !_saving,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayName,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Nombre visible'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER · sólo lectura')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN · edición')),
                  DropdownMenuItem(value: 'SUPERADMIN', child: Text('SUPERADMIN · control total')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _role = value ?? 'USER'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso activo'),
                subtitle: const Text('Apágalo para revocar el acceso del usuario.'),
                value: _active,
                onChanged: _saving ? null : (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_saving,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: _isEdit ? 'Nueva contraseña opcional' : 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: StatusColors.offline)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _EllipsisText extends StatelessWidget {
  const _EllipsisText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

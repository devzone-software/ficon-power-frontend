import 'dart:async';

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
  static const _liveRefreshInterval = Duration(seconds: 5);

  _AdminData? _data;
  Object? _error;
  Timer? _liveRefreshTimer;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refresh(showLoading: true);
    _liveRefreshTimer = Timer.periodic(
      _liveRefreshInterval,
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<_AdminData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchUsers(),
      widget.repository.fetchAuditLogs(),
      widget.repository.fetchLoginAttempts(),
      widget.repository.fetchAdminSessions(),
      widget.repository.fetchBlockedUsers(),
    ]);
    return _AdminData(
      users: results[0] as List<ManagedUser>,
      auditLogs: results[1] as List<AuditLogEntry>,
      loginAttempts: results[2] as List<LoginAttempt>,
      sessions: results[3] as List<AdminSession>,
      blockedUsers: results[4] as List<BlockedLoginUser>,
    );
  }

  Future<void> _refresh({bool showLoading = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
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

  Future<void> _unblockUser(BlockedLoginUser blockedUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: Text(
          '¿Permitir nuevamente el inicio de sesión de '
          '${blockedUser.username} desde ${blockedUser.ipAddress ?? 'esta IP'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.unblockBlockedUser(blockedUser.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${blockedUser.username} desbloqueado.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo desbloquear: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: AppRoutes.admin,
      title: 'Administración',
      currentUser: widget.currentUser,
      onLogout: widget.onLogout,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return ErrorView(error: _error, onRetry: () => _refresh(showLoading: true));
    }

    final data = _data!;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  labelColor: FiconColors.logoBlue,
                  unselectedLabelColor: FiconColors.deepAlt,
                  tabs: const [
                    Tab(text: 'Usuarios'),
                    Tab(text: 'Bloqueados'),
                    Tab(text: 'Audit logs'),
                    Tab(text: 'Logins'),
                    Tab(text: 'Sesiones'),
                  ],
                ),
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
                _BlockedUsersTab(
                  blockedUsers: data.blockedUsers,
                  onUnblock: _unblockUser,
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
  }
}

class _AdminData {
  const _AdminData({
    required this.users,
    required this.auditLogs,
    required this.loginAttempts,
    required this.sessions,
    required this.blockedUsers,
  });

  final List<ManagedUser> users;
  final List<AuditLogEntry> auditLogs;
  final List<LoginAttempt> loginAttempts;
  final List<AdminSession> sessions;
  final List<BlockedLoginUser> blockedUsers;
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

class _BlockedUsersTab extends StatelessWidget {
  const _BlockedUsersTab({
    required this.blockedUsers,
    required this.onUnblock,
    required this.onRefresh,
  });

  final List<BlockedLoginUser> blockedUsers;
  final ValueChanged<BlockedLoginUser> onUnblock;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (blockedUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 360,
            child: Center(
              child: EmptyNote('No hay usuarios bloqueados registrados.'),
            ),
          ),
        ),
      );
    }
    return _TableShell(
      onRefresh: onRefresh,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('IP')),
          DataColumn(label: Text('Fallos'), numeric: true),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Bloqueado')),
          DataColumn(label: Text('Expira')),
          DataColumn(label: Text('Desbloqueado por')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final blocked in blockedUsers)
            DataRow(
              cells: [
                DataCell(Text(blocked.username)),
                DataCell(Text(blocked.displayName ?? '—')),
                DataCell(Text(blocked.ipAddress ?? '—')),
                DataCell(Text('${blocked.failedAttempts}')),
                DataCell(
                  StatusChip(
                    label: blocked.active ? 'Bloqueado' : 'Liberado/expirado',
                    color: blocked.active ? FiconColors.logoBlue : FiconColors.deepAlt,
                  ),
                ),
                DataCell(Text(formatDateTime(blocked.blockedAt))),
                DataCell(Text(formatDateTime(blocked.expiresAt))),
                DataCell(Text(blocked.unblockedByUsername ?? '—')),
                DataCell(
                  FilledButton.tonalIcon(
                    onPressed: blocked.active ? () => onUnblock(blocked) : null,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Desbloquear'),
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

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
  final Map<String, String> _textFilters = {};
  final Map<String, DateTime?> _dateFilters = {};

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
    final users = data.users.where(_matchesUserFilters).toList();
    final blockedUsers = data.blockedUsers.where(_matchesBlockedUserFilters).toList();
    final auditLogs = data.auditLogs.where(_matchesAuditLogFilters).toList();
    final loginAttempts = data.loginAttempts.where(_matchesLoginAttemptFilters).toList();
    final sessions = data.sessions.where(_matchesSessionFilters).toList();

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
                  users: users,
                  onCreate: () => _openUserDialog(),
                  onEdit: _openUserDialog,
                  onRefresh: _refresh,
                  filters: [
                    _textColumnFilter(
                      keyName: 'users.username',
                      label: 'Usuario',
                      options: _uniqueColumnOptions(data.users, (user) => user.username),
                    ),
                    _textColumnFilter(
                      keyName: 'users.displayName',
                      label: 'Nombre',
                      options: _uniqueColumnOptions(data.users, (user) => user.displayName),
                    ),
                    _textColumnFilter(
                      keyName: 'users.role',
                      label: 'Rol',
                      options: _uniqueColumnOptions(data.users, (user) => user.role),
                    ),
                    _textColumnFilter(
                      keyName: 'users.status',
                      label: 'Estado',
                      options: _uniqueColumnOptions(
                        data.users,
                        (user) => user.active ? 'Activo' : 'Revocado',
                      ),
                    ),
                  ],
                ),
                _BlockedUsersTab(
                  blockedUsers: blockedUsers,
                  onUnblock: _unblockUser,
                  onRefresh: _refresh,
                  filters: [
                    _textColumnFilter(
                      keyName: 'blocked.username',
                      label: 'Usuario',
                      options: _uniqueColumnOptions(data.blockedUsers, (blocked) => blocked.username),
                    ),
                    _textColumnFilter(
                      keyName: 'blocked.displayName',
                      label: 'Nombre',
                      options: _uniqueColumnOptions(data.blockedUsers, (blocked) => blocked.displayName),
                    ),
                    _ipColumnFilter('blocked.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'blocked.failedAttempts',
                      label: 'Fallos',
                      options: _uniqueColumnOptions(
                        data.blockedUsers,
                        (blocked) => '${blocked.failedAttempts}',
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'blocked.status',
                      label: 'Estado',
                      options: _uniqueColumnOptions(
                        data.blockedUsers,
                        (blocked) => blocked.active ? 'Bloqueado' : 'Liberado/expirado',
                      ),
                    ),
                    _dateColumnFilter('blocked.blockedAt', 'Bloqueado'),
                    _dateColumnFilter('blocked.expiresAt', 'Expira'),
                    _textColumnFilter(
                      keyName: 'blocked.unblockedBy',
                      label: 'Desbloqueado por',
                      options: _uniqueColumnOptions(
                        data.blockedUsers,
                        (blocked) => blocked.unblockedByUsername,
                      ),
                    ),
                  ],
                ),
                _AuditTab(
                  logs: auditLogs,
                  onRefresh: _refresh,
                  filters: [
                    _dateColumnFilter('audit.createdAt', 'Fecha'),
                    _textColumnFilter(
                      keyName: 'audit.actor',
                      label: 'Usuario',
                      options: _uniqueColumnOptions(
                        data.auditLogs,
                        (log) => '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'audit.action',
                      label: 'Acción',
                      options: _uniqueColumnOptions(data.auditLogs, (log) => log.action),
                    ),
                    _textColumnFilter(
                      keyName: 'audit.entity',
                      label: 'Entidad',
                      options: _uniqueColumnOptions(
                        data.auditLogs,
                        (log) => '${log.entityType} ${log.entityId ?? ''}',
                      ),
                    ),
                    _ipColumnFilter('audit.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'audit.userAgent',
                      label: 'Navegador',
                      options: _uniqueColumnOptions(data.auditLogs, (log) => log.userAgent),
                    ),
                  ],
                ),
                _LoginAttemptsTab(
                  attempts: loginAttempts,
                  onRefresh: _refresh,
                  filters: [
                    _dateColumnFilter('logins.createdAt', 'Fecha'),
                    _textColumnFilter(
                      keyName: 'logins.username',
                      label: 'Usuario',
                      options: _uniqueColumnOptions(data.loginAttempts, (attempt) => attempt.username),
                    ),
                    _textColumnFilter(
                      keyName: 'logins.result',
                      label: 'Resultado',
                      options: _uniqueColumnOptions(
                        data.loginAttempts,
                        (attempt) => attempt.success ? 'Correcto' : 'Fallido',
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'logins.reason',
                      label: 'Motivo',
                      options: _uniqueColumnOptions(data.loginAttempts, (attempt) => attempt.reason),
                    ),
                    _ipColumnFilter('logins.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'logins.userAgent',
                      label: 'Navegador',
                      options: _uniqueColumnOptions(data.loginAttempts, (attempt) => attempt.userAgent),
                    ),
                  ],
                ),
                _SessionsTab(
                  sessions: sessions,
                  onRefresh: _refresh,
                  filters: [
                    _dateColumnFilter('sessions.createdAt', 'Creada'),
                    _textColumnFilter(
                      keyName: 'sessions.username',
                      label: 'Usuario',
                      options: _uniqueColumnOptions(data.sessions, (session) => session.username),
                    ),
                    _textColumnFilter(
                      keyName: 'sessions.role',
                      label: 'Rol',
                      options: _uniqueColumnOptions(data.sessions, (session) => session.role),
                    ),
                    _textColumnFilter(
                      keyName: 'sessions.status',
                      label: 'Estado',
                      options: _uniqueColumnOptions(
                        data.sessions,
                        (session) => session.active ? 'Activa' : 'Cerrada/expirada',
                      ),
                    ),
                    _dateColumnFilter('sessions.expiresAt', 'Expira'),
                    _ipColumnFilter('sessions.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'sessions.userAgent',
                      label: 'Navegador',
                      options: _uniqueColumnOptions(data.sessions, (session) => session.userAgent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesUserFilters(ManagedUser user) {
    return _matchesText('users.username', user.username) &&
        _matchesText('users.displayName', user.displayName) &&
        _matchesText('users.role', user.role) &&
        _matchesText('users.status', user.active ? 'Activo' : 'Revocado');
  }

  bool _matchesBlockedUserFilters(BlockedLoginUser blockedUser) {
    return _matchesText('blocked.username', blockedUser.username) &&
        _matchesText('blocked.displayName', blockedUser.displayName) &&
        _matchesIp('blocked.ip', blockedUser.ipAddress) &&
        _matchesText('blocked.failedAttempts', '${blockedUser.failedAttempts}') &&
        _matchesText(
          'blocked.status',
          blockedUser.active ? 'Bloqueado' : 'Liberado/expirado',
        ) &&
        _matchesDate('blocked.blockedAt', blockedUser.blockedAt) &&
        _matchesDate('blocked.expiresAt', blockedUser.expiresAt) &&
        _matchesText('blocked.unblockedBy', blockedUser.unblockedByUsername);
  }

  bool _matchesAuditLogFilters(AuditLogEntry log) {
    return _matchesDate('audit.createdAt', log.createdAt) &&
        _matchesText('audit.actor', '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}') &&
        _matchesText('audit.action', log.action) &&
        _matchesText('audit.entity', '${log.entityType} ${log.entityId ?? ''}') &&
        _matchesIp('audit.ip', log.ipAddress) &&
        _matchesText('audit.userAgent', log.userAgent);
  }

  bool _matchesLoginAttemptFilters(LoginAttempt attempt) {
    return _matchesDate('logins.createdAt', attempt.createdAt) &&
        _matchesText('logins.username', attempt.username) &&
        _matchesText('logins.result', attempt.success ? 'Correcto' : 'Fallido') &&
        _matchesText('logins.reason', attempt.reason) &&
        _matchesIp('logins.ip', attempt.ipAddress) &&
        _matchesText('logins.userAgent', attempt.userAgent);
  }

  bool _matchesSessionFilters(AdminSession session) {
    return _matchesDate('sessions.createdAt', session.createdAt) &&
        _matchesText('sessions.username', session.username) &&
        _matchesText('sessions.role', session.role) &&
        _matchesText('sessions.status', session.active ? 'Activa' : 'Cerrada/expirada') &&
        _matchesDate('sessions.expiresAt', session.expiresAt) &&
        _matchesIp('sessions.ip', session.ipAddress) &&
        _matchesText('sessions.userAgent', session.userAgent);
  }

  bool _matchesText(String keyName, String? value) {
    final query = _normalize(_textFilters[keyName] ?? '');
    if (query.isEmpty) return true;
    return _normalize(value ?? '').contains(query);
  }

  bool _matchesDate(String keyName, DateTime? value) {
    final selectedDate = _dateFilters[keyName];
    if (selectedDate == null) return true;
    if (value == null) return false;
    return value.year == selectedDate.year &&
        value.month == selectedDate.month &&
        value.day == selectedDate.day;
  }

  bool _matchesIp(String keyName, String? value) {
    final filters = [
      _textFilters['$keyName.0'] ?? '',
      _textFilters['$keyName.1'] ?? '',
      _textFilters['$keyName.2'] ?? '',
      _textFilters['$keyName.3'] ?? '',
    ].map(_normalize).toList();
    if (filters.every((filter) => filter.isEmpty)) return true;
    final segments = (value ?? '').split('.');
    if (segments.length != 4) return false;
    for (var index = 0; index < filters.length; index++) {
      final filter = filters[index];
      if (filter.isEmpty) continue;
      if (!segments[index].startsWith(filter)) return false;
    }
    return true;
  }

  List<String> _uniqueColumnOptions<T>(
    List<T> rows,
    String? Function(T row) valueForRow,
  ) {
    final byNormalizedValue = <String, String>{};
    for (final row in rows) {
      final cleanValue = valueForRow(row)?.trim();
      if (cleanValue == null || cleanValue.isEmpty || cleanValue == '—') continue;
      byNormalizedValue.putIfAbsent(_normalize(cleanValue), () => cleanValue);
    }
    final options = byNormalizedValue.values.toList()
      ..sort((a, b) => _normalize(a).compareTo(_normalize(b)));
    return options;
  }

  Widget _textColumnFilter({
    required String keyName,
    required String label,
    required List<String> options,
  }) {
    return SizedBox(
      width: 240,
      child: _SearchableTableFilter(
        label: label,
        value: _textFilters[keyName] ?? '',
        options: options,
        onChanged: (value) => setState(() => _textFilters[keyName] = value),
      ),
    );
  }

  Widget _dateColumnFilter(String keyName, String label) {
    return SizedBox(
      width: 190,
      child: _DateColumnFilter(
        label: label,
        value: _dateFilters[keyName],
        onChanged: (value) => setState(() => _dateFilters[keyName] = value),
      ),
    );
  }

  Widget _ipColumnFilter(String keyName, String label) {
    return SizedBox(
      width: 330,
      child: _IpColumnFilter(
        label: label,
        values: [
          _textFilters['$keyName.0'] ?? '',
          _textFilters['$keyName.1'] ?? '',
          _textFilters['$keyName.2'] ?? '',
          _textFilters['$keyName.3'] ?? '',
        ],
        onChanged: (index, value) => setState(() => _textFilters['$keyName.$index'] = value),
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
    required this.filters,
  });

  final List<ManagedUser> users;
  final VoidCallback onCreate;
  final ValueChanged<ManagedUser> onEdit;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filters: filters,
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
    required this.filters,
  });

  final List<BlockedLoginUser> blockedUsers;
  final ValueChanged<BlockedLoginUser> onUnblock;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filters: filters,
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
  const _AuditTab({
    required this.logs,
    required this.onRefresh,
    required this.filters,
  });

  final List<AuditLogEntry> logs;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filters: filters,
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
  const _LoginAttemptsTab({
    required this.attempts,
    required this.onRefresh,
    required this.filters,
  });

  final List<LoginAttempt> attempts;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filters: filters,
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
  const _SessionsTab({
    required this.sessions,
    required this.onRefresh,
    required this.filters,
  });

  final List<AdminSession> sessions;
  final Future<void> Function() onRefresh;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      onRefresh: onRefresh,
      filters: filters,
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
  const _TableShell({
    required this.child,
    required this.onRefresh,
    this.action,
    this.filters = const [],
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? action;
  final List<Widget> filters;

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
                if (filters.isNotEmpty || action != null) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      ...filters,
                      if (action != null) action!,
                    ],
                  ),
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

class _SearchableTableFilter extends StatefulWidget {
  const _SearchableTableFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchableTableFilter> createState() => _SearchableTableFilterState();
}

class _SearchableTableFilterState extends State<_SearchableTableFilter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SearchableTableFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        return _rankedMatches(widget.options, textEditingValue.text);
      },
      onSelected: (selected) {
        _controller.text = selected;
        _controller.selection = TextSelection.collapsed(offset: selected.length);
        widget.onChanged(selected);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: 'Escribe o selecciona un valor',
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar filtro',
                        onPressed: () {
                          controller.clear();
                          widget.onChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final visibleOptions = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: visibleOptions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = visibleOptions[index];
                  return ListTile(
                    dense: true,
                    title: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateColumnFilter extends StatelessWidget {
  const _DateColumnFilter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: value == null
            ? null
            : IconButton(
                tooltip: 'Limpiar fecha',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close),
              ),
      ),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 1),
          );
          if (picked != null) onChanged(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            value == null ? 'Cualquier fecha' : _formatDateOnly(value!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _IpColumnFilter extends StatefulWidget {
  const _IpColumnFilter({
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final void Function(int index, String value) onChanged;

  @override
  State<_IpColumnFilter> createState() => _IpColumnFilterState();
}

class _IpColumnFilterState extends State<_IpColumnFilter> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (var index = 0; index < 4; index++)
        TextEditingController(text: index < widget.values.length ? widget.values[index] : ''),
    ];
  }

  @override
  void didUpdateWidget(covariant _IpColumnFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var index = 0; index < _controllers.length; index++) {
      final value = index < widget.values.length ? widget.values[index] : '';
      if (_controllers[index].text != value) {
        _controllers[index].text = value;
        _controllers[index].selection = TextSelection.collapsed(offset: value.length);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lan_outlined),
        suffixIcon: _controllers.every((controller) => controller.text.isEmpty)
            ? null
            : IconButton(
                tooltip: 'Limpiar IP',
                onPressed: () {
                  for (var index = 0; index < _controllers.length; index++) {
                    _controllers[index].clear();
                    widget.onChanged(index, '');
                  }
                },
                icon: const Icon(Icons.close),
              ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _controllers.length; index++) ...[
            Expanded(
              child: TextField(
                controller: _controllers[index],
                maxLength: 3,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: index == 0 ? '198' : '',
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  final cleanValue = value.replaceAll(RegExp('[^0-9]'), '');
                  final nextValue = cleanValue.length > 3 ? cleanValue.substring(0, 3) : cleanValue;
                  if (nextValue != value) {
                    _controllers[index].text = nextValue;
                    _controllers[index].selection =
                        TextSelection.collapsed(offset: nextValue.length);
                  }
                  widget.onChanged(index, nextValue);
                },
              ),
            ),
            if (index < _controllers.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text('.', style: Theme.of(context).textTheme.titleMedium),
              ),
          ],
        ],
      ),
    );
  }
}

Iterable<String> _rankedMatches(List<String> options, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return options.take(30);

  final prefixMatches = <String>[];
  final start = _lowerBoundByNormalized(options, normalizedQuery);
  for (var index = start; index < options.length && prefixMatches.length < 20; index++) {
    final option = options[index];
    if (!_normalize(option).startsWith(normalizedQuery)) break;
    prefixMatches.add(option);
  }

  final seen = prefixMatches.toSet();
  final containsMatches = <String>[];
  for (final option in options) {
    if (prefixMatches.length + containsMatches.length >= 30) break;
    if (seen.contains(option)) continue;
    if (_normalize(option).contains(normalizedQuery)) containsMatches.add(option);
  }

  return [...prefixMatches, ...containsMatches];
}

int _lowerBoundByNormalized(List<String> options, String query) {
  var low = 0;
  var high = options.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (_normalize(options[middle]).compareTo(query) < 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

String _normalize(String value) => value.trim().toLowerCase();

String _formatDateOnly(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
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

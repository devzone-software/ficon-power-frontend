import 'dart:async';

import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/table_filters.dart';

part '../admin/admin_tables.dart';
part '../admin/admin_user_dialog.dart';

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
  final ColumnFilterState _columnFilters = ColumnFilterState();

  @override
  void initState() {
    super.initState();
    _refresh(showLoading: true);
    _liveRefreshTimer = Timer.periodic(_liveRefreshInterval, (_) => _refresh());
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
      builder: (_) => _UserDialog(
        repository: widget.repository,
        currentUser: widget.currentUser,
        user: user,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null ? 'Usuario creado.' : 'Usuario actualizado.',
          ),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo desbloquear: $e')));
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
      return ErrorView(
        error: _error,
        onRetry: () => _refresh(showLoading: true),
      );
    }

    final data = _data!;
    final users = data.users.where(_matchesUserFilters).toList();
    final blockedUsers = data.blockedUsers
        .where(_matchesBlockedUserFilters)
        .toList();
    final auditLogs = data.auditLogs.where(_matchesAuditLogFilters).toList();
    final loginAttempts = data.loginAttempts
        .where(_matchesLoginAttemptFilters)
        .toList();
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
                      options: _uniqueColumnOptions(
                        data.users,
                        (user) => user.username,
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'users.displayName',
                      label: 'Nombre',
                      options: _uniqueColumnOptions(
                        data.users,
                        (user) => user.displayName,
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'users.role',
                      label: 'Rol',
                      options: _uniqueColumnOptions(
                        data.users,
                        (user) => user.role,
                      ),
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
                      options: _uniqueColumnOptions(
                        data.blockedUsers,
                        (blocked) => blocked.username,
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'blocked.displayName',
                      label: 'Nombre',
                      options: _uniqueColumnOptions(
                        data.blockedUsers,
                        (blocked) => blocked.displayName,
                      ),
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
                        (blocked) =>
                            blocked.active ? 'Bloqueado' : 'Liberado/expirado',
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
                        (log) =>
                            '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'audit.action',
                      label: 'Acción',
                      options: _uniqueColumnOptions(
                        data.auditLogs,
                        (log) => log.action,
                      ),
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
                      options: _uniqueColumnOptions(
                        data.auditLogs,
                        (log) => log.userAgent,
                      ),
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
                      options: _uniqueColumnOptions(
                        data.loginAttempts,
                        (attempt) => attempt.username,
                      ),
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
                      options: _uniqueColumnOptions(
                        data.loginAttempts,
                        (attempt) => attempt.reason,
                      ),
                    ),
                    _ipColumnFilter('logins.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'logins.userAgent',
                      label: 'Navegador',
                      options: _uniqueColumnOptions(
                        data.loginAttempts,
                        (attempt) => attempt.userAgent,
                      ),
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
                      options: _uniqueColumnOptions(
                        data.sessions,
                        (session) => session.username,
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'sessions.role',
                      label: 'Rol',
                      options: _uniqueColumnOptions(
                        data.sessions,
                        (session) => session.role,
                      ),
                    ),
                    _textColumnFilter(
                      keyName: 'sessions.status',
                      label: 'Estado',
                      options: _uniqueColumnOptions(
                        data.sessions,
                        (session) =>
                            session.active ? 'Activa' : 'Cerrada/expirada',
                      ),
                    ),
                    _dateColumnFilter('sessions.expiresAt', 'Expira'),
                    _ipColumnFilter('sessions.ip', 'IP'),
                    _textColumnFilter(
                      keyName: 'sessions.userAgent',
                      label: 'Navegador',
                      options: _uniqueColumnOptions(
                        data.sessions,
                        (session) => session.userAgent,
                      ),
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
        _matchesText(
          'blocked.failedAttempts',
          '${blockedUser.failedAttempts}',
        ) &&
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
        _matchesText(
          'audit.actor',
          '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
        ) &&
        _matchesText('audit.action', log.action) &&
        _matchesText(
          'audit.entity',
          '${log.entityType} ${log.entityId ?? ''}',
        ) &&
        _matchesIp('audit.ip', log.ipAddress) &&
        _matchesText('audit.userAgent', log.userAgent);
  }

  bool _matchesLoginAttemptFilters(LoginAttempt attempt) {
    return _matchesDate('logins.createdAt', attempt.createdAt) &&
        _matchesText('logins.username', attempt.username) &&
        _matchesText(
          'logins.result',
          attempt.success ? 'Correcto' : 'Fallido',
        ) &&
        _matchesText('logins.reason', attempt.reason) &&
        _matchesIp('logins.ip', attempt.ipAddress) &&
        _matchesText('logins.userAgent', attempt.userAgent);
  }

  bool _matchesSessionFilters(AdminSession session) {
    return _matchesDate('sessions.createdAt', session.createdAt) &&
        _matchesText('sessions.username', session.username) &&
        _matchesText('sessions.role', session.role) &&
        _matchesText(
          'sessions.status',
          session.active ? 'Activa' : 'Cerrada/expirada',
        ) &&
        _matchesDate('sessions.expiresAt', session.expiresAt) &&
        _matchesIp('sessions.ip', session.ipAddress) &&
        _matchesText('sessions.userAgent', session.userAgent);
  }

  bool _matchesText(String keyName, String? value) {
    return _columnFilters.matchesText(keyName, value);
  }

  bool _matchesDate(String keyName, DateTime? value) {
    return _columnFilters.matchesDate(keyName, value);
  }

  bool _matchesIp(String keyName, String? value) {
    return _columnFilters.matchesIp(keyName, value);
  }

  List<String> _uniqueColumnOptions<T>(
    List<T> rows,
    String? Function(T row) valueForRow,
  ) {
    return uniqueColumnOptions(rows, valueForRow);
  }

  Widget _textColumnFilter({
    required String keyName,
    required String label,
    required List<String> options,
  }) {
    return SizedBox(
      width: 240,
      child: TextColumnFilter(
        label: label,
        value: _columnFilters.text(keyName),
        options: options,
        onChanged: (value) =>
            setState(() => _columnFilters.setText(keyName, value)),
        width: 240,
      ),
    );
  }

  Widget _dateColumnFilter(String keyName, String label) {
    return SizedBox(
      width: 190,
      child: DateColumnFilter(
        label: label,
        value: _columnFilters.date(keyName),
        onChanged: (value) =>
            setState(() => _columnFilters.setDate(keyName, value)),
        width: 190,
      ),
    );
  }

  Widget _ipColumnFilter(String keyName, String label) {
    return SizedBox(
      width: 330,
      child: IpColumnFilter(
        label: label,
        values: _columnFilters.ipSegments(keyName),
        onChanged: (index, value) =>
            setState(() => _columnFilters.setIpSegment(keyName, index, value)),
        width: 330,
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

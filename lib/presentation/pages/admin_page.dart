import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../application/admin_activity_controller.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../admin/admin_table_filters.dart';
import '../admin/audit_tab.dart';
import '../admin/blocked_users_tab.dart';
import '../admin/login_attempts_tab.dart';
import '../admin/sessions_tab.dart';
import '../admin/users_tab.dart';
import '../theme/ficon_theme.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

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
  late final AdminActivityController _activityController;
  late final AdminTableFilters _filters;

  @override
  void initState() {
    super.initState();
    _activityController = AdminActivityController(load: _load)..start();
    _filters = AdminTableFilters(onChanged: () => setState(() {}));
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<AdminActivityData> _load() async {
    final results = await Future.wait([
      widget.repository.fetchUsers(),
      widget.repository.fetchAuditLogs(),
      widget.repository.fetchLoginAttempts(),
      widget.repository.fetchAdminSessions(),
      widget.repository.fetchBlockedUsers(),
    ]);
    return AdminActivityData(
      users: results[0] as List<ManagedUser>,
      auditLogs: results[1] as List<AuditLogEntry>,
      loginAttempts: results[2] as List<LoginAttempt>,
      sessions: results[3] as List<AdminSession>,
      blockedUsers: results[4] as List<BlockedLoginUser>,
    );
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
      await _activityController.refresh();
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
      await _activityController.refresh();
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
      body: AnimatedBuilder(
        animation: _activityController,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_activityController.loading && _activityController.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activityController.error != null && _activityController.data == null) {
      return ErrorView(
        error: _activityController.error,
        onRetry: () => _activityController.refresh(showLoading: true),
      );
    }

    final data = _activityController.data!;
    final users = data.users.where(_filters.matchesUser).toList();
    final blockedUsers = data.blockedUsers
        .where(_filters.matchesBlockedUser)
        .toList();
    final auditLogs = data.auditLogs.where(_filters.matchesAuditLog).toList();
    final loginAttempts = data.loginAttempts
        .where(_filters.matchesLoginAttempt)
        .toList();
    final sessions = data.sessions.where(_filters.matchesSession).toList();

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
                UsersTab(
                  users: users,
                  onCreate: () => _openUserDialog(),
                  onEdit: _openUserDialog,
                  onRefresh: _activityController.refresh,
                  filters: [
                    _filters.text(
                      keyName: 'users.username',
                      label: 'Usuario',
                      options: _filters.options(
                        data.users,
                        (user) => user.username,
                      ),
                    ),
                    _filters.text(
                      keyName: 'users.displayName',
                      label: 'Nombre',
                      options: _filters.options(
                        data.users,
                        (user) => user.displayName,
                      ),
                    ),
                    _filters.text(
                      keyName: 'users.role',
                      label: 'Rol',
                      options: _filters.options(
                        data.users,
                        (user) => user.role,
                      ),
                    ),
                    _filters.text(
                      keyName: 'users.status',
                      label: 'Estado',
                      options: _filters.options(
                        data.users,
                        (user) => user.active ? 'Activo' : 'Revocado',
                      ),
                    ),
                  ],
                ),
                BlockedUsersTab(
                  blockedUsers: blockedUsers,
                  onUnblock: _unblockUser,
                  onRefresh: _activityController.refresh,
                  filters: [
                    _filters.text(
                      keyName: 'blocked.username',
                      label: 'Usuario',
                      options: _filters.options(
                        data.blockedUsers,
                        (blocked) => blocked.username,
                      ),
                    ),
                    _filters.text(
                      keyName: 'blocked.displayName',
                      label: 'Nombre',
                      options: _filters.options(
                        data.blockedUsers,
                        (blocked) => blocked.displayName,
                      ),
                    ),
                    _filters.ip('blocked.ip', 'IP'),
                    _filters.text(
                      keyName: 'blocked.failedAttempts',
                      label: 'Fallos',
                      options: _filters.options(
                        data.blockedUsers,
                        (blocked) => '${blocked.failedAttempts}',
                      ),
                    ),
                    _filters.text(
                      keyName: 'blocked.status',
                      label: 'Estado',
                      options: _filters.options(
                        data.blockedUsers,
                        (blocked) =>
                            blocked.active ? 'Bloqueado' : 'Liberado/expirado',
                      ),
                    ),
                    _filters.date('blocked.blockedAt', 'Bloqueado'),
                    _filters.date('blocked.expiresAt', 'Expira'),
                    _filters.text(
                      keyName: 'blocked.unblockedBy',
                      label: 'Desbloqueado por',
                      options: _filters.options(
                        data.blockedUsers,
                        (blocked) => blocked.unblockedByUsername,
                      ),
                    ),
                  ],
                ),
                AuditTab(
                  logs: auditLogs,
                  onRefresh: _activityController.refresh,
                  filters: [
                    _filters.date('audit.createdAt', 'Fecha'),
                    _filters.text(
                      keyName: 'audit.actor',
                      label: 'Usuario',
                      options: _filters.options(
                        data.auditLogs,
                        (log) =>
                            '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
                      ),
                    ),
                    _filters.text(
                      keyName: 'audit.action',
                      label: 'Acción',
                      options: _filters.options(
                        data.auditLogs,
                        (log) => log.action,
                      ),
                    ),
                    _filters.text(
                      keyName: 'audit.entity',
                      label: 'Entidad',
                      options: _filters.options(
                        data.auditLogs,
                        (log) => '${log.entityType} ${log.entityId ?? ''}',
                      ),
                    ),
                    _filters.ip('audit.ip', 'IP'),
                    _filters.text(
                      keyName: 'audit.userAgent',
                      label: 'Navegador',
                      options: _filters.options(
                        data.auditLogs,
                        (log) => log.userAgent,
                      ),
                    ),
                  ],
                ),
                LoginAttemptsTab(
                  attempts: loginAttempts,
                  onRefresh: _activityController.refresh,
                  filters: [
                    _filters.date('logins.createdAt', 'Fecha'),
                    _filters.text(
                      keyName: 'logins.username',
                      label: 'Usuario',
                      options: _filters.options(
                        data.loginAttempts,
                        (attempt) => attempt.username,
                      ),
                    ),
                    _filters.text(
                      keyName: 'logins.result',
                      label: 'Resultado',
                      options: _filters.options(
                        data.loginAttempts,
                        (attempt) => attempt.success ? 'Correcto' : 'Fallido',
                      ),
                    ),
                    _filters.text(
                      keyName: 'logins.reason',
                      label: 'Motivo',
                      options: _filters.options(
                        data.loginAttempts,
                        (attempt) => attempt.reason,
                      ),
                    ),
                    _filters.ip('logins.ip', 'IP'),
                    _filters.text(
                      keyName: 'logins.userAgent',
                      label: 'Navegador',
                      options: _filters.options(
                        data.loginAttempts,
                        (attempt) => attempt.userAgent,
                      ),
                    ),
                  ],
                ),
                SessionsTab(
                  sessions: sessions,
                  onRefresh: _activityController.refresh,
                  filters: [
                    _filters.date('sessions.createdAt', 'Creada'),
                    _filters.text(
                      keyName: 'sessions.username',
                      label: 'Usuario',
                      options: _filters.options(
                        data.sessions,
                        (session) => session.username,
                      ),
                    ),
                    _filters.text(
                      keyName: 'sessions.role',
                      label: 'Rol',
                      options: _filters.options(
                        data.sessions,
                        (session) => session.role,
                      ),
                    ),
                    _filters.text(
                      keyName: 'sessions.status',
                      label: 'Estado',
                      options: _filters.options(
                        data.sessions,
                        (session) =>
                            session.active ? 'Activa' : 'Cerrada/expirada',
                      ),
                    ),
                    _filters.date('sessions.expiresAt', 'Expira'),
                    _filters.ip('sessions.ip', 'IP'),
                    _filters.text(
                      keyName: 'sessions.userAgent',
                      label: 'Navegador',
                      options: _filters.options(
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
}

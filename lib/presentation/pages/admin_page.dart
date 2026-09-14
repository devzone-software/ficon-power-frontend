import 'dart:async';

import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../application/admin_activity_controller.dart';
import '../../application/user_error_message.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../../domain/realtime_change.dart';
import '../admin/admin_table_filters.dart';
import '../admin/admin_tabs.dart';
import '../admin/whatsapp_recipients_tab.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/common.dart';

part '../admin/admin_user_dialog.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onLogout,
    this.realtimeChanges,
  });

  final FiconMonitoringRepository repository;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final AdminActivityController _activityController;
  late final AdminTableFilters _filters;
  StreamSubscription<RealtimeChange>? _realtimeSubscription;
  Timer? _realtimeDebounce;

  @override
  void initState() {
    super.initState();
    _activityController = AdminActivityController(load: _load);
    if (widget.currentUser.canManageUsers) {
      _activityController.start();
    }
    _realtimeSubscription = widget.realtimeChanges
        ?.where(
          (change) => const {
            'user',
            'audit_log',
            'login_attempt',
            'auth_session',
          }.contains(change.entityType),
        )
        .listen(_scheduleRealtimeRefresh);
    _filters = AdminTableFilters(onChanged: () => setState(() {}));
  }

  void _scheduleRealtimeRefresh(RealtimeChange _) {
    if (!widget.currentUser.canManageUsers) return;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_activityController.refresh()),
    );
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    unawaited(_realtimeSubscription?.cancel());
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.forAction('No se pudo desbloquear', e),
          ),
        ),
      );
    }
  }

  Future<void> _revokeSession(AdminSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar sesión'),
        content: Text(
          '¿Cerrar la sesión activa de ${session.username} en '
          '${session.ipAddress ?? 'IP desconocida'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.revokeAdminSession(session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesión de ${session.username} revocada.')),
      );
      await _activityController.refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.forAction('No se pudo revocar la sesión', error),
          ),
        ),
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
      realtimeChanges: widget.realtimeChanges,
      body: AnimatedBuilder(
        animation: _activityController,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!widget.currentUser.canManageUsers) {
      return _AdminRoleOverview(
        repository: widget.repository,
        realtimeChanges: widget.realtimeChanges,
      );
    }
    if (_activityController.loading && _activityController.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activityController.error != null && _activityController.data == null) {
      return ErrorView(
        error: _activityController.error,
        onRetry: () => _activityController.refresh(showLoading: true),
      );
    }

    return AdminTabs(
      data: _activityController.data!,
      filters: _filters,
      onCreateUser: _openUserDialog,
      onEditUser: _openUserDialog,
      onUnblockUser: _unblockUser,
      onRevokeSession: _revokeSession,
      onRefresh: _activityController.refresh,
      repository: widget.repository,
      realtimeChanges: widget.realtimeChanges,
    );
  }
}

class _AdminRoleOverview extends StatelessWidget {
  const _AdminRoleOverview({required this.repository, this.realtimeChanges});

  final FiconMonitoringRepository repository;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.router_outlined),
              title: const Text('Gestión de medidores'),
              subtitle: const Text('Editar nombre, sede y datos autorizados.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.devices),
            ),
          ),
        ),
        Expanded(
          child: WhatsAppRecipientsTab(
            repository: repository,
            realtimeChanges: realtimeChanges,
          ),
        ),
      ],
    );
  }
}

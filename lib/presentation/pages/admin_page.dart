import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../application/admin_activity_controller.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../admin/admin_table_filters.dart';
import '../admin/admin_tabs.dart';
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
    _activityController = AdminActivityController(load: _load);
    if (widget.currentUser.canManageUsers) {
      _activityController.start();
    }
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
        SnackBar(content: Text('No se pudo revocar la sesión: $error')),
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
      body: AnimatedBuilder(
        animation: _activityController,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!widget.currentUser.canManageUsers) {
      return const _AdminRoleOverview();
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
    );
  }
}

class _AdminRoleOverview extends StatelessWidget {
  const _AdminRoleOverview();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Herramientas administrativas',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'El rol ADMIN puede editar la información operativa de los '
          'medidores. Usuarios, auditoría, bloqueos y sesiones permanecen '
          'reservados para SUPERADMIN.',
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.router_outlined),
            title: const Text('Gestión de medidores'),
            subtitle: const Text('Editar nombre, sede y datos autorizados.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.devices),
          ),
        ),
      ],
    );
  }
}

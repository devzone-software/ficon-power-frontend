import 'package:flutter/material.dart';

import '../../application/admin_activity_controller.dart';
import '../../domain/admin_models.dart';
import '../../domain/realtime_change.dart';
import '../theme/ficon_theme.dart';
import 'admin_filter_definitions.dart';
import 'admin_table_filters.dart';
import 'audit_tab.dart';
import 'blocked_users_tab.dart';
import 'login_attempts_tab.dart';
import 'sessions_tab.dart';
import 'users_tab.dart';
import 'whatsapp_recipients_tab.dart';
import '../../adapters/http/ficon_monitoring_repository.dart';

class AdminTabs extends StatelessWidget {
  const AdminTabs({
    super.key,
    required this.data,
    required this.filters,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onUnblockUser,
    required this.onRevokeSession,
    required this.onRefresh,
    required this.repository,
    this.realtimeChanges,
  });

  final AdminActivityData data;
  final AdminTableFilters filters;
  final VoidCallback onCreateUser;
  final ValueChanged<ManagedUser> onEditUser;
  final ValueChanged<BlockedLoginUser> onUnblockUser;
  final ValueChanged<AdminSession> onRevokeSession;
  final Future<void> Function() onRefresh;
  final FiconMonitoringRepository repository;
  final Stream<RealtimeChange>? realtimeChanges;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final definitions = AdminFilterDefinitions(
      filters: filters,
      data: data,
      compact: compact,
    );
    final tabs = <Tab>[
      const Tab(text: 'Usuarios'),
      const Tab(text: 'Bloqueados'),
      if (!compact) const Tab(text: 'Audit logs'),
      if (!compact) const Tab(text: 'Logins'),
      if (!compact) const Tab(text: 'Sesiones'),
      const Tab(text: 'WhatsApp'),
    ];
    final views = <Widget>[
      UsersTab(
        users: data.users.where(filters.matchesUser).toList(),
        onCreate: onCreateUser,
        onEdit: onEditUser,
        onRefresh: onRefresh,
        filters: definitions.users,
      ),
      BlockedUsersTab(
        blockedUsers: filters.sortBlockedUsers(
          data.blockedUsers.where(filters.matchesBlockedUser),
        ),
        onUnblock: onUnblockUser,
        onRefresh: onRefresh,
        filters: definitions.blockedUsers,
      ),
      if (!compact)
        AuditTab(
          logs: data.auditLogs.where(filters.matchesAuditLog).toList(),
          onRefresh: onRefresh,
          filters: definitions.auditLogs,
        ),
      if (!compact)
        LoginAttemptsTab(
          attempts: data.loginAttempts
              .where(filters.matchesLoginAttempt)
              .toList(),
          onRefresh: onRefresh,
          filters: definitions.loginAttempts,
        ),
      if (!compact)
        SessionsTab(
          sessions: data.sessions.where(filters.matchesSession).toList(),
          onRefresh: onRefresh,
          onRevoke: onRevokeSession,
          filters: definitions.sessions,
        ),
      WhatsAppRecipientsTab(
        repository: repository,
        realtimeChanges: realtimeChanges,
      ),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: FiconColors.logoBlue,
              unselectedLabelColor: FiconColors.deepAlt,
              tabs: tabs,
            ),
          ),
          Expanded(child: TabBarView(children: views)),
        ],
      ),
    );
  }
}

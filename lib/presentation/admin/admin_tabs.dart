import 'package:flutter/material.dart';

import '../../application/admin_activity_controller.dart';
import '../../domain/admin_models.dart';
import '../theme/ficon_theme.dart';
import 'admin_filter_definitions.dart';
import 'admin_table_filters.dart';
import 'audit_tab.dart';
import 'blocked_users_tab.dart';
import 'login_attempts_tab.dart';
import 'sessions_tab.dart';
import 'users_tab.dart';

class AdminTabs extends StatelessWidget {
  const AdminTabs({
    super.key,
    required this.data,
    required this.filters,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onUnblockUser,
    required this.onRefresh,
  });

  final AdminActivityData data;
  final AdminTableFilters filters;
  final VoidCallback onCreateUser;
  final ValueChanged<ManagedUser> onEditUser;
  final ValueChanged<BlockedLoginUser> onUnblockUser;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final definitions = AdminFilterDefinitions(filters: filters, data: data);
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const Material(
            color: Colors.white,
            child: TabBar(
              labelColor: FiconColors.logoBlue,
              unselectedLabelColor: FiconColors.deepAlt,
              tabs: [
                Tab(text: 'Usuarios'),
                Tab(text: 'Bloqueados'),
                Tab(text: 'Audit logs'),
                Tab(text: 'Logins'),
                Tab(text: 'Sesiones'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                UsersTab(
                  users: data.users.where(filters.matchesUser).toList(),
                  onCreate: onCreateUser,
                  onEdit: onEditUser,
                  onRefresh: onRefresh,
                  filters: definitions.users,
                ),
                BlockedUsersTab(
                  blockedUsers: data.blockedUsers
                      .where(filters.matchesBlockedUser)
                      .toList(),
                  onUnblock: onUnblockUser,
                  onRefresh: onRefresh,
                  filters: definitions.blockedUsers,
                ),
                AuditTab(
                  logs: data.auditLogs.where(filters.matchesAuditLog).toList(),
                  onRefresh: onRefresh,
                  filters: definitions.auditLogs,
                ),
                LoginAttemptsTab(
                  attempts: data.loginAttempts
                      .where(filters.matchesLoginAttempt)
                      .toList(),
                  onRefresh: onRefresh,
                  filters: definitions.loginAttempts,
                ),
                SessionsTab(
                  sessions: data.sessions
                      .where(filters.matchesSession)
                      .toList(),
                  onRefresh: onRefresh,
                  filters: definitions.sessions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

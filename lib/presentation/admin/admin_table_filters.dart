import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/table_filters.dart';

class AdminTableFilters {
  AdminTableFilters({required this.onChanged});

  final VoidCallback onChanged;
  final ColumnFilterState state = ColumnFilterState();

  List<String> options<T>(List<T> rows, String? Function(T row) valueForRow) =>
      uniqueColumnOptions(rows, valueForRow);

  Widget text({
    required String keyName,
    required String label,
    required List<String> options,
  }) => TextColumnFilter(
    label: label,
    value: state.text(keyName),
    options: options,
    onChanged: (value) {
      state.setText(keyName, value);
      onChanged();
    },
    width: 240,
  );

  Widget date(String keyName, String label) => DateColumnFilter(
    label: label,
    value: state.date(keyName),
    onChanged: (value) {
      state.setDate(keyName, value);
      onChanged();
    },
    width: 190,
  );

  Widget ip(String keyName, String label) => IpColumnFilter(
    label: label,
    values: state.ipSegments(keyName),
    onChanged: (index, value) {
      state.setIpSegment(keyName, index, value);
      onChanged();
    },
    width: 330,
  );

  bool matchesUser(ManagedUser user) {
    return state.matchesText('users.username', user.username) &&
        state.matchesText('users.displayName', user.displayName) &&
        state.matchesText('users.role', user.role) &&
        state.matchesText('users.status', user.active ? 'Activo' : 'Revocado');
  }

  bool matchesBlockedUser(BlockedLoginUser user) {
    return state.matchesText('blocked.username', user.username) &&
        state.matchesText('blocked.displayName', user.displayName) &&
        state.matchesIp('blocked.ip', user.ipAddress) &&
        state.matchesText('blocked.failedAttempts', '${user.failedAttempts}') &&
        state.matchesText(
          'blocked.status',
          user.active ? 'Bloqueado' : 'Liberado/expirado',
        ) &&
        state.matchesDate('blocked.blockedAt', user.blockedAt) &&
        state.matchesDate('blocked.expiresAt', user.expiresAt) &&
        state.matchesText('blocked.unblockedBy', user.unblockedByUsername);
  }

  bool matchesAuditLog(AuditLogEntry log) {
    return state.matchesDate('audit.createdAt', log.createdAt) &&
        state.matchesText(
          'audit.actor',
          '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
        ) &&
        state.matchesText('audit.action', log.action) &&
        state.matchesText(
          'audit.entity',
          '${log.entityType} ${log.entityId ?? ''}',
        ) &&
        state.matchesIp('audit.ip', log.ipAddress) &&
        state.matchesText('audit.userAgent', log.userAgent);
  }

  bool matchesLoginAttempt(LoginAttempt attempt) {
    return state.matchesDate('logins.createdAt', attempt.createdAt) &&
        state.matchesText('logins.username', attempt.username) &&
        state.matchesText(
          'logins.result',
          attempt.success ? 'Correcto' : 'Fallido',
        ) &&
        state.matchesText('logins.reason', attempt.reason) &&
        state.matchesIp('logins.ip', attempt.ipAddress) &&
        state.matchesText('logins.userAgent', attempt.userAgent);
  }

  bool matchesSession(AdminSession session) {
    return state.matchesDate('sessions.createdAt', session.createdAt) &&
        state.matchesText('sessions.username', session.username) &&
        state.matchesText('sessions.role', session.role) &&
        state.matchesText(
          'sessions.status',
          session.active ? 'Activa' : 'Cerrada/expirada',
        ) &&
        state.matchesDate('sessions.expiresAt', session.expiresAt) &&
        state.matchesIp('sessions.ip', session.ipAddress) &&
        state.matchesText('sessions.userAgent', session.userAgent);
  }
}

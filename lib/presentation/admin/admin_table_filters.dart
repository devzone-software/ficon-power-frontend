import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/table_filters.dart';

class AdminTableFilters {
  AdminTableFilters({required this.onChanged});

  final VoidCallback onChanged;
  final ColumnFilterState state = ColumnFilterState();

  List<String> options<T>(List<T> rows, String? Function(T row) valueForRow) =>
      uniqueColumnOptions(rows, valueForRow);
  List<String> mergedOptions(Iterable<Iterable<String>> groups) =>
      mergeFilterOptions(groups);

  Widget text({
    required String keyName,
    required String label,
    required List<String> options,
    bool wideOnMobile = false,
    String? hint,
  }) => TextColumnFilter(
    label: label,
    value: state.text(keyName),
    options: options,
    wideOnMobile: wideOnMobile,
    hint: hint,
    onChanged: (value) {
      state.setText(keyName, value);
      onChanged();
    },
    width: 240,
  );

  Widget sort(String keyName, String label) => SortColumnControl(
    label: label,
    value: state.sort(keyName),
    onChanged: (value) {
      state.setSort(keyName, value);
      onChanged();
    },
  );

  Widget choice({
    required String keyName,
    required String label,
    required List<String> options,
    Map<String, String> labels = const {},
  }) => ChoiceColumnFilter(
    label: label,
    value: state.text(keyName),
    options: options,
    labels: labels,
    onChanged: (value) {
      state.setText(keyName, value);
      onChanged();
    },
  );

  Widget select({
    required String keyName,
    required String label,
    required List<String> options,
  }) => SelectColumnFilter(
    label: label,
    value: state.text(keyName),
    options: options,
    onChanged: (value) {
      state.setText(keyName, value);
      onChanged();
    },
    width: 240,
  );

  Widget date(String keyName, String label, {bool wideOnMobile = false}) =>
      DateColumnFilter(
        label: label,
        value: state.date(keyName),
        wideOnMobile: wideOnMobile,
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
    return state.matchesAnyText('users.query', [
          user.username,
          user.displayName,
        ]) &&
        state.matchesText('users.username', user.username) &&
        state.matchesText('users.displayName', user.displayName) &&
        state.matchesChoice('users.role', user.role) &&
        state.matchesChoice(
          'users.status',
          user.active ? 'Activo' : 'Revocado',
        );
  }

  bool matchesBlockedUser(BlockedLoginUser user) {
    return state.matchesAnyText('blocked.query', [
          user.username,
          user.displayName,
          user.ipAddress,
          user.unblockedByUsername,
        ]) &&
        state.matchesText('blocked.username', user.username) &&
        state.matchesText('blocked.displayName', user.displayName) &&
        state.matchesIp('blocked.ip', user.ipAddress) &&
        state.matchesChoice(
          'blocked.failedAttempts',
          '${user.failedAttempts}',
        ) &&
        state.matchesChoice(
          'blocked.status',
          user.active ? 'Bloqueado' : 'Liberado/expirado',
        ) &&
        state.matchesDate('blocked.blockedAt', user.blockedAt) &&
        state.matchesDate('blocked.expiresAt', user.expiresAt) &&
        state.matchesText('blocked.unblockedBy', user.unblockedByUsername);
  }

  bool matchesAuditLog(AuditLogEntry log) {
    return state.matchesAnyText('audit.query', [
          log.actorUsername,
          log.actorRole,
          log.action,
          log.entityType,
          log.entityId,
          log.ipAddress,
          log.userAgent,
        ]) &&
        state.matchesDate('audit.createdAt', log.createdAt) &&
        state.matchesText(
          'audit.actor',
          '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
        ) &&
        state.matchesChoice('audit.action', log.action) &&
        state.matchesChoice(
          'audit.entity',
          '${log.entityType} ${log.entityId ?? ''}',
        ) &&
        state.matchesIp('audit.ip', log.ipAddress) &&
        state.matchesText('audit.userAgent', log.userAgent);
  }

  bool matchesLoginAttempt(LoginAttempt attempt) {
    return state.matchesAnyText('logins.query', [
          attempt.username,
          attempt.reason,
          attempt.ipAddress,
          attempt.userAgent,
        ]) &&
        state.matchesDate('logins.createdAt', attempt.createdAt) &&
        state.matchesText('logins.username', attempt.username) &&
        state.matchesChoice(
          'logins.result',
          attempt.success ? 'Correcto' : 'Fallido',
        ) &&
        state.matchesChoice('logins.reason', attempt.reason) &&
        state.matchesIp('logins.ip', attempt.ipAddress) &&
        state.matchesText('logins.userAgent', attempt.userAgent);
  }

  bool matchesSession(AdminSession session) {
    return state.matchesAnyText('sessions.query', [
          session.username,
          session.role,
          session.ipAddress,
          session.userAgent,
        ]) &&
        state.matchesDate('sessions.createdAt', session.createdAt) &&
        state.matchesText('sessions.username', session.username) &&
        state.matchesChoice('sessions.role', session.role) &&
        state.matchesChoice(
          'sessions.status',
          session.active ? 'Activa' : 'Cerrada/expirada',
        ) &&
        state.matchesDate('sessions.expiresAt', session.expiresAt) &&
        state.matchesIp('sessions.ip', session.ipAddress) &&
        state.matchesText('sessions.userAgent', session.userAgent);
  }

  List<BlockedLoginUser> sortBlockedUsers(Iterable<BlockedLoginUser> users) =>
      state.sortedNumeric(
        'blocked.failedAttemptsSort',
        users,
        (user) => user.failedAttempts,
      );
}

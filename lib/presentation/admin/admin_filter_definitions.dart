import 'package:flutter/material.dart';

import '../../application/admin_activity_controller.dart';
import 'admin_table_filters.dart';

class AdminFilterDefinitions {
  const AdminFilterDefinitions({required this.filters, required this.data});

  final AdminTableFilters filters;
  final AdminActivityData data;

  List<Widget> get users => [
    filters.text(
      keyName: 'users.username',
      label: 'Usuario',
      options: filters.options(data.users, (user) => user.username),
    ),
    filters.text(
      keyName: 'users.displayName',
      label: 'Nombre',
      options: filters.options(data.users, (user) => user.displayName),
    ),
    filters.text(
      keyName: 'users.role',
      label: 'Rol',
      options: filters.options(data.users, (user) => user.role),
    ),
    filters.text(
      keyName: 'users.status',
      label: 'Estado',
      options: filters.options(
        data.users,
        (user) => user.active ? 'Activo' : 'Revocado',
      ),
    ),
  ];

  List<Widget> get blockedUsers => [
    filters.text(
      keyName: 'blocked.username',
      label: 'Usuario',
      options: filters.options(
        data.blockedUsers,
        (blocked) => blocked.username,
      ),
    ),
    filters.text(
      keyName: 'blocked.displayName',
      label: 'Nombre',
      options: filters.options(
        data.blockedUsers,
        (blocked) => blocked.displayName,
      ),
    ),
    filters.ip('blocked.ip', 'IP'),
    filters.text(
      keyName: 'blocked.failedAttempts',
      label: 'Fallos',
      options: filters.options(
        data.blockedUsers,
        (blocked) => '${blocked.failedAttempts}',
      ),
    ),
    filters.text(
      keyName: 'blocked.status',
      label: 'Estado',
      options: filters.options(
        data.blockedUsers,
        (blocked) => blocked.active ? 'Bloqueado' : 'Liberado/expirado',
      ),
    ),
    filters.date('blocked.blockedAt', 'Bloqueado'),
    filters.date('blocked.expiresAt', 'Expira'),
    filters.text(
      keyName: 'blocked.unblockedBy',
      label: 'Desbloqueado por',
      options: filters.options(
        data.blockedUsers,
        (blocked) => blocked.unblockedByUsername,
      ),
    ),
  ];

  List<Widget> get auditLogs => [
    filters.date('audit.createdAt', 'Fecha'),
    filters.text(
      keyName: 'audit.actor',
      label: 'Usuario',
      options: filters.options(
        data.auditLogs,
        (log) => '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
      ),
    ),
    filters.text(
      keyName: 'audit.action',
      label: 'Acción',
      options: filters.options(data.auditLogs, (log) => log.action),
    ),
    filters.text(
      keyName: 'audit.entity',
      label: 'Entidad',
      options: filters.options(
        data.auditLogs,
        (log) => '${log.entityType} ${log.entityId ?? ''}',
      ),
    ),
    filters.ip('audit.ip', 'IP'),
    filters.text(
      keyName: 'audit.userAgent',
      label: 'Navegador',
      options: filters.options(data.auditLogs, (log) => log.userAgent),
    ),
  ];

  List<Widget> get loginAttempts => [
    filters.date('logins.createdAt', 'Fecha'),
    filters.text(
      keyName: 'logins.username',
      label: 'Usuario',
      options: filters.options(
        data.loginAttempts,
        (attempt) => attempt.username,
      ),
    ),
    filters.text(
      keyName: 'logins.result',
      label: 'Resultado',
      options: filters.options(
        data.loginAttempts,
        (attempt) => attempt.success ? 'Correcto' : 'Fallido',
      ),
    ),
    filters.text(
      keyName: 'logins.reason',
      label: 'Motivo',
      options: filters.options(data.loginAttempts, (attempt) => attempt.reason),
    ),
    filters.ip('logins.ip', 'IP'),
    filters.text(
      keyName: 'logins.userAgent',
      label: 'Navegador',
      options: filters.options(
        data.loginAttempts,
        (attempt) => attempt.userAgent,
      ),
    ),
  ];

  List<Widget> get sessions => [
    filters.date('sessions.createdAt', 'Creada'),
    filters.text(
      keyName: 'sessions.username',
      label: 'Usuario',
      options: filters.options(data.sessions, (session) => session.username),
    ),
    filters.text(
      keyName: 'sessions.role',
      label: 'Rol',
      options: filters.options(data.sessions, (session) => session.role),
    ),
    filters.text(
      keyName: 'sessions.status',
      label: 'Estado',
      options: filters.options(
        data.sessions,
        (session) => session.active ? 'Activa' : 'Cerrada/expirada',
      ),
    ),
    filters.date('sessions.expiresAt', 'Expira'),
    filters.ip('sessions.ip', 'IP'),
    filters.text(
      keyName: 'sessions.userAgent',
      label: 'Navegador',
      options: filters.options(data.sessions, (session) => session.userAgent),
    ),
  ];
}

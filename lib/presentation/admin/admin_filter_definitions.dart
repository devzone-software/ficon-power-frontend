import 'package:flutter/material.dart';

import '../../application/admin_activity_controller.dart';
import 'admin_table_filters.dart';

class AdminFilterDefinitions {
  const AdminFilterDefinitions({
    required this.filters,
    required this.data,
    required this.compact,
  });

  final AdminTableFilters filters;
  final AdminActivityData data;
  final bool compact;

  List<Widget> get users => compact
      ? [
          filters.text(
            keyName: 'users.query',
            label: 'Buscar usuarios',
            hint: 'Usuario o nombre',
            options: filters.mergedOptions([
              filters.options(data.users, (user) => user.username),
              filters.options(data.users, (user) => user.displayName),
            ]),
            wideOnMobile: true,
          ),
          filters.choice(
            keyName: 'users.role',
            label: 'Rol',
            options: const ['USER', 'ADMIN', 'SUPERADMIN'],
            labels: const {
              'USER': 'Lectura',
              'ADMIN': 'Admin',
              'SUPERADMIN': 'Superadmin',
            },
          ),
          filters.choice(
            keyName: 'users.status',
            label: 'Estado',
            options: const ['Activo', 'Revocado'],
          ),
        ]
      : [
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
          filters.choice(
            keyName: 'users.role',
            label: 'Rol',
            options: const ['USER', 'ADMIN', 'SUPERADMIN'],
            labels: const {
              'USER': 'Lectura',
              'ADMIN': 'Admin',
              'SUPERADMIN': 'Superadmin',
            },
          ),
          filters.choice(
            keyName: 'users.status',
            label: 'Estado',
            options: const ['Activo', 'Revocado'],
          ),
        ];

  List<Widget> get blockedUsers => compact
      ? [
          filters.text(
            keyName: 'blocked.query',
            label: 'Buscar bloqueos',
            hint: 'Usuario, nombre, IP o responsable',
            options: filters.mergedOptions([
              filters.options(data.blockedUsers, (blocked) => blocked.username),
              filters.options(
                data.blockedUsers,
                (blocked) => blocked.displayName,
              ),
              filters.options(
                data.blockedUsers,
                (blocked) => blocked.ipAddress,
              ),
              filters.options(
                data.blockedUsers,
                (blocked) => blocked.unblockedByUsername,
              ),
            ]),
            wideOnMobile: true,
          ),
          filters.choice(
            keyName: 'blocked.status',
            label: 'Estado',
            options: const ['Bloqueado', 'Liberado/expirado'],
            labels: const {'Liberado/expirado': 'Liberado'},
          ),
          filters.date('blocked.blockedAt', 'Bloqueado'),
          filters.date('blocked.expiresAt', 'Expira'),
          filters.sort('blocked.failedAttemptsSort', 'Ordenar por fallos'),
        ]
      : [
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
          filters.sort('blocked.failedAttemptsSort', 'Ordenar por fallos'),
          filters.choice(
            keyName: 'blocked.status',
            label: 'Estado',
            options: const ['Bloqueado', 'Liberado/expirado'],
            labels: const {'Liberado/expirado': 'Liberado'},
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

  List<Widget> get auditLogs => compact
      ? [
          filters.text(
            keyName: 'audit.query',
            label: 'Buscar en auditoría',
            hint: 'Usuario, acción, entidad, IP o navegador',
            options: filters.mergedOptions([
              filters.options(data.auditLogs, (log) => log.actorUsername),
              filters.options(data.auditLogs, (log) => log.action),
              filters.options(data.auditLogs, (log) => log.entityType),
              filters.options(data.auditLogs, (log) => log.entityId),
              filters.options(data.auditLogs, (log) => log.ipAddress),
              filters.options(data.auditLogs, (log) => log.userAgent),
            ]),
            wideOnMobile: true,
          ),
          filters.date('audit.createdAt', 'Fecha', wideOnMobile: true),
        ]
      : [
          filters.date('audit.createdAt', 'Fecha'),
          filters.text(
            keyName: 'audit.actor',
            label: 'Usuario',
            options: filters.options(
              data.auditLogs,
              (log) => '${log.actorUsername ?? '—'} · ${log.actorRole ?? '—'}',
            ),
          ),
          filters.select(
            keyName: 'audit.action',
            label: 'Acción',
            options: filters.options(data.auditLogs, (log) => log.action),
          ),
          filters.select(
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

  List<Widget> get loginAttempts => compact
      ? [
          filters.text(
            keyName: 'logins.query',
            label: 'Buscar inicios de sesión',
            hint: 'Usuario, motivo, IP o navegador',
            options: filters.mergedOptions([
              filters.options(
                data.loginAttempts,
                (attempt) => attempt.username,
              ),
              filters.options(data.loginAttempts, (attempt) => attempt.reason),
              filters.options(
                data.loginAttempts,
                (attempt) => attempt.ipAddress,
              ),
              filters.options(
                data.loginAttempts,
                (attempt) => attempt.userAgent,
              ),
            ]),
            wideOnMobile: true,
          ),
          filters.choice(
            keyName: 'logins.result',
            label: 'Resultado',
            options: const ['Correcto', 'Fallido'],
          ),
          filters.date('logins.createdAt', 'Fecha', wideOnMobile: true),
        ]
      : [
          filters.date('logins.createdAt', 'Fecha'),
          filters.text(
            keyName: 'logins.username',
            label: 'Usuario',
            options: filters.options(
              data.loginAttempts,
              (attempt) => attempt.username,
            ),
          ),
          filters.choice(
            keyName: 'logins.result',
            label: 'Resultado',
            options: const ['Correcto', 'Fallido'],
          ),
          filters.select(
            keyName: 'logins.reason',
            label: 'Motivo',
            options: filters.options(
              data.loginAttempts,
              (attempt) => attempt.reason,
            ),
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

  List<Widget> get sessions => compact
      ? [
          filters.text(
            keyName: 'sessions.query',
            label: 'Buscar sesiones',
            hint: 'Usuario, rol, IP o navegador',
            options: filters.mergedOptions([
              filters.options(data.sessions, (session) => session.username),
              filters.options(data.sessions, (session) => session.role),
              filters.options(data.sessions, (session) => session.ipAddress),
              filters.options(data.sessions, (session) => session.userAgent),
            ]),
            wideOnMobile: true,
          ),
          filters.choice(
            keyName: 'sessions.role',
            label: 'Rol',
            options: const ['USER', 'ADMIN', 'SUPERADMIN'],
            labels: const {
              'USER': 'Lectura',
              'ADMIN': 'Admin',
              'SUPERADMIN': 'Superadmin',
            },
          ),
          filters.choice(
            keyName: 'sessions.status',
            label: 'Estado',
            options: const ['Activa', 'Cerrada/expirada'],
            labels: const {'Cerrada/expirada': 'Cerrada'},
          ),
          filters.date('sessions.createdAt', 'Creada'),
          filters.date('sessions.expiresAt', 'Expira'),
        ]
      : [
          filters.date('sessions.createdAt', 'Creada'),
          filters.text(
            keyName: 'sessions.username',
            label: 'Usuario',
            options: filters.options(
              data.sessions,
              (session) => session.username,
            ),
          ),
          filters.choice(
            keyName: 'sessions.role',
            label: 'Rol',
            options: const ['USER', 'ADMIN', 'SUPERADMIN'],
            labels: const {
              'USER': 'Lectura',
              'ADMIN': 'Admin',
              'SUPERADMIN': 'Superadmin',
            },
          ),
          filters.choice(
            keyName: 'sessions.status',
            label: 'Estado',
            options: const ['Activa', 'Cerrada/expirada'],
            labels: const {'Cerrada/expirada': 'Cerrada'},
          ),
          filters.date('sessions.expiresAt', 'Expira'),
          filters.ip('sessions.ip', 'IP'),
          filters.text(
            keyName: 'sessions.userAgent',
            label: 'Navegador',
            options: filters.options(
              data.sessions,
              (session) => session.userAgent,
            ),
          ),
        ];
}

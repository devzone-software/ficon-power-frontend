import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../domain/auth_user.dart';
import '../../navigation/app_routes.dart';
import '../../theme/ficon_theme.dart';

class MobileAccountPanel extends StatelessWidget {
  const MobileAccountPanel({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.onLogout,
  });

  final AuthUser user;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: FiconColors.surface,
        child: SafeArea(
          child: SizedBox(
            width: width > 420 ? 360 : width * 0.88,
            height: double.infinity,
            child: Column(
              children: [
                _AccountHeader(user: user),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _AccountSummary(user: user),
                      const SizedBox(height: 14),
                      _QuickAccess(
                        user: user,
                        onNavigate: (route) {
                          Navigator.pop(context);
                          onNavigate(route);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      Text(
                        'FICON Power Mobile · v${AppConfig.appVersionName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.pop(context);
                            onLogout();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) => Container(
    color: FiconColors.ink,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: FiconColors.cyan.withValues(alpha: 0.18),
          child: Text(
            user.username.isEmpty ? '?' : user.username[0].toUpperCase(),
            style: const TextStyle(
              color: FiconColors.cyan,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                user.username,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const _ActiveBadge(),
      ],
    ),
  );
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          title: const Text('Cuenta principal'),
          subtitle: Text('${user.displayName}\n${user.username}'),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Nivel de acceso'),
          subtitle: Text(user.role),
          trailing: Chip(label: Text(_roleLabel(user.role))),
        ),
        const Divider(height: 1),
        const ListTile(
          title: Text('Estado del sistema'),
          subtitle: Text('Operativo'),
          trailing: Icon(Icons.circle, size: 10, color: FiconColors.cyan),
        ),
      ],
    ),
  );

  String _roleLabel(String role) => switch (role) {
    'SUPERADMIN' => 'Permisos raíz',
    'ADMIN' => 'Administrador',
    _ => 'Solo lectura',
  };
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.user, required this.onNavigate});

  final AuthUser user;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Text(
              'ACCESOS RÁPIDOS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          if (user.canManageUsers)
            _AccessButton(
              icon: Icons.manage_accounts_outlined,
              label: 'Gestión de usuarios',
              onTap: () => onNavigate(AppRoutes.admin),
            ),
          if (user.canAccessAdmin)
            _AccessButton(
              icon: Icons.router_outlined,
              label: 'Gestión de medidores',
              onTap: () => onNavigate(AppRoutes.devices),
            ),
          _AccessButton(
            icon: Icons.warning_amber_outlined,
            label: 'Registro de incidentes',
            onTap: () => onNavigate(AppRoutes.incidents),
          ),
        ],
      ),
    ),
  );
}

class _AccessButton extends StatelessWidget {
  const _AccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: FiconColors.surface,
      leading: Icon(icon, color: FiconColors.logoBlue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: FiconColors.cyan.withValues(alpha: 0.12),
      border: Border.all(color: FiconColors.cyan.withValues(alpha: 0.35)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: const Text(
      'Activo',
      style: TextStyle(
        color: FiconColors.cyan,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../domain/auth_user.dart';
import '../theme/ficon_theme.dart';

/// Rutas definidas en la aplicación.
class AppRoutes {
  AppRoutes._();

  static const dashboard = '/dashboard';
  static const devices = '/dispositivos';
  static const incidents = '/incidentes';
  static const events = '/eventos';

  /// Ruta a la que se redirige cualquier ruta desconocida.
  static const fallback = dashboard;
}

/// Sección del menú de navegación del encabezado.
class NavItem {
  const NavItem({required this.route, required this.label});

  final String route;
  final String label;
}

const navItems = [
  NavItem(route: AppRoutes.dashboard, label: 'Resumen'),
  NavItem(route: AppRoutes.devices, label: 'Dispositivos'),
  NavItem(route: AppRoutes.incidents, label: 'Incidentes'),
  NavItem(route: AppRoutes.events, label: 'Eventos'),
];

/// Scaffold común con el encabezado de navegación entre rutas.
/// En pantallas anchas muestra los enlaces en la barra superior;
/// en pantallas angostas los agrupa en un menú.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    required this.currentUser,
    required this.onLogout,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final AuthUser currentUser;
  final VoidCallback onLogout;

  void _goTo(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        title: const FiconBrandMark(height: 40),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: FiconGradients.signal),
          ),
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = MediaQuery.of(context).size.width >= 720;
              if (!wide) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Secciones',
                  onSelected: (route) => _goTo(context, route),
                  itemBuilder: (context) => [
                    for (final item in navItems)
                      PopupMenuItem(
                        value: item.route,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: item.route == currentRoute
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (final item in navItems)
                    _NavButton(
                      label: item.label,
                      active: item.route == currentRoute,
                      onPressed: () => _goTo(context, item.route),
                    ),
                  _UserMenu(user: currentUser, onLogout: onLogout),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onLogout});

  final AuthUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sesión',
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user.displayName} · ${user.role}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: FiconColors.cyan.withValues(alpha: 0.18),
          child: Text(
            user.username.isEmpty ? '?' : user.username[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: active ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: active ? FiconColors.ink : Colors.white,
          backgroundColor:
              active ? FiconColors.cyan.withValues(alpha: 0.86) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

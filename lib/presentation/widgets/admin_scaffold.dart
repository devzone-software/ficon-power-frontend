import 'package:flutter/material.dart';
import '../../offline/local_console.dart';

import '../../domain/auth_user.dart';
import '../../domain/peru_phone_number.dart';
import '../../domain/realtime_change.dart';
import '../../application/ficon_repository_scope.dart';
import '../mobile/shell/mobile_navigation_shell.dart';
import '../navigation/app_routes.dart';
import '../theme/ficon_theme.dart';

export '../navigation/app_routes.dart' show AppRoutes;

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
    this.realtimeChanges,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final AuthUser currentUser;
  final VoidCallback onLogout;
  final Stream<RealtimeChange>? realtimeChanges;

  void _goTo(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 720) {
      return MobileNavigationShell(
        currentRoute: currentRoute,
        title: title,
        body: body,
        currentUser: currentUser,
        repository: FiconRepositoryScope.of(context),
        onLogout: onLogout,
        onNavigate: (route) => _goTo(context, route),
        realtimeChanges: realtimeChanges,
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        title: Tooltip(
          message: 'Ir al dashboard',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _goTo(context, AppRoutes.dashboard),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: FiconBrandMark(height: 40),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: FiconGradients.signal),
          ),
        ),
        actions: [
          if (currentUser.canEditDevices)
            IconButton(tooltip: 'Operaciones', onPressed: () => LocalConsole.open(context), icon: const Icon(Icons.electrical_services)),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = MediaQuery.of(context).size.width >= 720;
              final visibleItems = navItems
                  .where(
                    (item) => !item.adminOnly || currentUser.canAccessAdmin,
                  )
                  .toList();
              if (!wide) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UserMenu(user: currentUser, onLogout: onLogout),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Secciones',
                      onSelected: (route) => _goTo(context, route),
                      itemBuilder: (context) => [
                        for (final item in visibleItems)
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
                    ),
                    const SizedBox(width: 4),
                  ],
                );
              }
              return Row(
                children: [
                  for (final item in visibleItems)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(_contact(user.email, 'Correo no registrado')),
              Text(
                user.whatsappPhone?.trim().isNotEmpty == true
                    ? formatPeruMobilePhone(user.whatsappPhone!)
                    : 'WhatsApp no registrado',
              ),
            ],
          ),
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

  String _contact(String? value, String fallback) {
    final normalized = value?.trim();
    return normalized?.isNotEmpty == true ? normalized! : fallback;
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
          backgroundColor: active
              ? FiconColors.cyan.withValues(alpha: 0.86)
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

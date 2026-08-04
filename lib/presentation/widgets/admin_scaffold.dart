import 'package:flutter/material.dart';

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
  });

  final String currentRoute;
  final String title;
  final Widget body;

  void _goTo(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FICON Power'),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: active ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              active ? colorScheme.primary : colorScheme.onSurfaceVariant,
          backgroundColor:
              active ? colorScheme.primary.withValues(alpha: 0.10) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
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

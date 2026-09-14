class AppRoutes {
  AppRoutes._();

  static const dashboard = '/dashboard';
  static const login = '/login';
  static const devices = '/dispositivos';
  static const incidents = '/incidentes';
  static const calendar = '/calendario';
  static const events = '/eventos';
  static const admin = '/admin';
  static const fallback = dashboard;
}

class NavItem {
  const NavItem({
    required this.route,
    required this.label,
    this.adminOnly = false,
  });

  final String route;
  final String label;
  final bool adminOnly;
}

const navItems = [
  NavItem(route: AppRoutes.dashboard, label: 'Resumen'),
  NavItem(route: AppRoutes.devices, label: 'Dispositivos'),
  NavItem(route: AppRoutes.incidents, label: 'Incidentes'),
  NavItem(route: AppRoutes.calendar, label: 'Calendario'),
  NavItem(route: AppRoutes.events, label: 'Eventos'),
  NavItem(route: AppRoutes.admin, label: 'Admin', adminOnly: true),
];

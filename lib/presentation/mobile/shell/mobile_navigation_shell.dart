import 'package:flutter/material.dart';

import '../../../adapters/http/ficon_monitoring_repository.dart';
import '../../../application/mobile_notification_controller.dart';
import '../../../domain/auth_user.dart';
import '../../../domain/mobile_notification.dart';
import '../overlays/mobile_account_panel.dart';
import '../../theme/ficon_theme.dart';
import '../../navigation/app_routes.dart';

class MobileNavigationShell extends StatefulWidget {
  const MobileNavigationShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    required this.currentUser,
    required this.repository,
    required this.onLogout,
    required this.onNavigate,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final AuthUser currentUser;
  final FiconMonitoringRepository repository;
  final VoidCallback onLogout;
  final ValueChanged<String> onNavigate;

  @override
  State<MobileNavigationShell> createState() => _MobileNavigationShellState();
}

class _MobileNavigationShellState extends State<MobileNavigationShell>
    with WidgetsBindingObserver {
  late final MobileNotificationController _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = MobileNotificationController(
      widget.repository.fetchMobileNotifications,
      widget.repository.markMobileNotificationRead,
      widget.repository.markAllMobileNotificationsRead,
    )..refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _notifications.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryItems = navItems
        .where((item) => !item.adminOnly || widget.currentUser.canAccessAdmin)
        .toList();
    final selected = primaryItems.indexWhere(
      (item) => item.route == widget.currentRoute,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        titleSpacing: 14,
        title: InkWell(
          onTap: () => widget.onNavigate(AppRoutes.dashboard),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FiconBrandMark(height: 34),
              const SizedBox(width: 10),
              Flexible(
                child: Text(widget.title, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _notifications,
            builder: (context, _) => Badge(
              isLabelVisible: _notifications.unreadCount > 0,
              label: Text('${_notifications.unreadCount}'),
              child: IconButton(
                tooltip: 'Notificaciones',
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openAccountPanel,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: FiconColors.cyan.withValues(alpha: 0.18),
                child: Text(
                  widget.currentUser.username.isEmpty
                      ? '?'
                      : widget.currentUser.username[0].toUpperCase(),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: FiconGradients.signal),
          ),
        ),
      ),
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) =>
            widget.onNavigate(primaryItems[index].route),
        destinations: [
          for (final item in primaryItems)
            NavigationDestination(
              icon: Icon(_navigationIcon(item.route)),
              label: item.label,
            ),
        ],
      ),
    );
  }

  IconData _navigationIcon(String route) => switch (route) {
    AppRoutes.dashboard => Icons.dashboard_outlined,
    AppRoutes.devices => Icons.router_outlined,
    AppRoutes.incidents => Icons.warning_amber_outlined,
    AppRoutes.events => Icons.event_note_outlined,
    AppRoutes.admin => Icons.admin_panel_settings_outlined,
    _ => Icons.circle_outlined,
  };

  Future<void> _openAccountPanel() => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar panel de cuenta',
    barrierColor: FiconColors.ink.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => MobileAccountPanel(
      user: widget.currentUser,
      onNavigate: widget.onNavigate,
      onLogout: widget.onLogout,
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );

  Future<void> _openNotifications() async {
    await _notifications.refresh();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AnimatedBuilder(
        animation: _notifications,
        builder: (context, _) =>
            _NotificationHistorySheet(controller: _notifications),
      ),
    );
  }
}

class _NotificationHistorySheet extends StatelessWidget {
  const _NotificationHistorySheet({required this.controller});

  final MobileNotificationController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Notificaciones',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${controller.unreadCount} sin leer'),
              trailing: TextButton(
                onPressed: controller.unreadCount == 0
                    ? null
                    : controller.readAll,
                child: const Text('Leer todas'),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _history()),
          ],
        ),
      ),
    );
  }

  Widget _history() {
    if (controller.loading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.items.isEmpty) {
      return Center(child: Text('No se pudo cargar el historial.'));
    }
    if (controller.items.isEmpty) {
      return const Center(child: Text('No hay notificaciones registradas.'));
    }
    return ListView.separated(
      itemCount: controller.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = controller.items[index];
        return _NotificationTile(
          notification: item,
          onTap: item.unread ? () => controller.read(item.id) : null,
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final MobileNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        notification.eventType == 'power_outage'
            ? Icons.power_off_outlined
            : Icons.power_outlined,
        color: notification.unread ? FiconColors.cyan : FiconColors.deepAlt,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.unread ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      subtitle: Text(notification.body),
      trailing: notification.unread
          ? const Icon(Icons.circle, size: 9, color: FiconColors.cyan)
          : null,
    );
  }
}

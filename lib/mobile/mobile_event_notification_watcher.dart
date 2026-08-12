import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../config/auth_session.dart';
import '../domain/event.dart';

/// Observa eventos nuevos desde el backend y los muestra como notificaciones
/// locales en la app móvil beta.
///
/// Esta es una solución beta basada en polling. Funciona cuando la app está
/// abierta o viva en memoria. Para recibir alertas con la app cerrada/matada se
/// debe agregar push notifications con FCM desde el backend.
class MobileEventNotificationWatcher extends StatefulWidget {
  const MobileEventNotificationWatcher({
    super.key,
    required this.session,
    required this.repository,
    required this.child,
    this.pollInterval = const Duration(seconds: 20),
  });

  final AuthSession session;
  final FiconMonitoringRepository repository;
  final Widget child;
  final Duration pollInterval;

  @override
  State<MobileEventNotificationWatcher> createState() =>
      _MobileEventNotificationWatcherState();
}

class _MobileEventNotificationWatcherState
    extends State<MobileEventNotificationWatcher> {
  static const _channelId = 'ficon_power_events';
  static const _channelName = 'Eventos FICON Power';
  static const _channelDescription =
      'Alertas locales cuando se detectan eventos nuevos.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  String? _lastSeenEventId;
  bool _initializing = false;
  bool _notificationsReady = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleSessionChange);
    unawaited(_initializeNotifications());
    _handleSessionChange();
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    if (_initializing || _notificationsReady) return;
    _initializing = true;
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _notifications.initialize(settings: initializationSettings);

      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();

      _notificationsReady = true;
    } finally {
      _initializing = false;
    }
  }

  void _handleSessionChange() {
    if (!mounted) return;
    if (widget.session.isAuthenticated) {
      _timer ??= Timer.periodic(widget.pollInterval, (_) => _pollEvents());
      unawaited(_primeLatestEvent());
    } else {
      _timer?.cancel();
      _timer = null;
      _lastSeenEventId = null;
    }
  }

  Future<void> _primeLatestEvent() async {
    if (_lastSeenEventId != null || _polling) return;
    _polling = true;
    try {
      final events = await widget.repository.fetchEvents(limit: 1);
      if (events.isNotEmpty) {
        _lastSeenEventId = events.first.id;
      }
    } catch (_) {
      // La UI principal ya maneja errores visibles de API.
    } finally {
      _polling = false;
    }
  }

  Future<void> _pollEvents() async {
    if (!widget.session.isAuthenticated || _polling) return;
    _polling = true;
    try {
      final events = await widget.repository.fetchEvents(limit: 10);
      if (events.isEmpty) return;

      final lastSeen = _lastSeenEventId;
      if (lastSeen == null) {
        _lastSeenEventId = events.first.id;
        return;
      }

      final newEvents = <Event>[];
      for (final event in events) {
        if (event.id == lastSeen) break;
        newEvents.add(event);
      }

      if (newEvents.isEmpty) return;

      _lastSeenEventId = events.first.id;
      await _initializeNotifications();

      for (final event in newEvents.reversed) {
        await _showEventNotification(event);
      }
    } catch (_) {
      // No bloquea la app si el polling falla temporalmente.
    } finally {
      _polling = false;
    }
  }

  Future<void> _showEventNotification(Event event) async {
    if (!_notificationsReady) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.status,
      ),
    );

    await _notifications.show(
      id: event.id.hashCode & 0x7fffffff,
      title: _titleFor(event),
      body: _bodyFor(event),
      notificationDetails: details,
      payload: event.id,
    );
  }

  String _titleFor(Event event) {
    return switch (event.eventType) {
      'deviceOffline' => 'Corte detectado',
      'deviceOnline' => 'Retorno detectado',
      _ => 'Nuevo evento FICON Power',
    };
  }

  String _bodyFor(Event event) {
    final device = event.deviceName?.trim().isNotEmpty == true
        ? event.deviceName!.trim()
        : 'Dispositivo';
    final site = event.siteName?.trim().isNotEmpty == true
        ? ' · ${event.siteName!.trim()}'
        : '';
    return '$device$site';
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

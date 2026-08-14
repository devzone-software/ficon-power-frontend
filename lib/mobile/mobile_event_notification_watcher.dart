import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../config/auth_session.dart';
import '../domain/event.dart';
import 'mobile_event_detector.dart';

/// Observa eventos nuevos desde el backend y los muestra como notificaciones
/// locales en la app móvil.
///
/// Esta es una solución inicial basada en polling. Funciona cuando la app está
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
  final MobileEventDetector _eventDetector = MobileEventDetector();

  Timer? _timer;
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
      _eventDetector.reset();
    }
  }

  Future<void> _primeLatestEvent() async {
    if (_eventDetector.isPrimed || _polling) return;
    _polling = true;
    try {
      final events = await widget.repository.fetchEvents(limit: 1);
      _eventDetector.prime(events);
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

      final newEvents = _eventDetector.detect(events);
      if (newEvents.isEmpty) return;
      await _initializeNotifications();

      for (final event in newEvents) {
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

    final content = EventNotificationContent.fromEvent(event);
    await _notifications.show(
      id: event.id.hashCode & 0x7fffffff,
      title: content.title,
      body: content.body,
      notificationDetails: details,
      payload: event.id,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

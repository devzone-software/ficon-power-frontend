import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../../config/auth_session.dart';
import '../../presentation/navigation/app_routes.dart';

class MobileNotificationDestination {
  const MobileNotificationDestination._({
    required this.route,
    this.incidentId,
    this.deviceId,
  });

  final String route;
  final String? incidentId;
  final String? deviceId;

  static MobileNotificationDestination? fromData(Map<String, dynamic> data) {
    final incidentId = _value(data, 'incidentId', 'incident_id');
    if (incidentId != null) {
      return MobileNotificationDestination._(
        route: AppRoutes.incidents,
        incidentId: incidentId,
      );
    }
    final deviceId = _value(data, 'deviceId', 'device_id');
    if (deviceId != null) {
      return MobileNotificationDestination._(
        route: AppRoutes.devices,
        deviceId: deviceId,
      );
    }
    return null;
  }

  static MobileNotificationDestination? fromLocalPayload(String payload) {
    final value = payload.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('device:')) {
      return fromData({'deviceId': value.substring('device:'.length)});
    }
    if (value.startsWith('incident:')) {
      return fromData({'incidentId': value.substring('incident:'.length)});
    }
    // Las versiones anteriores guardaban directamente el UUID del incidente.
    return fromData({'incidentId': value});
  }

  static String? _value(Map<String, dynamic> data, String key, String alias) {
    final value = (data[key] ?? data[alias])?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class MobileNotificationNavigation extends StatefulWidget {
  const MobileNotificationNavigation({
    super.key,
    required this.navigatorKey,
    required this.session,
    required this.child,
    this.openedMessages,
    this.initialMessage,
    this.localPayloads,
    this.initialLocalPayload,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final AuthSession session;
  final Widget child;
  final Stream<RemoteMessage>? openedMessages;
  final Future<RemoteMessage?> Function()? initialMessage;
  final Stream<String>? localPayloads;
  final Future<String?> Function()? initialLocalPayload;

  @override
  State<MobileNotificationNavigation> createState() =>
      _MobileNotificationNavigationState();
}

class _MobileNotificationNavigationState
    extends State<MobileNotificationNavigation> {
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _localSubscription;
  MobileNotificationDestination? _pending;
  final Set<String> _handledMessages = {};
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _openedSubscription =
        (widget.openedMessages ?? FirebaseMessaging.onMessageOpenedApp).listen(
          _handleMessage,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('FCM notification-open stream failed: $error');
          },
        );
    _localSubscription = widget.localPayloads?.listen(_handleLocalPayload);
    unawaited(_loadInitialMessage());
    unawaited(_loadInitialLocalPayload());
  }

  Future<void> _loadInitialLocalPayload() async {
    try {
      final payload = await widget.initialLocalPayload?.call();
      if (payload != null) _handleLocalPayload(payload);
    } catch (error, stackTrace) {
      debugPrint('Local initial notification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _loadInitialMessage() async {
    try {
      final message =
          await (widget.initialMessage?.call() ??
              FirebaseMessaging.instance.getInitialMessage());
      if (message != null) _handleMessage(message);
    } catch (error, stackTrace) {
      debugPrint('FCM initial notification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleMessage(RemoteMessage message) {
    final destination = MobileNotificationDestination.fromData(message.data);
    if (destination == null) return;
    final identity = message.messageId?.trim();
    if (identity != null &&
        identity.isNotEmpty &&
        !_handledMessages.add(identity)) {
      return;
    }
    _queue(destination);
  }

  void _handleLocalPayload(String payload) {
    final destination = MobileNotificationDestination.fromLocalPayload(payload);
    if (destination != null) _queue(destination);
  }

  void _queue(MobileNotificationDestination destination) {
    _pending = destination;
    _scheduleNavigation();
  }

  void _onSessionChanged() => _scheduleNavigation();

  void _scheduleNavigation() {
    if (!widget.session.isAuthenticated ||
        _pending == null ||
        _navigationScheduled) {
      return;
    }
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      if (!mounted || !widget.session.isAuthenticated || _pending == null) {
        return;
      }
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) {
        Future<void>.delayed(
          const Duration(milliseconds: 100),
          _scheduleNavigation,
        );
        return;
      }
      final destination = _pending!;
      _pending = null;
      unawaited(navigator.pushNamed(destination.route, arguments: destination));
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    unawaited(_openedSubscription?.cancel());
    unawaited(_localSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

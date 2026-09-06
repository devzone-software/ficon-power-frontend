import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'mobile_power_alert_channel.dart';

class MobileForegroundNotificationContent {
  const MobileForegroundNotificationContent({
    required this.notificationId,
    required this.title,
    required this.body,
    this.payload,
  });

  final int notificationId;
  final String title;
  final String body;
  final String? payload;

  factory MobileForegroundNotificationContent.fromMessage(
    RemoteMessage message,
  ) {
    final eventType = message.data['eventType']?.trim() ?? '';
    final incidentId = message.data['incidentId']?.trim();
    final deviceName = message.data['deviceName']?.trim();
    final title = _firstNonBlank([
      message.notification?.title,
      message.data['title'],
      switch (eventType) {
        'power_outage' => 'Corte de energía detectado',
        'power_restored' => 'Suministro eléctrico restablecido',
        _ => 'Alerta FICON Power',
      },
    ]);
    final body = _firstNonBlank([
      message.notification?.body,
      message.data['body'],
      deviceName,
      'Se recibió una nueva alerta.',
    ]);
    final identity = _firstNonBlank([
      message.messageId,
      if (incidentId != null && incidentId.isNotEmpty) '$eventType:$incidentId',
      '$title:$body',
    ]);

    return MobileForegroundNotificationContent(
      notificationId: identity.hashCode & 0x7fffffff,
      title: title,
      body: body,
      payload: incidentId?.isEmpty == false ? incidentId : null,
    );
  }

  static String _firstNonBlank(Iterable<String?> values) {
    return values
        .map((value) => value?.trim())
        .firstWhere((value) => value?.isNotEmpty == true)!;
  }
}

class MobileForegroundNotificationListener extends StatefulWidget {
  const MobileForegroundNotificationListener({
    super.key,
    required this.channel,
    required this.child,
    this.messages,
  });

  final MobilePowerAlertChannel channel;
  final Widget child;
  final Stream<RemoteMessage>? messages;

  @override
  State<MobileForegroundNotificationListener> createState() =>
      _MobileForegroundNotificationListenerState();
}

class _MobileForegroundNotificationListenerState
    extends State<MobileForegroundNotificationListener> {
  StreamSubscription<RemoteMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = (widget.messages ?? FirebaseMessaging.onMessage).listen(
      _showNotification,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM foreground stream failed: $error');
      },
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final content = MobileForegroundNotificationContent.fromMessage(message);
    try {
      await widget.channel.show(
        notificationId: content.notificationId,
        title: content.title,
        body: content.body,
        payload: content.payload,
      );
    } catch (error, stackTrace) {
      debugPrint('FCM foreground notification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

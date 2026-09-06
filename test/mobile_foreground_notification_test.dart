import 'dart:async';

import 'package:ficon_power_frontend/mobile/notifications/mobile_foreground_notification_listener.dart';
import 'package:ficon_power_frontend/mobile/notifications/mobile_power_alert_channel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa el título y cuerpo enviados por FCM', () {
    final content = MobileForegroundNotificationContent.fromMessage(
      const RemoteMessage(
        messageId: 'message-1',
        data: {
          'eventType': 'power_outage',
          'incidentId': 'incident-1',
          'deviceName': 'Medidor Puno',
        },
        notification: RemoteNotification(
          title: 'Corte detectado',
          body: 'Medidor Puno sin energía',
        ),
      ),
    );

    expect(content.title, 'Corte detectado');
    expect(content.body, 'Medidor Puno sin energía');
    expect(content.payload, 'incident-1');
    expect(content.notificationId, 'message-1'.hashCode & 0x7fffffff);
  });

  test('construye contenido legible para un mensaje solo de datos', () {
    final content = MobileForegroundNotificationContent.fromMessage(
      const RemoteMessage(
        data: {
          'eventType': 'power_restored',
          'incidentId': 'incident-2',
          'deviceName': ' Medidor Juliaca ',
        },
      ),
    );

    expect(content.title, 'Suministro eléctrico restablecido');
    expect(content.body, 'Medidor Juliaca');
    expect(content.payload, 'incident-2');
  });

  testWidgets('muestra localmente los mensajes recibidos en primer plano', (
    tester,
  ) async {
    final messages = StreamController<RemoteMessage>();
    final channel = _RecordingPowerAlertChannel();
    await tester.pumpWidget(
      MobileForegroundNotificationListener(
        channel: channel,
        messages: messages.stream,
        child: const SizedBox(),
      ),
    );

    messages.add(
      const RemoteMessage(
        messageId: 'foreground-message',
        notification: RemoteNotification(
          title: 'Corte detectado',
          body: 'Medidor Puno',
        ),
      ),
    );
    await tester.pump();

    expect(channel.titles, ['Corte detectado']);
    expect(channel.bodies, ['Medidor Puno']);

    await messages.close();
  });
}

class _RecordingPowerAlertChannel extends MobilePowerAlertChannel {
  final List<String> titles = [];
  final List<String> bodies = [];

  @override
  Future<void> show({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    titles.add(title);
    bodies.add(body);
  }
}

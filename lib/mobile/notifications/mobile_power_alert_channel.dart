import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MobilePowerAlertChannel {
  MobilePowerAlertChannel({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  // Canal de respaldo utilizado por Firebase cuando el mensaje no puede
  // resolverse contra otro channel_id. Se configura explícitamente para que
  // las alarmas no terminen en un canal Misc silencioso.
  static const id = 'fcm_fallback_notification_channel';
  static const name = 'Misc';
  static const description =
      'Alertas sonoras para cortes de energia pendientes de revision.';
  static final _vibrationPattern = Int64List.fromList([0, 1000, 300, 1000]);

  final FlutterLocalNotificationsPlugin _notifications;

  Future<void> ensureCreated() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings: settings);
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.deleteNotificationChannel(
      channelId: 'ficon_power_power_alerts_alarm',
    );
    await android?.deleteNotificationChannel(
      channelId: 'ficon_power_power_alerts_alarm_v2',
    );
    await android?.deleteNotificationChannel(
      channelId: 'ficon_power_power_alerts_alarm_v3',
    );
    await android?.deleteNotificationChannel(
      channelId: 'ficon_power_power_alerts_alarm_v4',
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        id,
        name,
        description: description,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('power_alarm'),
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MobilePowerAlertChannel {
  MobilePowerAlertChannel({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const id = 'ficon_power_power_alerts_alarm_v3';
  static const name = 'Cortes de energia';
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
    await android?.deleteNotificationChannel('ficon_power_power_alerts_alarm');
    await android?.deleteNotificationChannel(
      'ficon_power_power_alerts_alarm_v2',
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
      ),
    );
  }
}

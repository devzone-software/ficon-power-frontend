import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MobilePowerAlertChannel {
  MobilePowerAlertChannel({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const id = 'ficon_power_power_alerts_alarm_v2';
  static const name = 'Cortes de energia';
  static const description =
      'Alertas sonoras para cortes de energia pendientes de revision.';

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
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        id,
        name,
        description: description,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('power_alarm'),
        enableVibration: true,
      ),
    );
  }
}

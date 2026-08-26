import 'package:ficon_power_frontend/application/mobile_notification_controller.dart';
import 'package:ficon_power_frontend/domain/mobile_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MobileNotification notification(String id, {required bool unread}) {
    return MobileNotification(
      id: id,
      title: 'Corte de energía',
      body: 'Medidor sin conexión',
      data: const {'deviceName': 'Medidor'},
      eventType: 'power_outage',
      status: unread ? 'SENT' : 'READ',
      createdAt: DateTime.utc(2026, 8, 24),
      readAt: unread ? null : DateTime.utc(2026, 8, 24, 1),
      unread: unread,
    );
  }

  test('carga el historial y calcula notificaciones no leídas', () async {
    final controller = MobileNotificationController(
      () async => [
        notification('one', unread: true),
        notification('two', unread: false),
      ],
      (_) async {},
      () async {},
    );

    await controller.refresh();

    expect(controller.items, hasLength(2));
    expect(controller.unreadCount, 1);
    expect(controller.error, isNull);
  });

  test('marca una notificación y conserva el resto del historial', () async {
    var markedId = '';
    final controller = MobileNotificationController(
      () async => [
        notification('one', unread: true),
        notification('two', unread: true),
      ],
      (id) async => markedId = id,
      () async {},
    );
    await controller.refresh();

    await controller.read('one');

    expect(markedId, 'one');
    expect(controller.unreadCount, 1);
    expect(
      controller.items.singleWhere((item) => item.id == 'one').unread,
      isFalse,
    );
  });
}

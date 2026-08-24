import 'package:ficon_power_frontend/domain/event.dart';
import 'package:ficon_power_frontend/mobile/notifications/mobile_event_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event event(String id, String type, {String? device, String? site}) => Event(
    id: id,
    eventType: type,
    deviceName: device,
    siteName: site,
    deliveryLatencyMillis: 0,
  );

  test('inicializa sin notificar eventos históricos', () {
    final detector = MobileEventDetector();

    expect(detector.detect([event('2', 'deviceOnline')]), isEmpty);
    expect(detector.isPrimed, isTrue);
  });

  test('devuelve eventos nuevos en orden cronológico', () {
    final detector = MobileEventDetector()..prime([event('1', 'deviceOnline')]);

    final detected = detector.detect([
      event('3', 'deviceOffline'),
      event('2', 'deviceOnline'),
      event('1', 'deviceOnline'),
    ]);

    expect(detected.map((item) => item.id), ['2', '3']);
    expect(detector.detect([event('3', 'deviceOffline')]), isEmpty);
  });

  test('construye título y cuerpo para corte y retorno', () {
    final outage = EventNotificationContent.fromEvent(
      event('1', 'deviceOffline', device: ' Medidor ', site: ' Lima '),
    );
    final restored = EventNotificationContent.fromEvent(
      event('2', 'deviceOnline'),
    );

    expect(outage.title, 'Corte detectado');
    expect(outage.body, 'Medidor · Lima');
    expect(restored.title, 'Retorno detectado');
    expect(restored.body, 'Dispositivo');
  });
}

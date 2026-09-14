import 'package:ficon_power_frontend/domain/whatsapp_recipient.dart';
import 'package:ficon_power_frontend/domain/peru_phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta destinatarios globales y sus preferencias', () {
    final recipient = WhatsAppRecipient.fromJson({
      'id': 'recipient-1',
      'label': 'Operaciones',
      'phone': '51987654321',
      'siteId': null,
      'siteName': null,
      'notifyOutage': true,
      'notifyRestored': false,
      'active': true,
      'lastTestStatus': 'SENT',
      'lastTestMessage': 'Aceptado',
      'lastTestAt': '2026-09-11T12:30:00Z',
    });

    expect(recipient.global, isTrue);
    expect(recipient.notifyOutage, isTrue);
    expect(recipient.notifyRestored, isFalse);
    expect(recipient.lastTestAt, DateTime.parse('2026-09-11T12:30:00Z'));
  });

  test('interpreta el resultado del mensaje de prueba', () {
    final result = WhatsAppTestResult.fromJson({
      'configured': true,
      'accepted': true,
      'message': 'Mensaje de prueba aceptado por Meta.',
    });

    expect(result.configured, isTrue);
    expect(result.accepted, isTrue);
    expect(result.message, contains('aceptado'));
  });

  test('normaliza cualquier presentación de un celular peruano', () {
    expect(normalizePeruMobilePhone('987654321'), '51987654321');
    expect(normalizePeruMobilePhone('987 654 321'), '51987654321');
    expect(normalizePeruMobilePhone('+51 987-654-321'), '51987654321');
    expect(normalizePeruMobilePhone('51987654321'), '51987654321');
    expect(formatPeruMobilePhone('51987654321'), '+51 987 654 321');
  });

  test('rechaza números que no sean celulares peruanos', () {
    expect(normalizePeruMobilePhone('+1 202 555 0123'), isNull);
    expect(normalizePeruMobilePhone('123456'), isNull);
  });
}

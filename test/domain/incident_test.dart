import 'package:ficon_power_frontend/domain/incident.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only active incidents are awaiting attention', () {
    const active = Incident(id: 'active', status: 'active');
    const acknowledged = Incident(id: 'ack', status: 'acknowledged');
    const resolved = Incident(id: 'resolved', status: 'resolved');

    expect(active.isAwaitingAttention, isTrue);
    expect(acknowledged.isAwaitingAttention, isFalse);
    expect(resolved.isAwaitingAttention, isFalse);
  });

  test('acknowledged incidents remain open until power is restored', () {
    const acknowledged = Incident(id: 'ack', status: 'acknowledged');

    expect(acknowledged.isOpen, isTrue);
  });
}

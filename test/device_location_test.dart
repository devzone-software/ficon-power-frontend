import 'package:ficon_power_frontend/domain/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta coordenadas y limita el mapa a Puno', () {
    final device = Device.fromJson({
      'id': 'device-1',
      'name': 'Medidor Puno',
      'active': true,
      'status': 'offline',
      'district': '  PUNO ',
      'latitude': -15.840222,
      'longitude': -70.021881,
      'currentIncidentStartedAt': '2026-09-13T10:00:00-05:00',
    });

    expect(device.isInPuno, isTrue);
    expect(device.hasLocation, isTrue);
    expect(device.hasActiveIncident, isTrue);
    expect(device.latitude, -15.840222);
    expect(device.longitude, -70.021881);
  });

  test('no inventa ubicación para dispositivos sin coordenadas', () {
    final device = Device.fromJson({
      'id': 'device-2',
      'name': 'Sin ubicación',
      'active': true,
      'status': 'online',
      'district': 'Puno',
    });

    expect(device.isInPuno, isTrue);
    expect(device.hasLocation, isFalse);
  });
}

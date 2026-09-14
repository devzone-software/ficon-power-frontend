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

  test('usa el centro de Puno si faltan coordenadas de la sede', () {
    final device = Device.fromJson({
      'id': 'device-2',
      'name': 'Sin ubicación',
      'active': true,
      'status': 'online',
      'district': 'Puno',
    });

    expect(device.isInPuno, isTrue);
    expect(device.hasLocation, isFalse);
    expect(device.punoMapLocation?.latitude, -15.8433);
    expect(device.punoMapLocation?.longitude, -70.0236);
  });

  test('ubica Putina y Lampa dentro de la región Puno', () {
    final putina = Device.fromJson({
      'id': 'device-putina',
      'name': 'Medidor Putina',
      'active': true,
      'status': 'online',
      'siteName': 'Timax - Putina',
      'district': 'Putina',
    });
    final lampa = Device.fromJson({
      'id': 'device-lampa',
      'name': 'Medidor Lampa',
      'active': true,
      'status': 'online',
      'district': 'Lampa',
    });

    expect(putina.isInPuno, isTrue);
    expect(putina.punoMapLocation?.latitude, -14.9141);
    expect(lampa.isInPuno, isTrue);
    expect(lampa.punoMapLocation?.longitude, -70.36662);
  });

  test('excluye coordenadas que pertenecen a otra región', () {
    final device = Device.fromJson({
      'id': 'device-cusco',
      'name': 'Medidor Cusco',
      'active': true,
      'status': 'online',
      'siteName': 'Cusco',
      'district': 'Cusco',
      'department': 'Cusco',
      'latitude': -13.53195,
      'longitude': -71.96746,
    });

    expect(device.hasLocation, isTrue);
    expect(device.isInPuno, isFalse);
  });
}

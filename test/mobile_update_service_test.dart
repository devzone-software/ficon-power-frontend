import 'package:ficon_power_frontend/mobile/updates/mobile_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('resuelve URL configurada o derivada de la API', () {
    expect(
      MobileUpdateService.resolveManifestUri(
        configuredUrl: ' https://updates.example/version.json ',
        apiBaseUrl: 'https://api.example/',
      ).toString(),
      'https://updates.example/version.json',
    );
    expect(
      MobileUpdateService.resolveManifestUri(
        configuredUrl: '',
        apiBaseUrl: 'https://api.example/',
      ).toString(),
      'https://api.example/mobile/version.json',
    );
  });

  test('devuelve únicamente una versión superior a la instalada', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"versionCode":4,"versionName":"0.1.4",'
        '"apkUrl":"https://example/app.apk","notes":"Fix",'
        '"required":false}',
        200,
      ),
    );
    final service = MobileUpdateService(
      manifestUri: Uri.parse('https://example/version.json'),
      installedVersionCode: 3,
      client: client,
    );

    final update = await service.findAvailableUpdate();

    expect(update?.versionCode, 4);
    expect(update?.versionName, '0.1.4');
    expect(update?.apkUri.toString(), 'https://example/app.apk');
  });

  test('ignora versión ya instalada y respuestas no exitosas', () async {
    final current = MobileUpdateService(
      manifestUri: Uri.parse('https://example/version.json'),
      installedVersionCode: 4,
      client: MockClient(
        (_) async => http.Response(
          '{"versionCode":4,"apkUrl":"https://example/app.apk"}',
          200,
        ),
      ),
    );
    final unavailable = MobileUpdateService(
      manifestUri: Uri.parse('https://example/version.json'),
      installedVersionCode: 1,
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(await current.findAvailableUpdate(), isNull);
    expect(await unavailable.findAvailableUpdate(), isNull);
  });

  test('expone la versión publicada aunque no sea una actualización', () async {
    final service = MobileUpdateService(
      manifestUri: Uri.parse('https://example/version.json'),
      installedVersionCode: 10,
      client: MockClient(
        (_) async => http.Response(
          '{"versionCode":10,"versionName":"0.1.5",'
          '"architecture":"arm64-v8a",'
          '"apkUrl":"https://example/app.apk","required":false}',
          200,
        ),
      ),
    );

    final manifest = await service.fetchManifest();

    expect(manifest?.versionName, '0.1.5');
    expect(manifest?.versionCode, 10);
    expect(manifest?.architecture, 'arm64-v8a');
    expect(await service.findAvailableUpdate(), isNull);
  });
}

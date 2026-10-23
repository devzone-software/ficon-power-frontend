import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ficon_power_frontend/offline/local_engine.dart';
import 'package:ficon_power_frontend/adapters/http/ficon_monitoring_repository.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';

void main() {
  late Directory directory;
  late LocalEngine engine;
  late AuthSession session;
  late FiconMonitoringRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ficon-local-test-');
    engine = await LocalEngine.open(directory.path);
    session = AuthSession();
    repository = FiconMonitoringRepository(
      client: LocalClient(engine),
      baseUrl: 'http://local.ficon',
      session: session,
    );
    final login = await repository.login(
      username: 'superadmin',
      password: 'FiconLocal2026!',
    );
    session.start(token: login.token, user: login.user);
  });
  tearDown(() async {
    repository.dispose();
    await engine.changes.close();
    await directory.delete(recursive: true);
  });
  Future<dynamic> call(String path, [Map<String, dynamic> body = const {}]) =>
      engine.request(
        'POST',
        Uri.parse('http://local.ficon$path'),
        body,
        session.token!,
      );

  test(
    'power loss is idempotent, persists and restoration closes incident',
    () async {
      expect(await repository.fetchDevices(), hasLength(4));
      final before = await repository.fetchDeviceDetail('d-0');
      await call('/api/local/devices/d-0/power', {'online': false});
      await call('/api/local/devices/d-0/power', {'online': false});
      final detail = await repository.fetchDeviceDetail('d-0');
      expect(detail.device.isOnline, isFalse);
      expect(detail.recentIncidents.length, before.recentIncidents.length + 1);
      expect(detail.recentEvents.length, before.recentEvents.length + 1);
      final incident = detail.recentIncidents.first;
      await repository.acknowledgeIncident(incident.id);
      final reopened = await LocalEngine.open(directory.path);
      expect(reopened.rows('devices').first['status'], 'offline');
      await reopened.changes.close();
      await call('/api/local/devices/d-0/power', {'online': true});
      final restored = await repository.fetchDeviceDetail('d-0');
      expect(restored.device.isOnline, isTrue);
      expect(restored.recentIncidents.first.status, 'resolved');
      expect(restored.recentIncidents.first.endTime, isNotNull);
      expect(await repository.fetchMobileUnreadNotificationCount(), 2);
      await repository.markAllMobileNotificationsRead();
      expect(await repository.fetchMobileUnreadNotificationCount(), 0);
    },
  );
  test('paging filters and detail use the same history', () async {
    final page = await repository.fetchIncidentsPage(
      deviceName: 'Timax - Juliaca',
      size: 2,
    );
    expect(page.items, hasLength(2));
    expect(page.totalItems, 6);
    expect(page.hasNext, true);
    expect(
      (await repository.fetchDeviceDetail('d-1')).metrics.incidentsLast30Days,
      6,
    );
  });
  test(
    'user WhatsApp configuration projects into recipients and deliveries are simulated',
    () async {
      final user = await repository.createUser(
        username: 'nuevo',
        password: 'NuevaClave123!',
        role: 'USER',
        displayName: 'Nuevo',
        whatsappPhone: '+51 999 888 777',
        whatsappEnabled: true,
      );
      final recipients = await repository.fetchWhatsAppRecipients();
      expect(recipients.single.userId, user.id);
      expect(recipients.single.phone, '+51999888777');
      final result = await repository.testUserWhatsApp(user.id);
      expect(result.accepted, true);
      expect(
        (await repository.fetchUserWhatsAppDeliveries(user.id)).single.status,
        'SIMULATED',
      );
      await repository.updateUser(
        user.id,
        role: 'USER',
        displayName: 'Nuevo',
        active: true,
        whatsappEnabled: false,
        whatsappPhone: '999888777',
      );
      expect((await repository.fetchWhatsAppRecipients()).single.active, false);
    },
  );
  test('technician cannot mutate devices or users; sessions revoke', () async {
    final login = await repository.login(
      username: 'tecnico',
      password: 'FiconLocal2026!',
    );
    final token = login.token;
    await expectLater(
      engine.request(
        'POST',
        Uri.parse('http://local.ficon/api/local/devices/d-0/power'),
        {'online': false},
        token,
      ),
      throwsA(isA<LocalFailure>().having((e) => e.status, 'status', 403)),
    );
    await repository.revokeAdminSession(token);
    await expectLater(
      engine.request(
        'GET',
        Uri.parse('http://local.ficon/api/devices'),
        {},
        token,
      ),
      throwsA(isA<LocalFailure>().having((e) => e.status, 'status', 401)),
    );
  });
  test('archive hides device and retains incident history', () async {
    await call('/api/local/devices/d-0/archive');
    expect(await repository.fetchDevices(), hasLength(3));
    expect(await repository.fetchIncidents(), hasLength(24));
  });
  test(
    'failed login recorded and password is not persisted in plaintext',
    () async {
      await expectLater(
        repository.login(username: 'admin', password: 'incorrecta'),
        throwsA(anything),
      );
      expect((await repository.fetchLoginAttempts()).first.success, false);
      expect(
        await engine.file.readAsString(),
        isNot(contains('FiconLocal2026!')),
      );
    },
  );
  test('unknown operations fail and never fall back to network', () async {
    await expectLater(
      engine.request(
        'GET',
        Uri.parse('http://local.ficon/api/missing'),
        {},
        session.token!,
      ),
      throwsA(isA<LocalFailure>()),
    );
  });
}

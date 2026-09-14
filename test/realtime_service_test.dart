import 'dart:async';

import 'package:ficon_power_frontend/application/realtime_service.dart';
import 'package:ficon_power_frontend/config/auth_session.dart';
import 'package:ficon_power_frontend/domain/auth_user.dart';
import 'package:ficon_power_frontend/domain/realtime_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('comparte una sola conexión entre varios consumidores', () async {
    final session = AuthSession()
      ..start(
        token: 'token',
        user: const AuthUser(
          id: 'user-1',
          username: 'reader',
          role: 'USER',
          displayName: 'Reader',
        ),
      );
    final source = StreamController<RealtimeChange>();
    var connections = 0;
    final service = RealtimeService(() {
      connections++;
      return source.stream;
    }, session);
    final first = <RealtimeChange>[];
    final second = <RealtimeChange>[];
    final firstSubscription = service.changes.listen(first.add);
    final secondSubscription = service.changes.listen(second.add);
    const change = RealtimeChange(
      id: '1',
      eventType: 'device.updated',
      entityType: 'device',
      payload: {},
      createdAt: null,
    );

    source.add(change);
    await Future<void>.delayed(Duration.zero);

    expect(connections, 1);
    expect(first, [change]);
    expect(second, [change]);
    await firstSubscription.cancel();
    await secondSubscription.cancel();
    service.dispose();
    await source.close();
  });
}

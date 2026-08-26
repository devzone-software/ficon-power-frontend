import 'dart:async';

import 'package:ficon_power_frontend/application/admin_activity_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const emptyData = AdminActivityData(
    users: [],
    auditLogs: [],
    loginAttempts: [],
    sessions: [],
    blockedUsers: [],
  );

  test('publica datos cargados y evita cargas simultáneas', () async {
    final pending = Completer<AdminActivityData>();
    var calls = 0;
    final controller = AdminActivityController(
      load: () {
        calls++;
        return pending.future;
      },
    );

    final first = controller.refresh(showLoading: true);
    await controller.refresh();
    pending.complete(emptyData);
    await first;

    expect(calls, 1);
    expect(controller.data, same(emptyData));
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('conserva el error para que la vista pueda reintentar', () async {
    final controller = AdminActivityController(
      load: () async => throw StateError('offline'),
    );

    await controller.refresh(showLoading: true);

    expect(controller.data, isNull);
    expect(controller.loading, isFalse);
    expect(controller.error, isA<StateError>());
    controller.dispose();
  });
}

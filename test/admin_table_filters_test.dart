import 'package:ficon_power_frontend/domain/admin_models.dart';
import 'package:ficon_power_frontend/presentation/admin/admin_table_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combina criterios de usuario con AND', () {
    final filters = AdminTableFilters(onChanged: () {})
      ..state.setText('users.role', 'admin')
      ..state.setText('users.status', 'activo');
    const activeAdmin = ManagedUser(
      id: '1',
      username: 'operator',
      role: 'ADMIN',
      displayName: 'Operator',
      active: true,
    );
    const revokedAdmin = ManagedUser(
      id: '2',
      username: 'old',
      role: 'ADMIN',
      displayName: 'Old',
      active: false,
    );

    expect(filters.matchesUser(activeAdmin), isTrue);
    expect(filters.matchesUser(revokedAdmin), isFalse);
  });

  test('aplica fecha e IP segmentada sobre audit logs', () {
    final filters = AdminTableFilters(onChanged: () {})
      ..state.setDate('audit.createdAt', DateTime(2026, 8, 13))
      ..state.setIpSegment('audit.ip', 0, '198')
      ..state.setIpSegment('audit.ip', 3, '30');
    final log = AuditLogEntry(
      id: '1',
      actorUsername: 'root',
      actorRole: 'SUPERADMIN',
      action: 'UPDATE',
      entityType: 'USER',
      entityId: '2',
      ipAddress: '198.162.74.30',
      userAgent: 'Browser',
      metadata: null,
      createdAt: DateTime(2026, 8, 13, 22),
    );

    expect(filters.matchesAuditLog(log), isTrue);
  });
}

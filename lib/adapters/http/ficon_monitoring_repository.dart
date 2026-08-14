import 'package:http/http.dart' as http;

import '../../config/auth_session.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/event.dart';
import '../../domain/incident.dart';
import '../../domain/notification_template.dart';
import '../../domain/site.dart';
import '../../ports/output/device_repository.dart';
import '../../ports/output/monitoring_query_repository.dart';
import '../../ports/output/notification_template_repository.dart';
import '../../ports/output/site_repository.dart';
import 'ficon_api_client.dart';

export 'ficon_api_client.dart' show ApiException;

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

/// Adaptador HTTP: implementa los puertos de salida
/// [MonitoringQueryRepository], [NotificationTemplateRepository],
/// [DeviceRepository] y [SiteRepository] contra la API REST del backend.
class FiconMonitoringRepository
    implements
        MonitoringQueryRepository,
        NotificationTemplateRepository,
        DeviceRepository,
        SiteRepository {
  FiconMonitoringRepository({
    http.Client? client,
    String? baseUrl,
    this.session,
  }) : _api = FiconApiClient(
         client: client,
         baseUrl: baseUrl,
         session: session,
       );

  final FiconApiClient _api;
  final AuthSession? session;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final data = await _api.postJson('/api/auth/login', {
      'username': username,
      'password': password,
    }, authenticated: false);
    return LoginResult(
      token: data['token'] as String? ?? '',
      user: AuthUser.fromJson(
        (data['user'] as Map<dynamic, dynamic>? ?? const {})
            .cast<String, dynamic>(),
      ),
    );
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/api/auth/logout', const {});
    } catch (_) {
      // El cierre local de sesión no debe bloquearse por red.
    }
  }

  Future<List<ManagedUser>> fetchUsers() async {
    final data = await _api.getList('/api/users');
    return data.map(ManagedUser.fromJson).toList();
  }

  Future<ManagedUser> createUser({
    required String username,
    required String password,
    required String role,
    required String displayName,
  }) async {
    final data = await _api.postJson('/api/users', {
      'username': username,
      'password': password,
      'role': role,
      'displayName': displayName,
    });
    return ManagedUser.fromJson(data);
  }

  Future<ManagedUser> updateUser(
    String id, {
    required String role,
    required String displayName,
    required bool active,
    String? password,
  }) async {
    final data = await _api.putJson('/api/users/$id', {
      'role': role,
      'displayName': displayName,
      'active': active,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return ManagedUser.fromJson(data);
  }

  Future<List<AuditLogEntry>> fetchAuditLogs({int limit = 100}) async {
    final data = await _api.getList('/api/admin/audit-logs?limit=$limit');
    return data.map(AuditLogEntry.fromJson).toList();
  }

  Future<List<LoginAttempt>> fetchLoginAttempts({int limit = 100}) async {
    final data = await _api.getList('/api/admin/login-attempts?limit=$limit');
    return data.map(LoginAttempt.fromJson).toList();
  }

  Future<List<AdminSession>> fetchAdminSessions({int limit = 100}) async {
    final data = await _api.getList('/api/admin/sessions?limit=$limit');
    return data.map(AdminSession.fromJson).toList();
  }

  Future<List<BlockedLoginUser>> fetchBlockedUsers({int limit = 100}) async {
    final data = await _api.getList('/api/admin/blocked-users?limit=$limit');
    return data.map(BlockedLoginUser.fromJson).toList();
  }

  Future<BlockedLoginUser> unblockBlockedUser(
    String id, {
    String reason = 'manual_superadmin_unlock',
  }) async {
    final data = await _api.postJson('/api/admin/blocked-users/$id/unblock', {
      'reason': reason,
    });
    return BlockedLoginUser.fromJson(data);
  }

  @override
  Future<List<Site>> fetchSites() async {
    final data = await _api.getList('/api/sites');
    return data.map(Site.fromJson).toList();
  }

  @override
  Future<List<Device>> fetchDevices() async {
    final data = await _api.getList('/api/devices');
    return data.map(Device.fromJson).toList();
  }

  @override
  Future<List<Incident>> fetchIncidents({int limit = 100}) async {
    final data = await _api.getList('/api/incidents?limit=$limit');
    return data.map(Incident.fromJson).toList();
  }

  @override
  Future<List<Event>> fetchEvents({int limit = 100}) async {
    final data = await _api.getList('/api/events?limit=$limit');
    return data.map(Event.fromJson).toList();
  }

  @override
  Future<List<NotificationTemplate>> fetchNotificationTemplates() async {
    final data = await _api.getList('/api/notification-templates');
    return data.map(NotificationTemplate.fromJson).toList();
  }

  @override
  Future<Device> updateDeviceDetails(
    String id, {
    required String name,
    required String siteId,
  }) async {
    final data = await _api.putJson('/api/devices/$id', {
      'name': name,
      'siteId': siteId,
    });
    return Device.fromJson(data);
  }

  @override
  Future<Site> createSite({
    required String name,
    String? district,
    String? province,
  }) async {
    final data = await _api.postJson('/api/sites', {
      'name': name,
      if (district != null && district.isNotEmpty) 'district': district,
      if (province != null && province.isNotEmpty) 'province': province,
    });
    return Site.fromJson(data);
  }

  void dispose() => _api.dispose();
}

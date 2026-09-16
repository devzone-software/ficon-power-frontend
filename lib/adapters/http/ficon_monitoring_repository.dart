import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/auth_session.dart';
import '../../domain/admin_models.dart';
import '../../domain/auth_user.dart';
import '../../domain/device.dart';
import '../../domain/device_detail.dart';
import '../../domain/event.dart';
import '../../domain/incident.dart';
import '../../domain/mobile_notification.dart';
import '../../domain/notification_template.dart';
import '../../domain/operations_calendar.dart';
import '../../domain/paged_result.dart';
import '../../domain/realtime_change.dart';
import '../../domain/site.dart';
import '../../domain/whatsapp_recipient.dart';
import '../../ports/output/device_repository.dart';
import '../../ports/output/monitoring_query_repository.dart';
import '../../ports/output/notification_template_repository.dart';
import '../../ports/output/operations_calendar_repository.dart';
import '../../ports/output/site_repository.dart';
import 'ficon_api_client.dart';

export 'ficon_api_client.dart' show ApiException;

class LoginResult {
  const LoginResult({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
    required this.user,
  });

  final String token;
  final String refreshToken;
  final DateTime? expiresAt;
  final DateTime? refreshExpiresAt;
  final AuthUser user;
}

class MobilePushTestResult {
  const MobilePushTestResult({
    required this.configured,
    required this.tokenRegistered,
    required this.accepted,
    required this.message,
  });

  final bool configured;
  final bool tokenRegistered;
  final bool accepted;
  final String message;

  factory MobilePushTestResult.fromJson(Map<String, dynamic> json) =>
      MobilePushTestResult(
        configured: json['configured'] as bool? ?? false,
        tokenRegistered: json['tokenRegistered'] as bool? ?? false,
        accepted: json['accepted'] as bool? ?? false,
        message: json['message'] as String? ?? 'Respuesta FCM no disponible.',
      );
}

/// Adaptador HTTP: implementa los puertos de salida
/// [MonitoringQueryRepository], [NotificationTemplateRepository],
/// [DeviceRepository] y [SiteRepository] contra la API REST del backend.
class FiconMonitoringRepository
    implements
        MonitoringQueryRepository,
        NotificationTemplateRepository,
        OperationsCalendarRepository,
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
  String? _registeredMobilePushToken;

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
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      refreshExpiresAt: DateTime.tryParse(
        data['refreshExpiresAt'] as String? ?? '',
      ),
      user: AuthUser.fromJson(
        (data['user'] as Map<dynamic, dynamic>? ?? const {})
            .cast<String, dynamic>(),
      ),
    );
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/api/auth/logout', {
        if (session?.refreshToken != null)
          'refreshToken': session!.refreshToken,
        if (_registeredMobilePushToken != null)
          'deviceToken': _registeredMobilePushToken,
      });
    } catch (_) {
      // El cierre local de sesión no debe bloquearse por red.
    } finally {
      _registeredMobilePushToken = null;
    }
  }

  Future<void> registerMobilePushToken({
    required String token,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    await _api.postJson('/api/mobile/device-tokens', {
      'token': token,
      'platform': platform,
      if (deviceName != null && deviceName.isNotEmpty) 'deviceName': deviceName,
      if (appVersion != null && appVersion.isNotEmpty) 'appVersion': appVersion,
    });
    _registeredMobilePushToken = token;
  }

  Future<void> revokeMobilePushToken(String token) async {
    if (_registeredMobilePushToken != token) return;
    await _api.deleteJson('/api/mobile/device-tokens', {'token': token});
    _registeredMobilePushToken = null;
  }

  Future<MobilePushTestResult> sendMobilePushTest(String token) async {
    final data = await _api.postJson('/api/mobile/device-tokens/test', {
      'token': token,
    });
    return MobilePushTestResult.fromJson(data);
  }

  Future<List<MobileNotification>> fetchMobileNotifications({
    int limit = 100,
  }) async {
    final data = await _api.getList('/api/mobile/notifications?limit=$limit');
    return data.map(MobileNotification.fromJson).toList();
  }

  Future<int> fetchMobileUnreadNotificationCount() async {
    final data = await _api.getJson('/api/mobile/notifications/unread-count');
    return data['unreadCount'] as int? ?? 0;
  }

  Future<void> markMobileNotificationRead(String id) async {
    await _api.patchJson('/api/mobile/notifications/$id/read');
  }

  Future<void> markAllMobileNotificationsRead() async {
    await _api.patchJson('/api/mobile/notifications/read-all');
  }

  Stream<RealtimeChange> openRealtimeChanges() async* {
    await for (final event in _api.getEventStream('/api/realtime/stream')) {
      if (event.event == 'ready' || event.data.trim().isEmpty) continue;
      final decoded = jsonDecode(event.data);
      if (decoded is Map<String, dynamic>) {
        yield RealtimeChange.fromJson(decoded);
      }
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
    String? email,
    String? whatsappPhone,
    bool whatsappEnabled = false,
  }) async {
    final data = await _api.postJson('/api/users', {
      'username': username,
      'password': password,
      'role': role,
      'displayName': displayName,
      'email': email,
      'whatsappPhone': whatsappPhone,
      'whatsappEnabled': whatsappEnabled,
    });
    return ManagedUser.fromJson(data);
  }

  Future<ManagedUser> updateUser(
    String id, {
    required String role,
    required String displayName,
    String? email,
    String? whatsappPhone,
    bool whatsappEnabled = false,
    required bool active,
    String? password,
  }) async {
    final data = await _api.putJson('/api/users/$id', {
      'role': role,
      'displayName': displayName,
      'email': email,
      'whatsappPhone': whatsappPhone,
      'whatsappEnabled': whatsappEnabled,
      'active': active,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return ManagedUser.fromJson(data);
  }

  Future<List<UserWhatsAppDelivery>> fetchUserWhatsAppDeliveries(
    String userId,
  ) async {
    final data = await _api.getList('/api/users/$userId/whatsapp-deliveries');
    return data.map(UserWhatsAppDelivery.fromJson).toList();
  }

  Future<WhatsAppTestResult> testUserWhatsApp(String userId) async {
    final data = await _api.postJson(
      '/api/users/$userId/whatsapp-test',
      const {},
      timeout: const Duration(seconds: 45),
    );
    return WhatsAppTestResult.fromJson(data);
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

  Future<void> revokeAdminSession(String id) async {
    await _api.postJson('/api/admin/sessions/$id/revoke', const {});
  }

  Future<List<WhatsAppRecipient>> fetchWhatsAppRecipients() async {
    final data = await _api.getList('/api/whatsapp-recipients');
    return data.map(WhatsAppRecipient.fromJson).toList();
  }

  Future<WhatsAppRecipient> saveWhatsAppRecipient({
    String? id,
    required String label,
    required String phone,
    String? siteId,
    required bool notifyOutage,
    required bool notifyRestored,
    required bool active,
  }) async {
    final payload = {
      'label': label.trim(),
      'phone': phone.trim(),
      'siteId': siteId,
      'notifyOutage': notifyOutage,
      'notifyRestored': notifyRestored,
      'active': active,
    };
    final data = id == null
        ? await _api.postJson('/api/whatsapp-recipients', payload)
        : await _api.putJson('/api/whatsapp-recipients/$id', payload);
    return WhatsAppRecipient.fromJson(data);
  }

  Future<void> deleteWhatsAppRecipient(String id) =>
      _api.deleteJson('/api/whatsapp-recipients/$id', const {});

  Future<WhatsAppTestResult> testWhatsAppRecipient(String id) async {
    final data = await _api.postJson(
      '/api/whatsapp-recipients/$id/test',
      const {},
      timeout: const Duration(seconds: 45),
    );
    return WhatsAppTestResult.fromJson(data);
  }

  @override
  Future<List<OperationsCalendarEntry>> fetchCalendarEntries({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _api.getList(
      _pathWithQuery('/api/calendar', {
        'from': _dateQueryValue(from),
        'to': _dateQueryValue(to),
      }),
    );
    return data.map(OperationsCalendarEntry.fromJson).toList();
  }

  @override
  Future<List<TuyaPlan>> fetchTuyaPlans() async {
    final data = await _api.getList('/api/calendar/tuya-plans');
    return data.map(TuyaPlan.fromJson).toList();
  }

  @override
  Future<TuyaPlan> saveTuyaPlan({
    int? id,
    required String projectName,
    required String planName,
    DateTime? lastRenewedOn,
    required DateTime nextRenewalOn,
    required int renewalIntervalMonths,
    required int reminderDays,
    String? notes,
    required bool active,
  }) async {
    final payload = {
      'projectName': projectName.trim(),
      'planName': planName.trim(),
      if (lastRenewedOn != null)
        'lastRenewedOn': _dateQueryValue(lastRenewedOn),
      'nextRenewalOn': _dateQueryValue(nextRenewalOn),
      'renewalIntervalMonths': renewalIntervalMonths,
      'reminderDays': reminderDays,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'active': active,
    };
    final data = id == null
        ? await _api.postJson('/api/calendar/tuya-plans', payload)
        : await _api.putJson('/api/calendar/tuya-plans/$id', payload);
    return TuyaPlan.fromJson(data);
  }

  @override
  Future<TuyaPlan> renewTuyaPlan(
    int id, {
    DateTime? renewedOn,
    String? notes,
  }) async {
    final data = await _api.postJson('/api/calendar/tuya-plans/$id/renew', {
      if (renewedOn != null) 'renewedOn': _dateQueryValue(renewedOn),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    return TuyaPlan.fromJson(data);
  }

  @override
  Future<void> deleteTuyaPlan(int id) =>
      _api.deleteJson('/api/calendar/tuya-plans/$id', const {});

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
  Future<DeviceDetail> fetchDeviceDetail(String deviceId) async {
    final data = await _api.getJson('/api/devices/$deviceId/detail');
    return DeviceDetail.fromJson(data);
  }

  @override
  Future<List<Incident>> fetchIncidents({int limit = 100}) async {
    final data = await _api.getList('/api/incidents?limit=$limit');
    return data.map(Incident.fromJson).toList();
  }

  @override
  Future<PagedResult<Incident>> fetchIncidentsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String status = '',
    String deviceName = '',
    String siteName = '',
    String incidentId = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = await _api.getJson(
      _pathWithQuery('/api/incidents', {
        'page': '$page',
        'size': '$size',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
        if (deviceName.trim().isNotEmpty) 'deviceName': deviceName.trim(),
        if (siteName.trim().isNotEmpty) 'siteName': siteName.trim(),
        if (incidentId.trim().isNotEmpty) 'incidentId': incidentId.trim(),
        if (startDate != null) 'startDate': _dateQueryValue(startDate),
        if (endDate != null) 'endDate': _dateQueryValue(endDate),
      }),
    );
    return PagedResult.fromJson(data, Incident.fromJson);
  }

  @override
  Future<void> acknowledgeIncident(String id) async {
    await _api.patchJson('/api/incidents/$id/acknowledge');
  }

  @override
  Future<List<Event>> fetchEvents({int limit = 100}) async {
    final data = await _api.getList('/api/events?limit=$limit');
    return data.map(Event.fromJson).toList();
  }

  @override
  Future<PagedResult<Event>> fetchEventsPage({
    int page = 0,
    int size = 10,
    String search = '',
    String eventType = '',
    String deviceName = '',
    String siteName = '',
    DateTime? occurredDate,
  }) async {
    final data = await _api.getJson(
      _pathWithQuery('/api/events', {
        'page': '$page',
        'size': '$size',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (eventType.trim().isNotEmpty) 'eventType': eventType.trim(),
        if (deviceName.trim().isNotEmpty) 'deviceName': deviceName.trim(),
        if (siteName.trim().isNotEmpty) 'siteName': siteName.trim(),
        if (occurredDate != null) 'occurredDate': _dateQueryValue(occurredDate),
      }),
    );
    return PagedResult.fromJson(data, Event.fromJson);
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

  String _pathWithQuery(String path, Map<String, String> query) {
    return Uri(path: path, queryParameters: query).toString();
  }

  String _dateQueryValue(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void dispose() => _api.dispose();
}

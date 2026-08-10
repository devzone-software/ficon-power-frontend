import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../config/auth_session.dart';
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

/// Error de comunicación con la API de FICON Power.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  @override
  String toString() =>
      'ApiException(${statusCode ?? 'sin respuesta'}): $message';
}

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
    AuthSession? session,
  })
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _session = session;

  final http.Client _client;
  final String _baseUrl;
  final AuthSession? _session;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_session?.token != null) 'Authorization': 'Bearer ${_session!.token}',
        if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
      };

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final data = await _sendJson(
      'POST',
      '/api/auth/login',
      {'username': username, 'password': password},
      authenticated: false,
    );
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
      await _sendJson('POST', '/api/auth/logout', const {});
    } catch (_) {
      // El cierre local de sesión no debe bloquearse por red.
    }
  }

  @override
  Future<List<Site>> fetchSites() async {
    final data = await _getList('/api/sites');
    return data.map(Site.fromJson).toList();
  }

  @override
  Future<List<Device>> fetchDevices() async {
    final data = await _getList('/api/devices');
    return data.map(Device.fromJson).toList();
  }

  @override
  Future<List<Incident>> fetchIncidents({int limit = 100}) async {
    final data = await _getList('/api/incidents?limit=$limit');
    return data.map(Incident.fromJson).toList();
  }

  @override
  Future<List<Event>> fetchEvents({int limit = 100}) async {
    final data = await _getList('/api/events?limit=$limit');
    return data.map(Event.fromJson).toList();
  }

  @override
  Future<List<NotificationTemplate>> fetchNotificationTemplates() async {
    final data = await _getList('/api/notification-templates');
    return data.map(NotificationTemplate.fromJson).toList();
  }

  @override
  Future<Device> updateDeviceDetails(
    String id, {
    required String name,
    required String siteId,
  }) async {
    final data = await _putJson('/api/devices/$id', {
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
    final data = await _postJson('/api/sites', {
      'name': name,
      if (district != null && district.isNotEmpty) 'district': district,
      if (province != null && province.isNotEmpty) 'province': province,
    });
    return Site.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('No se pudo conectar con $_baseUrl: $e');
    }
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(response, path),
        statusCode: response.statusCode,
        details: utf8.decode(response.bodyBytes),
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    Map<String, dynamic> payload,
  ) =>
      _sendJson('PUT', path, payload);

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) =>
      _sendJson('POST', path, payload);

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Map<String, dynamic> payload,
    {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      if (authenticated) ..._headers else 'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(payload);
    final http.Response response;
    try {
      response = await (method == 'POST'
              ? _client.post(uri, headers: headers, body: body)
              : _client.put(uri, headers: headers, body: body))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('No se pudo conectar con $_baseUrl: $e');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _errorMessage(response, path),
        statusCode: response.statusCode,
        details: utf8.decode(response.bodyBytes),
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded;
  }

  void dispose() => _client.close();

  String _errorMessage(http.Response response, String path) {
    final body = utf8.decode(response.bodyBytes);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'] ?? decoded['message'];
        if (error is String && error.isNotEmpty) return error;
      }
    } catch (_) {
      // Si no es JSON, cae al mensaje genérico.
    }
    return 'El backend respondió con un error en $path';
  }
}

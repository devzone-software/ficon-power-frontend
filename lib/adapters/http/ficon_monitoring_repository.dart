import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../domain/device.dart';
import '../../domain/incident.dart';
import '../../domain/site.dart';
import '../../ports/output/monitoring_query_repository.dart';

/// Error de comunicación con la API de FICON Power.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(${statusCode ?? 'sin respuesta'}): $message';
}

/// Adaptador HTTP: implementa el puerto de salida
/// [MonitoringQueryRepository] contra la API REST del backend.
class FiconMonitoringRepository implements MonitoringQueryRepository {
  FiconMonitoringRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
      };

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
        'El backend respondió con un error en $path',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  void dispose() => _client.close();
}

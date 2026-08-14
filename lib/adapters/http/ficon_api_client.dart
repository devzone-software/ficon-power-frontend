import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../config/auth_session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  @override
  String toString() =>
      'ApiException(${statusCode ?? 'sin respuesta'}): $message';
}

class FiconApiClient {
  FiconApiClient({http.Client? client, String? baseUrl, this.session})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String _baseUrl;
  final AuthSession? session;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (session?.token != null) 'Authorization': 'Bearer ${session!.token}',
    if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
  };

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await _request(
      () => _client.get(Uri.parse('$_baseUrl$path'), headers: _headers),
    );
    _requireStatus(response, path, const {200});
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload, {
    bool authenticated = true,
  }) => _sendJson('POST', path, payload, authenticated: authenticated);

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> payload,
  ) => _sendJson('PUT', path, payload);

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Map<String, dynamic> payload, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      if (authenticated) ..._headers else 'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(payload);
    final response = await _request(
      () => method == 'POST'
          ? _client.post(uri, headers: headers, body: body)
          : _client.put(uri, headers: headers, body: body),
    );
    _requireStatus(response, path, const {200, 201});
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded;
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(_timeout);
    } catch (error) {
      throw ApiException('No se pudo conectar con $_baseUrl: $error');
    }
  }

  void _requireStatus(http.Response response, String path, Set<int> accepted) {
    if (accepted.contains(response.statusCode)) return;
    throw ApiException(
      _errorMessage(response, path),
      statusCode: response.statusCode,
      details: utf8.decode(response.bodyBytes),
    );
  }

  String _errorMessage(http.Response response, String path) {
    final body = utf8.decode(response.bodyBytes);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'] ?? decoded['message'];
        if (error is String && error.isNotEmpty) return error;
      }
    } catch (_) {
      // Una respuesta no JSON utiliza el mensaje genérico del endpoint.
    }
    return 'El backend respondió con un error en $path';
  }

  void dispose() => _client.close();
}

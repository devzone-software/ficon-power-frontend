import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../config/auth_session.dart';
import 'exception_handler.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  @override
  String toString() => message;
}

class FiconApiClient {
  FiconApiClient({http.Client? client, String? baseUrl, this.session})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String _baseUrl;
  final AuthSession? session;
  Future<bool>? _refreshing;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (session?.token != null) 'Authorization': 'Bearer ${session!.token}',
    if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
  };

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await _requestWithRefresh(
      () => _client.get(Uri.parse('$_baseUrl$path'), headers: _headers),
    );
    _requireStatus(response, path, const {200});
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _requestWithRefresh(
      () => _client.get(Uri.parse('$_baseUrl$path'), headers: _headers),
    );
    _requireStatus(response, path, const {200});
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada en $path');
    }
    return decoded;
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

  Future<Map<String, dynamic>> patchJson(
    String path, [
    Map<String, dynamic> payload = const {},
  ]) => _sendJson('PATCH', path, payload);

  Future<void> deleteJson(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _requestWithRefresh(
      () => _client.delete(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );
    _requireStatus(response, path, const {200, 204});
  }

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
    final response = authenticated
        ? await _requestWithRefresh(
            () => method == 'POST'
                ? _client.post(
                    uri,
                    headers: {..._headers, 'Content-Type': 'application/json'},
                    body: body,
                  )
                : method == 'PUT'
                ? _client.put(
                    uri,
                    headers: {..._headers, 'Content-Type': 'application/json'},
                    body: body,
                  )
                : _client.patch(
                    uri,
                    headers: {..._headers, 'Content-Type': 'application/json'},
                    body: body,
                  ),
          )
        : await _request(
            () => method == 'POST'
                ? _client.post(uri, headers: headers, body: body)
                : method == 'PUT'
                ? _client.put(uri, headers: headers, body: body)
                : _client.patch(uri, headers: headers, body: body),
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

  Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function() send,
  ) async {
    final response = await _request(send);
    if (response.statusCode != 401 || session?.canRefresh != true) {
      return response;
    }
    if (await _refreshSession()) {
      return _request(send);
    }
    return response;
  }

  Future<bool> _refreshSession() {
    final active = _refreshing;
    if (active != null) return active;
    final refresh = _performRefresh();
    _refreshing = refresh;
    return refresh.whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final current = session;
    final refreshToken = current?.refreshToken;
    if (current == null || refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    final response = await _request(
      () => _client.post(
        Uri.parse('$_baseUrl/api/auth/refresh'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      current.clear();
      return false;
    }
    _requireStatus(response, '/api/auth/refresh', const {200});
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada en /api/auth/refresh');
    }
    final nextToken = data['token'] as String? ?? '';
    final nextRefreshToken = data['refreshToken'] as String? ?? '';
    if (nextToken.isEmpty || nextRefreshToken.isEmpty) {
      throw ApiException('La renovación no devolvió credenciales válidas');
    }
    current.renew(
      token: nextToken,
      refreshToken: nextRefreshToken,
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      refreshExpiresAt: DateTime.tryParse(
        data['refreshExpiresAt'] as String? ?? '',
      ),
    );
    return true;
  }

  void _requireStatus(http.Response response, String path, Set<int> accepted) {
    if (accepted.contains(response.statusCode)) return;
    throw ApiException(
      ExceptionHandler.fromResponse(response, path),
      statusCode: response.statusCode,
      details: utf8.decode(response.bodyBytes),
    );
  }

  void dispose() => _client.close();
}

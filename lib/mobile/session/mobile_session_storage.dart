// Persistencia segura del estado de autenticación móvil.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/auth_session.dart';
import '../../domain/auth_user.dart';

/// Persiste la sesión móvil hasta que el usuario cierre sesión.
///
/// El token se guarda en el almacenamiento seguro del dispositivo. En Android,
/// el plugin usa el Keystore del sistema para proteger los valores.
class MobileSessionStorage {
  MobileSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'ficon_power.auth.token';
  static const _refreshTokenKey = 'ficon_power.auth.refresh_token';
  static const _expiresAtKey = 'ficon_power.auth.expires_at';
  static const _refreshExpiresAtKey = 'ficon_power.auth.refresh_expires_at';
  static const _userKey = 'ficon_power.auth.user';

  final FlutterSecureStorage _secureStorage;

  Future<void> restoreInto(AuthSession session) async {
    final token = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final expiresAt = await _secureStorage.read(key: _expiresAtKey);
    final refreshExpiresAt = await _secureStorage.read(
      key: _refreshExpiresAtKey,
    );
    final userJson = await _secureStorage.read(key: _userKey);
    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      return;
    }

    try {
      final user = AuthUser.fromJson(
        (jsonDecode(userJson) as Map<dynamic, dynamic>).cast<String, dynamic>(),
      );
      session.start(
        token: token,
        refreshToken: refreshToken,
        expiresAt: DateTime.tryParse(expiresAt ?? ''),
        refreshExpiresAt: DateTime.tryParse(refreshExpiresAt ?? ''),
        user: user,
      );
    } catch (_) {
      await clear();
    }
  }

  Future<void> save(AuthSession session) async {
    final token = session.token;
    final refreshToken = session.refreshToken;
    final user = session.user;
    if (token == null || token.isEmpty || user == null) {
      await clear();
      return;
    }

    await _secureStorage.write(key: _tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _writeOptionalDate(_expiresAtKey, session.expiresAt);
    await _writeOptionalDate(_refreshExpiresAtKey, session.refreshExpiresAt);
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> _writeOptionalDate(String key, DateTime? value) async {
    if (value == null) {
      await _secureStorage.delete(key: key);
    } else {
      await _secureStorage.write(key: key, value: value.toIso8601String());
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
    await _secureStorage.delete(key: _refreshExpiresAtKey);
    await _secureStorage.delete(key: _userKey);
  }
}

import 'package:flutter/foundation.dart';

import '../domain/auth_user.dart';

class AuthSession extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  DateTime? _expiresAt;
  DateTime? _refreshExpiresAt;
  AuthUser? _user;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get expiresAt => _expiresAt;
  DateTime? get refreshExpiresAt => _refreshExpiresAt;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get canRefresh => _refreshToken != null && _refreshToken!.isNotEmpty;

  void start({
    required String token,
    required AuthUser user,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  }) {
    _token = token;
    _refreshToken = refreshToken;
    _expiresAt = expiresAt;
    _refreshExpiresAt = refreshExpiresAt;
    _user = user;
    notifyListeners();
  }

  void renew({
    required String token,
    required String refreshToken,
    required DateTime? expiresAt,
    required DateTime? refreshExpiresAt,
  }) {
    _token = token;
    _refreshToken = refreshToken;
    _expiresAt = expiresAt;
    _refreshExpiresAt = refreshExpiresAt;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _refreshToken = null;
    _expiresAt = null;
    _refreshExpiresAt = null;
    _user = null;
    notifyListeners();
  }
}

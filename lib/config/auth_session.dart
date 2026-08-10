import 'package:flutter/foundation.dart';

import '../domain/auth_user.dart';

class AuthSession extends ChangeNotifier {
  String? _token;
  AuthUser? _user;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  void start({required String token, required AuthUser user}) {
    _token = token;
    _user = user;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}

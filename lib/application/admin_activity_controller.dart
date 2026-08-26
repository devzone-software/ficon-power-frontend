import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/admin_models.dart';

typedef AdminActivityLoader = Future<AdminActivityData> Function();

class AdminActivityController extends ChangeNotifier {
  AdminActivityController({
    required this.load,
    this.refreshInterval = const Duration(seconds: 5),
  });

  final AdminActivityLoader load;
  final Duration refreshInterval;

  AdminActivityData? _data;
  Object? _error;
  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  bool _disposed = false;

  AdminActivityData? get data => _data;
  Object? get error => _error;
  bool get loading => _loading;

  void start({bool schedule = true}) {
    unawaited(refresh(showLoading: true));
    if (schedule) {
      _timer ??= Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
    }
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    if (showLoading) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final nextData = await load();
      if (_disposed) return;
      _data = nextData;
      _error = null;
      _loading = false;
      notifyListeners();
    } catch (failure) {
      if (_disposed) return;
      _error = failure;
      _loading = false;
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class AdminActivityData {
  const AdminActivityData({
    required this.users,
    required this.auditLogs,
    required this.loginAttempts,
    required this.sessions,
    required this.blockedUsers,
  });

  final List<ManagedUser> users;
  final List<AuditLogEntry> auditLogs;
  final List<LoginAttempt> loginAttempts;
  final List<AdminSession> sessions;
  final List<BlockedLoginUser> blockedUsers;
}

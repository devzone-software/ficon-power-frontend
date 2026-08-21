import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../adapters/http/ficon_monitoring_repository.dart';
import '../config/app_config.dart';
import '../config/auth_session.dart';
import 'mobile_firebase_config.dart';

class MobilePushRegistration extends StatefulWidget {
  const MobilePushRegistration({
    super.key,
    required this.session,
    required this.repository,
    required this.child,
  });

  final AuthSession session;
  final FiconMonitoringRepository repository;
  final Widget child;

  @override
  State<MobilePushRegistration> createState() => _MobilePushRegistrationState();
}

class _MobilePushRegistrationState extends State<MobilePushRegistration> {
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleSessionChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    unawaited(_refreshSubscription?.cancel());
    super.dispose();
  }

  void _handleSessionChange() {
    if (widget.session.isAuthenticated) {
      unawaited(_registerCurrentDevice());
    } else {
      unawaited(_revokeCurrentDevice());
    }
  }

  Future<void> _registerCurrentDevice() async {
    if (_initializing || !MobileFirebaseConfig.isConfigured) return;
    _initializing = true;
    try {
      await _ensureFirebaseReady();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }
      _refreshSubscription ??= messaging.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });
    } catch (_) {
      // El push no debe impedir usar el dashboard móvil.
    } finally {
      _initializing = false;
    }
  }

  Future<void> _revokeCurrentDevice() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null || token.isEmpty) return;
    try {
      await widget.repository.revokeMobilePushToken(token);
    } catch (_) {
      // Si no hay red al cerrar sesión, el token expirará o podrá revocarse luego.
    }
  }

  Future<void> _ensureFirebaseReady() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(options: MobileFirebaseConfig.options);
  }

  Future<void> _registerToken(String token) async {
    if (!widget.session.isAuthenticated) return;
    await widget.repository.registerMobilePushToken(
      token: token,
      platform: Platform.isAndroid ? 'android' : Platform.operatingSystem,
      deviceName: Platform.operatingSystem,
      appVersion: AppConfig.appVersionName,
    );
    _registeredToken = token;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

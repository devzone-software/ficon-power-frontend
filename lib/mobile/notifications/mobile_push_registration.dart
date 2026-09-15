// Registro, diagnóstico y revocación del token FCM asociado a la sesión móvil.
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../adapters/http/ficon_monitoring_repository.dart';
import '../../application/user_error_message.dart';
import '../../config/app_config.dart';
import '../../config/auth_session.dart';
import '../config/mobile_firebase_config.dart';

enum MobilePushPhase { inactive, registering, retrying, registered }

class MobilePushStatus extends ChangeNotifier {
  MobilePushPhase phase = MobilePushPhase.inactive;
  String permission = 'Sin comprobar';
  String? tokenHint;
  String? lastError;
  DateTime? nextRetryAt;
  bool testing = false;
  String? testMessage;
  Future<void> Function()? retryAction;
  Future<void> Function()? testAction;

  String get label => switch (phase) {
    MobilePushPhase.inactive => 'Inactivo',
    MobilePushPhase.registering => 'Registrando dispositivo',
    MobilePushPhase.retrying => 'Reintentando registro',
    MobilePushPhase.registered => 'Registrado',
  };
  bool get canRetry =>
      retryAction != null && phase != MobilePushPhase.registering;
  bool get canTest =>
      testAction != null && phase == MobilePushPhase.registered && !testing;

  Future<void> retryNow() async => retryAction?.call();
  Future<void> sendTest() async => testAction?.call();

  void changed() => notifyListeners();

  void update({
    required MobilePushPhase nextPhase,
    String? nextPermission,
    String? nextTokenHint,
    String? error,
    DateTime? retryAt,
    bool clearError = false,
    bool clearRetry = false,
  }) {
    phase = nextPhase;
    if (nextPermission != null) permission = nextPermission;
    if (nextTokenHint != null) tokenHint = nextTokenHint;
    if (clearError) lastError = null;
    if (error != null) lastError = error;
    if (clearRetry) nextRetryAt = null;
    if (retryAt != null) nextRetryAt = retryAt;
    notifyListeners();
  }
}

class MobilePushStatusScope extends InheritedNotifier<MobilePushStatus> {
  const MobilePushStatusScope({
    super.key,
    required MobilePushStatus status,
    required super.child,
  }) : super(notifier: status);

  static MobilePushStatus? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MobilePushStatusScope>()
      ?.notifier;
}

typedef PushPermissionRequester = Future<AuthorizationStatus> Function();
typedef PushTokenLoader = Future<String?> Function();
typedef PushTokenRegistrar = Future<void> Function(String token);

class MobilePushRegistration extends StatefulWidget {
  const MobilePushRegistration({
    super.key,
    required this.session,
    required this.repository,
    required this.child,
    this.retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
    ],
    this.requestPermission,
    this.loadToken,
    this.tokenRefreshes,
    this.registerToken,
  });

  final AuthSession session;
  final FiconMonitoringRepository repository;
  final Widget child;
  final List<Duration> retryDelays;
  final PushPermissionRequester? requestPermission;
  final PushTokenLoader? loadToken;
  final Stream<String>? tokenRefreshes;
  final PushTokenRegistrar? registerToken;

  @override
  State<MobilePushRegistration> createState() => _MobilePushRegistrationState();
}

class _MobilePushRegistrationState extends State<MobilePushRegistration>
    with WidgetsBindingObserver {
  final MobilePushStatus _status = MobilePushStatus();
  StreamSubscription<String>? _refreshSubscription;
  Timer? _retryTimer;
  String? _registeredToken;
  bool _registering = false;
  int _failures = 0;

  bool get _injected =>
      widget.requestPermission != null || widget.loadToken != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_sessionChanged);
    _status.retryAction = _retryNow;
    _status.testAction = _sendTest;
    _sessionChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.session.isAuthenticated) {
      unawaited(_retryNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.removeListener(_sessionChanged);
    _retryTimer?.cancel();
    unawaited(_refreshSubscription?.cancel());
    _status.dispose();
    super.dispose();
  }

  void _sessionChanged() => widget.session.isAuthenticated
      ? unawaited(_register())
      : unawaited(_revoke());

  Future<void> _register() async {
    if (_registering || !MobileFirebaseConfig.isConfigured && !_injected) {
      return;
    }
    _retryTimer?.cancel();
    _registering = true;
    _status.update(nextPhase: MobilePushPhase.registering, clearRetry: true);
    try {
      if (!_injected && Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: MobileFirebaseConfig.options);
      }
      final authorization =
          await (widget.requestPermission?.call() ??
              FirebaseMessaging.instance
                  .requestPermission(alert: true, badge: true, sound: true)
                  .then((settings) => settings.authorizationStatus));
      _status.update(
        nextPhase: MobilePushPhase.registering,
        nextPermission: _permissionLabel(authorization),
      );
      if (authorization == AuthorizationStatus.denied) {
        throw StateError('Android bloqueó el permiso de notificaciones.');
      }
      final token =
          await (widget.loadToken?.call() ??
              FirebaseMessaging.instance.getToken());
      if (token == null || token.isEmpty) {
        throw StateError(
          'Firebase no devolvió un token para este dispositivo.',
        );
      }
      await (widget.registerToken?.call(token) ?? _registerInBackend(token));
      _registeredToken = token;
      _failures = 0;
      _status.update(
        nextPhase: MobilePushPhase.registered,
        nextTokenHint: _mask(token),
        clearError: true,
        clearRetry: true,
      );
      _refreshSubscription ??=
          (widget.tokenRefreshes ?? FirebaseMessaging.instance.onTokenRefresh)
              .listen((_) => unawaited(_retryNow()));
    } catch (error) {
      _scheduleRetry(error);
    } finally {
      _registering = false;
    }
  }

  Future<void> _registerInBackend(String token) =>
      widget.repository.registerMobilePushToken(
        token: token,
        platform: Platform.isAndroid ? 'android' : Platform.operatingSystem,
        deviceName: Platform.operatingSystem,
        appVersion: AppConfig.appVersionName,
      );

  void _scheduleRetry(Object error) {
    if (!widget.session.isAuthenticated || widget.retryDelays.isEmpty) return;
    final retryIndex = _failures < widget.retryDelays.length
        ? _failures
        : widget.retryDelays.length - 1;
    final delay = widget.retryDelays[retryIndex];
    _failures++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(_register()));
    _status.update(
      nextPhase: MobilePushPhase.retrying,
      error: _friendlyError(error),
      retryAt: DateTime.now().add(delay),
    );
  }

  Future<void> _retryNow() async {
    if (!widget.session.isAuthenticated) return;
    _retryTimer?.cancel();
    await _register();
  }

  Future<void> _sendTest() async {
    final token = _registeredToken;
    if (token == null || _status.testing) return;
    _status.testing = true;
    _status.changed();
    try {
      final result = await widget.repository.sendMobilePushTest(token);
      _status.testMessage = result.message;
      if (!result.accepted) _status.lastError = result.message;
      if (!result.tokenRegistered) {
        _scheduleRetry(StateError(result.message));
      }
    } catch (error) {
      _status.testMessage = 'No se pudo solicitar la prueba FCM.';
      _status.lastError = _friendlyError(error);
    } finally {
      _status.testing = false;
      _status.changed();
    }
  }

  Future<void> _revoke() async {
    _retryTimer?.cancel();
    _failures = 0;
    final token = _registeredToken;
    _registeredToken = null;
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    _status.update(
      nextPhase: MobilePushPhase.inactive,
      clearError: true,
      clearRetry: true,
    );
    if (token == null || token.isEmpty) return;
    try {
      await widget.repository.revokeMobilePushToken(token);
      if (!_injected) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // El cierre local no se bloquea si la red o Firebase no están disponibles.
    }
  }

  String _permissionLabel(AuthorizationStatus value) => switch (value) {
    AuthorizationStatus.authorized => 'Permitido',
    AuthorizationStatus.provisional => 'Provisional',
    AuthorizationStatus.denied => 'Bloqueado',
    AuthorizationStatus.notDetermined => 'Sin decidir',
  };

  String _mask(String token) => token.length <= 8
      ? '••••$token'
      : '••••${token.substring(token.length - 8)}';

  String _friendlyError(Object error) => UserErrorMessage.from(error);

  @override
  Widget build(BuildContext context) =>
      MobilePushStatusScope(status: _status, child: widget.child);
}

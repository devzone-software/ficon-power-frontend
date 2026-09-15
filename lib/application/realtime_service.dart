import 'dart:async';

import '../config/auth_session.dart';
import '../domain/realtime_change.dart';

class RealtimeService {
  RealtimeService(this._connect, this._session) {
    _changes = StreamController<RealtimeChange>.broadcast(
      onListen: _start,
      onCancel: _stopWhenUnused,
    );
    _session?.addListener(_handleSessionChange);
  }

  final Stream<RealtimeChange> Function() _connect;
  final AuthSession? _session;
  late final StreamController<RealtimeChange> _changes;
  StreamSubscription<RealtimeChange>? _connection;
  Timer? _retryTimer;
  Duration _retryDelay = const Duration(seconds: 1);
  bool _disposed = false;

  Stream<RealtimeChange> get changes => _changes.stream;

  void _start() {
    if (_disposed || _connection != null || _retryTimer != null) return;
    if (_session?.isAuthenticated == false) return;
    _connection = _connect().listen(
      (change) {
        _retryDelay = const Duration(seconds: 1);
        _changes.add(change);
      },
      onError: (_, _) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    _connection = null;
    if (_disposed ||
        !_changes.hasListener ||
        _session?.isAuthenticated == false) {
      return;
    }
    _retryTimer ??= Timer(_retryDelay, () {
      _retryTimer = null;
      _start();
    });
    final seconds = (_retryDelay.inSeconds * 2).clamp(1, 30);
    _retryDelay = Duration(seconds: seconds);
  }

  void _stopWhenUnused() {
    if (_changes.hasListener) return;
    _stop();
  }

  void _handleSessionChange() {
    if (_session?.isAuthenticated == true && _changes.hasListener) {
      _start();
    } else {
      _stop();
    }
  }

  void _stop() {
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_connection?.cancel());
    _connection = null;
    _retryDelay = const Duration(seconds: 1);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session?.removeListener(_handleSessionChange);
    _stop();
    unawaited(_changes.close());
  }
}

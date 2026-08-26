import 'package:flutter/foundation.dart';

import '../domain/mobile_notification.dart';

typedef MobileNotificationLoader = Future<List<MobileNotification>> Function();
typedef MobileNotificationMarker = Future<void> Function(String id);
typedef MobileNotificationsMarker = Future<void> Function();

class MobileNotificationController extends ChangeNotifier {
  MobileNotificationController(this._load, this._markRead, this._markAllRead);

  final MobileNotificationLoader _load;
  final MobileNotificationMarker _markRead;
  final MobileNotificationsMarker _markAllRead;

  List<MobileNotification> _items = const [];
  bool _loading = false;
  Object? _error;

  List<MobileNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  Object? get error => _error;
  int get unreadCount => _items.where((item) => item.unread).length;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _load();
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> read(String id) async {
    final index = _items.indexWhere((item) => item.id == id && item.unread);
    if (index < 0) return;
    await _markRead(id);
    final updated = [..._items];
    updated[index] = updated[index].markRead();
    _items = updated;
    notifyListeners();
  }

  Future<void> readAll() async {
    if (unreadCount == 0) return;
    await _markAllRead();
    _items = _items.map((item) => item.markRead()).toList();
    notifyListeners();
  }
}

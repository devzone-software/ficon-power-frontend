// Traducción de eventos de dominio a contenido de notificación.
import '../../domain/event.dart';

class EventNotificationContent {
  const EventNotificationContent({required this.title, required this.body});

  final String title;
  final String body;

  factory EventNotificationContent.fromEvent(Event event) {
    final title = switch (event.eventType) {
      'deviceOffline' => 'Corte detectado',
      'deviceOnline' => 'Retorno detectado',
      _ => 'Nuevo evento FICON Power',
    };
    final device = event.deviceName?.trim().isNotEmpty == true
        ? event.deviceName!.trim()
        : 'Dispositivo';
    final site = event.siteName?.trim().isNotEmpty == true
        ? ' · ${event.siteName!.trim()}'
        : '';
    return EventNotificationContent(title: title, body: '$device$site');
  }
}

class MobileEventDetector {
  String? _lastSeenEventId;

  bool get isPrimed => _lastSeenEventId != null;

  void reset() => _lastSeenEventId = null;

  void prime(List<Event> events) {
    if (events.isNotEmpty) _lastSeenEventId = events.first.id;
  }

  List<Event> detect(List<Event> newestFirst) {
    if (newestFirst.isEmpty) return const [];
    final lastSeen = _lastSeenEventId;
    if (lastSeen == null) {
      prime(newestFirst);
      return const [];
    }

    final newEvents = <Event>[];
    for (final event in newestFirst) {
      if (event.id == lastSeen) break;
      newEvents.add(event);
    }
    if (newEvents.isEmpty) return const [];

    _lastSeenEventId = newestFirst.first.id;
    return newEvents.reversed.toList(growable: false);
  }
}

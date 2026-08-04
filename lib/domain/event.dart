/// Evento Tuya recibido por el backend. Espejo de `EventView` del backend.
class Event {
  const Event({
    required this.id,
    required this.eventType,
    this.deviceName,
    this.siteName,
    this.occurredAt,
    this.receivedAt,
    required this.deliveryLatencyMillis,
  });

  final String id;
  final String eventType;
  final String? deviceName;
  final String? siteName;
  final DateTime? occurredAt;
  final DateTime? receivedAt;
  final int deliveryLatencyMillis;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      eventType: json['eventType'] as String? ?? '',
      deviceName: json['deviceName'] as String?,
      siteName: json['siteName'] as String?,
      occurredAt: _parseDate(json['occurredAt']),
      receivedAt: _parseDate(json['receivedAt']),
      deliveryLatencyMillis:
          (json['deliveryLatencyMillis'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

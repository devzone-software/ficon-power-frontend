/// Incidente de corte de energía. Espejo de `IncidentView` del backend.
class Incident {
  const Incident({
    required this.id,
    required this.status,
    this.deviceName,
    this.siteName,
    this.startTime,
    this.endTime,
    this.durationSeconds,
  });

  final String id;

  /// `active`, `acknowledged` o `resolved` (CHECK constraint del backend).
  final String status;
  final String? deviceName;
  final String? siteName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationSeconds;

  bool get isOpen => status == 'active' || status == 'acknowledged';

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      status: json['status'] as String? ?? '',
      deviceName: json['deviceName'] as String?,
      siteName: json['siteName'] as String?,
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

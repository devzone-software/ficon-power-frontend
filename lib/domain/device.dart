/// Dispositivo Tuya monitoreado. Espejo de `DeviceView` del backend.
class Device {
  const Device({
    required this.id,
    required this.name,
    this.externalId,
    this.category,
    this.model,
    required this.active,
    required this.status,
    this.lastStatusChange,
    this.siteId,
    this.siteName,
    this.district,
    this.currentIncidentStartedAt,
    required this.eventCount,
    required this.incidentCount,
    required this.totalDowntimeSeconds,
  });

  final String id;
  final String name;
  final String? externalId;
  final String? category;
  final String? model;
  final bool active;

  /// `online` u `offline` (valores del CHECK constraint del backend).
  final String status;
  final DateTime? lastStatusChange;
  final String? siteId;
  final String? siteName;
  final String? district;
  final DateTime? currentIncidentStartedAt;
  final int eventCount;
  final int incidentCount;
  final int totalDowntimeSeconds;

  bool get isOnline => status == 'online';

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      externalId: json['externalId'] as String?,
      category: json['category'] as String?,
      model: json['model'] as String?,
      active: json['active'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      lastStatusChange: _parseDate(json['lastStatusChange']),
      siteId: json['siteId'] as String?,
      siteName: json['siteName'] as String?,
      district: json['district'] as String?,
      currentIncidentStartedAt: _parseDate(json['currentIncidentStartedAt']),
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      incidentCount: (json['incidentCount'] as num?)?.toInt() ?? 0,
      totalDowntimeSeconds:
          (json['totalDowntimeSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

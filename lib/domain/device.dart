/// Dispositivo Tuya monitoreado. Espejo de `DeviceView` del backend.
class Device {
  const Device({
    required this.id,
    required this.name,
    this.externalId,
    this.provider,
    this.category,
    this.productId,
    this.model,
    required this.active,
    required this.status,
    this.lastStatusChange,
    this.siteId,
    this.siteName,
    this.district,
    this.province,
    this.department,
    this.latitude,
    this.longitude,
    this.currentIncidentStartedAt,
    required this.eventCount,
    required this.incidentCount,
    required this.totalDowntimeSeconds,
  });

  final String id;
  final String name;
  final String? externalId;
  final String? provider;
  final String? category;
  final String? productId;
  final String? model;
  final bool active;

  /// `online` u `offline` (valores del CHECK constraint del backend).
  final String status;
  final DateTime? lastStatusChange;
  final String? siteId;
  final String? siteName;
  final String? district;
  final String? province;
  final String? department;
  final double? latitude;
  final double? longitude;
  final DateTime? currentIncidentStartedAt;
  final int eventCount;
  final int incidentCount;
  final int totalDowntimeSeconds;

  bool get isOnline => status == 'online';
  bool get hasActiveIncident => currentIncidentStartedAt != null;
  bool get hasLocation => latitude != null && longitude != null;

  ({double latitude, double longitude})? get punoMapLocation {
    if (hasLocation) {
      return (latitude: latitude!, longitude: longitude!);
    }

    return _recognizedPunoCityLocation;
  }

  ({double latitude, double longitude})? get _recognizedPunoCityLocation {
    final location = [
      siteName,
      district,
      province,
    ].whereType<String>().map(_normalizeLocation).join(' ');
    if (_containsLocation(location, 'putina')) {
      return (latitude: -14.9141, longitude: -69.86848);
    }
    if (_containsLocation(location, 'lampa')) {
      return (latitude: -15.36443, longitude: -70.36662);
    }
    if (_containsLocation(location, 'puno')) {
      return (latitude: -15.81154, longitude: -70.0323);
    }
    return null;
  }

  bool get isInPuno {
    if (_normalizeLocation(department) == 'puno' ||
        _normalizeLocation(province) == 'puno') {
      return true;
    }
    return _recognizedPunoCityLocation != null;
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      externalId: json['externalId'] as String?,
      provider: json['provider'] as String?,
      category: json['category'] as String?,
      productId: json['productId'] as String?,
      model: json['model'] as String?,
      active: json['active'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      lastStatusChange: _parseDate(json['lastStatusChange']),
      siteId: json['siteId'] as String?,
      siteName: json['siteName'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      department: json['department'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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

  static String _normalizeLocation(String? value) =>
      value?.trim().toLowerCase() ?? '';

  static bool _containsLocation(String value, String location) => RegExp(
    '(^|[^a-záéíóúñ])${RegExp.escape(location)}([^a-záéíóúñ]|\$)',
  ).hasMatch(value);
}

/// Sede (establecimiento) monitoreada. Espejo de `SiteView` del backend.
class Site {
  const Site({
    required this.id,
    required this.name,
    this.address,
    this.district,
    this.province,
    this.department,
    this.timeZone,
    required this.active,
    required this.deviceCount,
  });

  final String id;
  final String name;
  final String? address;
  final String? district;
  final String? province;
  final String? department;
  final String? timeZone;
  final bool active;
  final int deviceCount;

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      department: json['department'] as String?,
      timeZone: json['timeZone'] as String?,
      active: json['active'] as bool? ?? false,
      deviceCount: (json['deviceCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// "Distrito, Provincia" con las partes disponibles.
  String get locationLabel => [
        district,
        province,
      ].whereType<String>().where((p) => p.isNotEmpty).join(', ');
}

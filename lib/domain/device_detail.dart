import 'device.dart';
import 'incident.dart';

class DeviceDetail {
  const DeviceDetail({
    required this.device,
    required this.metrics,
    required this.dailyIncidents,
    required this.weeklyIncidents,
    required this.monthlyIncidents,
    required this.weekdayIncidents,
    required this.timeOfDayIncidents,
    required this.recentIncidents,
  });

  final Device device;
  final DeviceDetailMetrics metrics;
  final List<DeviceFrequencyPoint> dailyIncidents;
  final List<DeviceFrequencyPoint> weeklyIncidents;
  final List<DeviceFrequencyPoint> monthlyIncidents;
  final List<DeviceFrequencyPoint> weekdayIncidents;
  final List<DeviceFrequencyPoint> timeOfDayIncidents;
  final List<Incident> recentIncidents;

  factory DeviceDetail.fromJson(Map<String, dynamic> json) => DeviceDetail(
    device: Device.fromJson(_map(json['device'])),
    metrics: DeviceDetailMetrics.fromJson(_map(json['metrics'])),
    dailyIncidents: _points(json['dailyIncidents']),
    weeklyIncidents: _points(json['weeklyIncidents']),
    monthlyIncidents: _points(json['monthlyIncidents']),
    weekdayIncidents: _points(json['weekdayIncidents']),
    timeOfDayIncidents: _points(json['timeOfDayIncidents']),
    recentIncidents: _list(
      json['recentIncidents'],
    ).map((item) => Incident.fromJson(_map(item))).toList(growable: false),
  );

  static List<DeviceFrequencyPoint> _points(dynamic value) => _list(value)
      .map((item) => DeviceFrequencyPoint.fromJson(_map(item)))
      .toList(growable: false);

  static Map<String, dynamic> _map(dynamic value) =>
      (value as Map<dynamic, dynamic>? ?? const {}).cast<String, dynamic>();

  static List<dynamic> _list(dynamic value) =>
      value as List<dynamic>? ?? const [];
}

class DeviceDetailMetrics {
  const DeviceDetailMetrics({
    required this.incidentsLast7Days,
    required this.incidentsLast30Days,
    required this.incidentsLast90Days,
    required this.averageDowntimeSeconds,
    required this.longestDowntimeSeconds,
    required this.availabilityLast30Days,
  });

  final int incidentsLast7Days;
  final int incidentsLast30Days;
  final int incidentsLast90Days;
  final int averageDowntimeSeconds;
  final int longestDowntimeSeconds;
  final double availabilityLast30Days;

  factory DeviceDetailMetrics.fromJson(
    Map<String, dynamic> json,
  ) => DeviceDetailMetrics(
    incidentsLast7Days: (json['incidentsLast7Days'] as num?)?.toInt() ?? 0,
    incidentsLast30Days: (json['incidentsLast30Days'] as num?)?.toInt() ?? 0,
    incidentsLast90Days: (json['incidentsLast90Days'] as num?)?.toInt() ?? 0,
    averageDowntimeSeconds:
        (json['averageDowntimeSeconds'] as num?)?.toInt() ?? 0,
    longestDowntimeSeconds:
        (json['longestDowntimeSeconds'] as num?)?.toInt() ?? 0,
    availabilityLast30Days:
        (json['availabilityLast30Days'] as num?)?.toDouble() ?? 100,
  );
}

class DeviceFrequencyPoint {
  const DeviceFrequencyPoint({required this.label, required this.count});

  final String label;
  final int count;

  factory DeviceFrequencyPoint.fromJson(Map<String, dynamic> json) =>
      DeviceFrequencyPoint(
        label: json['label'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

import '../domain/device.dart';
import '../domain/incident.dart';
import '../domain/monitoring_overview.dart';

class DashboardStatistics {
  const DashboardStatistics({
    required this.totalPowerOutages,
    required this.totalDowntimeSeconds,
    required this.averageIncidentSeconds,
    required this.dailyIncidents,
    required this.weeklyIncidents,
    required this.monthlyIncidents,
    required this.weekdayIncidents,
    required this.timeOfDayIncidents,
    required this.deviceRankings,
  });

  final int totalPowerOutages;
  final int totalDowntimeSeconds;
  final int averageIncidentSeconds;
  final List<FrequencyPoint> dailyIncidents;
  final List<FrequencyPoint> weeklyIncidents;
  final List<FrequencyPoint> monthlyIncidents;
  final List<FrequencyPoint> weekdayIncidents;
  final List<FrequencyPoint> timeOfDayIncidents;
  final List<DeviceImpactStat> deviceRankings;

  String get weeklyAverageText {
    if (weeklyIncidents.isEmpty) return '0/sem';
    final total = weeklyIncidents.fold<int>(0, (sum, item) => sum + item.count);
    return '${(total / weeklyIncidents.length).toStringAsFixed(1)}/sem';
  }

  factory DashboardStatistics.from(
    MonitoringOverview data, {
    DateTime? referenceTime,
  }) {
    final durations = data.incidents
        .map((incident) => incident.durationSeconds)
        .whereType<int>()
        .where((duration) => duration > 0)
        .toList(growable: false);
    final averageDuration = durations.isEmpty
        ? 0
        : (durations.reduce((sum, duration) => sum + duration) /
                  durations.length)
              .round();
    final frequency = _FrequencyCalculator(
      incidents: data.incidents,
      referenceTime: referenceTime ?? DateTime.now(),
    );

    return DashboardStatistics(
      totalPowerOutages: data.incidents.length,
      totalDowntimeSeconds: data.devices.fold<int>(
        0,
        (sum, device) => sum + device.totalDowntimeSeconds,
      ),
      averageIncidentSeconds: averageDuration,
      dailyIncidents: frequency.daily(),
      weeklyIncidents: frequency.weekly(),
      monthlyIncidents: frequency.monthly(),
      weekdayIncidents: frequency.byWeekday(),
      timeOfDayIncidents: frequency.byTimeOfDay(),
      deviceRankings: _deviceRankings(data.devices),
    );
  }

  static List<DeviceImpactStat> _deviceRankings(List<Device> devices) {
    final rankings =
        devices
            .map(
              (device) => DeviceImpactStat(
                label: device.name.isNotEmpty
                    ? device.name
                    : device.externalId ?? 'Dispositivo',
                incidents: device.incidentCount,
                downtimeSeconds: device.totalDowntimeSeconds,
              ),
            )
            .where((item) => item.incidents > 0 || item.downtimeSeconds > 0)
            .toList()
          ..sort((a, b) {
            final incidentOrder = b.incidents.compareTo(a.incidents);
            return incidentOrder != 0
                ? incidentOrder
                : b.downtimeSeconds.compareTo(a.downtimeSeconds);
          });
    return List.unmodifiable(rankings.take(10));
  }
}

class _FrequencyCalculator {
  const _FrequencyCalculator({
    required this.incidents,
    required this.referenceTime,
  });

  final List<Incident> incidents;
  final DateTime referenceTime;

  List<FrequencyPoint> daily() {
    final today = _dateOnly(referenceTime);
    final counts = <DateTime, int>{
      for (var offset = 6; offset >= 0; offset--)
        today.subtract(Duration(days: offset)): 0,
    };
    _countByDate(counts, (date) => _dateOnly(date));
    return List.unmodifiable(
      counts.entries.map(
        (entry) => FrequencyPoint(
          label: '${_twoDigits(entry.key.day)}/${_twoDigits(entry.key.month)}',
          count: entry.value,
        ),
      ),
    );
  }

  List<FrequencyPoint> weekly() {
    final today = _dateOnly(referenceTime);
    final currentMonday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final counts = <DateTime, int>{
      for (var offset = 3; offset >= 0; offset--)
        currentMonday.subtract(Duration(days: offset * 7)): 0,
    };
    _countByDate(
      counts,
      (date) => _dateOnly(
        date,
      ).subtract(Duration(days: date.weekday - DateTime.monday)),
    );
    return List.unmodifiable(
      counts.entries.map(
        (entry) => FrequencyPoint(
          label:
              'S ${_twoDigits(entry.key.day)}/${_twoDigits(entry.key.month)}',
          count: entry.value,
        ),
      ),
    );
  }

  List<FrequencyPoint> monthly() {
    final counts = <DateTime, int>{
      for (var offset = 5; offset >= 0; offset--)
        DateTime(referenceTime.year, referenceTime.month - offset): 0,
    };
    _countByDate(counts, (date) => DateTime(date.year, date.month));
    return List.unmodifiable(
      counts.entries.map(
        (entry) => FrequencyPoint(
          label: _monthNames[entry.key.month - 1],
          count: entry.value,
        ),
      ),
    );
  }

  List<FrequencyPoint> byWeekday() {
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final counts = List<int>.filled(labels.length, 0);
    for (final start in _startTimes) {
      counts[start.weekday - 1]++;
    }
    return List.unmodifiable([
      for (var index = 0; index < labels.length; index++)
        FrequencyPoint(label: labels[index], count: counts[index]),
    ]);
  }

  List<FrequencyPoint> byTimeOfDay() {
    final counts = List<int>.filled(4, 0);
    for (final start in _startTimes) {
      counts[(start.hour ~/ 6).clamp(0, 3)]++;
    }
    return List.unmodifiable([
      FrequencyPoint(label: '00-06', count: counts[0]),
      FrequencyPoint(label: '06-12', count: counts[1]),
      FrequencyPoint(label: '12-18', count: counts[2]),
      FrequencyPoint(label: '18-24', count: counts[3]),
    ]);
  }

  Iterable<DateTime> get _startTimes =>
      incidents.map((incident) => incident.startTime).whereType<DateTime>();

  void _countByDate(
    Map<DateTime, int> counts,
    DateTime Function(DateTime value) bucket,
  ) {
    for (final start in _startTimes) {
      final key = bucket(start);
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static const _monthNames = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
}

class FrequencyPoint {
  const FrequencyPoint({required this.label, required this.count});

  final String label;
  final int count;
}

class DeviceImpactStat {
  const DeviceImpactStat({
    required this.label,
    required this.incidents,
    required this.downtimeSeconds,
  });

  final String label;
  final int incidents;
  final int downtimeSeconds;
}

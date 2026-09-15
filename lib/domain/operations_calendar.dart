enum OperationsCalendarEntryType { incident, tuyaRenewal, tuyaRenewed }

class OperationsCalendarEntry {
  const OperationsCalendarEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.startAt,
    this.endAt,
    required this.status,
    this.deviceId,
    this.deviceName,
    this.siteId,
    this.siteName,
    this.tuyaPlanId,
    this.description,
  });

  final String id;
  final OperationsCalendarEntryType type;
  final String title;
  final DateTime date;
  final DateTime? startAt;
  final DateTime? endAt;
  final String status;
  final String? deviceId;
  final String? deviceName;
  final String? siteId;
  final String? siteName;
  final int? tuyaPlanId;
  final String? description;

  bool get isIncident => type == OperationsCalendarEntryType.incident;
  bool get isRenewal => type == OperationsCalendarEntryType.tuyaRenewal;
  bool get isCompletedRenewal =>
      type == OperationsCalendarEntryType.tuyaRenewed;

  bool occursOn(DateTime day) {
    final target = dateOnly(day);
    if (!isIncident) return sameDate(date, target);
    final start = dateOnly(startAt ?? date);
    final end = dateOnly(endAt ?? DateTime.now());
    return !target.isBefore(start) && !target.isAfter(end);
  }

  factory OperationsCalendarEntry.fromJson(Map<String, dynamic> json) {
    return OperationsCalendarEntry(
      id: json['id'] as String? ?? '',
      type: switch (json['type'] as String?) {
        'TUYA_RENEWAL' => OperationsCalendarEntryType.tuyaRenewal,
        'TUYA_RENEWED' => OperationsCalendarEntryType.tuyaRenewed,
        _ => OperationsCalendarEntryType.incident,
      },
      title: json['title'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      startAt: parseCalendarDate(json['startAt']),
      endAt: parseCalendarDate(json['endAt']),
      status: json['status'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      siteId: json['siteId'] as String?,
      siteName: json['siteName'] as String?,
      tuyaPlanId: (json['tuyaPlanId'] as num?)?.toInt(),
      description: json['description'] as String?,
    );
  }
}

class TuyaPlan {
  const TuyaPlan({
    required this.id,
    required this.projectName,
    required this.planName,
    this.lastRenewedOn,
    required this.nextRenewalOn,
    required this.renewalIntervalMonths,
    required this.reminderDays,
    this.notes,
    required this.active,
  });

  final int id;
  final String projectName;
  final String planName;
  final DateTime? lastRenewedOn;
  final DateTime nextRenewalOn;
  final int renewalIntervalMonths;
  final int reminderDays;
  final String? notes;
  final bool active;

  int daysUntilRenewal([DateTime? today]) => dateOnly(
    nextRenewalOn,
  ).difference(dateOnly(today ?? DateTime.now())).inDays;

  String status([DateTime? today]) {
    if (!active) return 'INACTIVE';
    final days = daysUntilRenewal(today);
    if (days < 0) return 'OVERDUE';
    if (days <= reminderDays) return 'DUE_SOON';
    return 'SCHEDULED';
  }

  factory TuyaPlan.fromJson(Map<String, dynamic> json) {
    return TuyaPlan(
      id: (json['id'] as num).toInt(),
      projectName: json['projectName'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      lastRenewedOn: parseCalendarDate(json['lastRenewedOn']),
      nextRenewalOn: DateTime.parse(json['nextRenewalOn'] as String),
      renewalIntervalMonths:
          (json['renewalIntervalMonths'] as num?)?.toInt() ?? 6,
      reminderDays: (json['reminderDays'] as num?)?.toInt() ?? 30,
      notes: json['notes'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class OperationsCalendarData {
  const OperationsCalendarData({required this.entries, required this.plans});

  final List<OperationsCalendarEntry> entries;
  final List<TuyaPlan> plans;
}

DateTime? parseCalendarDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

List<DateTime> calendarGridDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  final gridStart = first.subtract(
    Duration(days: first.weekday - DateTime.monday),
  );
  final gridEnd = last.add(Duration(days: DateTime.sunday - last.weekday));
  return List.generate(
    gridEnd.difference(gridStart).inDays + 1,
    (index) => gridStart.add(Duration(days: index)),
  );
}

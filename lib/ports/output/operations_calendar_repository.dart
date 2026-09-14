import '../../domain/operations_calendar.dart';

abstract interface class OperationsCalendarRepository {
  Future<List<OperationsCalendarEntry>> fetchCalendarEntries({
    required DateTime from,
    required DateTime to,
  });

  Future<List<TuyaPlan>> fetchTuyaPlans();

  Future<TuyaPlan> saveTuyaPlan({
    int? id,
    required String projectName,
    required String planName,
    DateTime? lastRenewedOn,
    required DateTime nextRenewalOn,
    required int renewalIntervalMonths,
    required int reminderDays,
    String? notes,
    required bool active,
  });

  Future<TuyaPlan> renewTuyaPlan(int id, {DateTime? renewedOn, String? notes});

  Future<void> deleteTuyaPlan(int id);
}

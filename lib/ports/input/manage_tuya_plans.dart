import '../../domain/operations_calendar.dart';

abstract interface class ManageTuyaPlans {
  Future<List<TuyaPlan>> list();

  Future<TuyaPlan> save({
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

  Future<TuyaPlan> renew(int id, {DateTime? renewedOn, String? notes});

  Future<void> delete(int id);
}

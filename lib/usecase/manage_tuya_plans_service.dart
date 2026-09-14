import '../domain/operations_calendar.dart';
import '../ports/input/manage_tuya_plans.dart';
import '../ports/output/operations_calendar_repository.dart';

class ManageTuyaPlansService implements ManageTuyaPlans {
  const ManageTuyaPlansService(this._repository);

  final OperationsCalendarRepository _repository;

  @override
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
  }) => _repository.saveTuyaPlan(
    id: id,
    projectName: projectName,
    planName: planName,
    lastRenewedOn: lastRenewedOn,
    nextRenewalOn: nextRenewalOn,
    renewalIntervalMonths: renewalIntervalMonths,
    reminderDays: reminderDays,
    notes: notes,
    active: active,
  );

  @override
  Future<TuyaPlan> renew(int id, {DateTime? renewedOn, String? notes}) =>
      _repository.renewTuyaPlan(id, renewedOn: renewedOn, notes: notes);

  @override
  Future<void> delete(int id) => _repository.deleteTuyaPlan(id);
}

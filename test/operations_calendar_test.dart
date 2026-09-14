import 'package:ficon_power_frontend/domain/operations_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta IDs numéricos de planes Tuya', () {
    final plan = TuyaPlan.fromJson({
      'id': 7,
      'projectName': 'Ficon Puno',
      'planName': 'Plan gratuito',
      'nextRenewalOn': '2026-09-20',
      'renewalIntervalMonths': 6,
      'reminderDays': 30,
      'active': true,
    });

    expect(plan.id, 7);
    expect(plan.status(DateTime(2026, 9, 14)), 'DUE_SOON');
    expect(plan.daysUntilRenewal(DateTime(2026, 9, 14)), 6);
  });

  test('marca un plan vencido según la fecha local', () {
    final plan = TuyaPlan.fromJson({
      'id': 8,
      'projectName': 'Proyecto Tuya',
      'planName': 'IoT Core',
      'nextRenewalOn': '2026-09-10',
      'reminderDays': 15,
      'active': true,
    });

    expect(plan.status(DateTime(2026, 9, 14)), 'OVERDUE');
    expect(plan.daysUntilRenewal(DateTime(2026, 9, 14)), -4);
  });

  test('un incidente aparece en cada día que abarca', () {
    final entry = OperationsCalendarEntry.fromJson({
      'id': 'incident:1',
      'type': 'INCIDENT',
      'title': 'Corte · Medidor Puno',
      'date': '2026-09-12',
      'startAt': '2026-09-12T22:00:00-05:00',
      'endAt': '2026-09-14T08:00:00-05:00',
      'status': 'resolved',
      'deviceId': 'device-uuid',
    });

    expect(entry.occursOn(DateTime(2026, 9, 11)), isFalse);
    expect(entry.occursOn(DateTime(2026, 9, 13)), isTrue);
    expect(entry.occursOn(DateTime(2026, 9, 14)), isTrue);
    expect(entry.occursOn(DateTime(2026, 9, 15)), isFalse);
  });

  test('interpreta una renovación histórica completada', () {
    final entry = OperationsCalendarEntry.fromJson({
      'id': 'tuya-renewed:10',
      'type': 'TUYA_RENEWED',
      'title': 'Tuya renovado · Ficon Puno',
      'date': '2026-09-14',
      'status': 'COMPLETED',
      'tuyaPlanId': 7,
    });

    expect(entry.isCompletedRenewal, isTrue);
    expect(entry.tuyaPlanId, 7);
  });
}

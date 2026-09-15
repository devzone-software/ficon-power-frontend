import '../../domain/operations_calendar.dart';

abstract interface class GetOperationsCalendar {
  Future<OperationsCalendarData> call({
    required DateTime from,
    required DateTime to,
  });
}

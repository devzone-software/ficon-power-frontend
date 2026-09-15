import '../domain/operations_calendar.dart';
import '../ports/input/get_operations_calendar.dart';
import '../ports/output/operations_calendar_repository.dart';

class GetOperationsCalendarService implements GetOperationsCalendar {
  const GetOperationsCalendarService(this._repository);

  final OperationsCalendarRepository _repository;

  @override
  Future<OperationsCalendarData> call({
    required DateTime from,
    required DateTime to,
  }) async {
    final results = await Future.wait([
      _repository.fetchCalendarEntries(from: from, to: to),
      _repository.fetchTuyaPlans(),
    ]);
    return OperationsCalendarData(
      entries: results[0] as List<OperationsCalendarEntry>,
      plans: results[1] as List<TuyaPlan>,
    );
  }
}

import 'filter_matching.dart';

enum ColumnSortDirection { ascending, descending }

class ColumnFilterState {
  final Map<String, String> _textValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, ColumnSortDirection?> _sortValues = {};

  String text(String key) => _textValues[key] ?? '';
  DateTime? date(String key) => _dateValues[key];
  ColumnSortDirection? sort(String key) => _sortValues[key];
  List<String> ipSegments(String key) => [
    for (var index = 0; index < 4; index++) text('$key.$index'),
  ];

  void setText(String key, String value) => _textValues[key] = value;
  void setDate(String key, DateTime? value) => _dateValues[key] = value;
  void setSort(String key, ColumnSortDirection? value) =>
      _sortValues[key] = value;
  void setIpSegment(String key, int index, String value) {
    _textValues['$key.$index'] = value;
  }

  bool matchesText(String key, String? value) =>
      matchesTextFilter(value, text(key));
  bool matchesAnyText(String key, Iterable<String?> values) {
    final query = text(key);
    if (query.trim().isEmpty) return true;
    return values.any((value) => matchesTextFilter(value, query));
  }

  bool matchesChoice(String key, String? value) {
    final selected = normalizeFilterValue(text(key));
    if (selected.isEmpty) return true;
    return normalizeFilterValue(value ?? '') == selected;
  }

  bool matchesDate(String key, DateTime? value) =>
      matchesDateFilter(value, date(key));

  bool matchesIp(String key, String? value) {
    final filters = ipSegments(key).map(normalizeFilterValue).toList();
    if (filters.every((filter) => filter.isEmpty)) return true;
    final segments = (value ?? '').split('.');
    if (segments.length != 4) return false;
    for (var index = 0; index < filters.length; index++) {
      final filter = filters[index];
      if (filter.isNotEmpty && !segments[index].startsWith(filter)) {
        return false;
      }
    }
    return true;
  }

  List<T> sortedNumeric<T>(
    String key,
    Iterable<T> rows,
    num Function(T row) valueForRow,
  ) {
    final result = rows.toList();
    final direction = sort(key);
    if (direction == null) return result;
    result.sort((left, right) {
      final comparison = valueForRow(left).compareTo(valueForRow(right));
      return direction == ColumnSortDirection.ascending
          ? comparison
          : -comparison;
    });
    return result;
  }
}

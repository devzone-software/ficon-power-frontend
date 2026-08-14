import 'filter_matching.dart';

class ColumnFilterState {
  final Map<String, String> _textValues = {};
  final Map<String, DateTime?> _dateValues = {};

  String text(String key) => _textValues[key] ?? '';
  DateTime? date(String key) => _dateValues[key];
  List<String> ipSegments(String key) => [
    for (var index = 0; index < 4; index++) text('$key.$index'),
  ];

  void setText(String key, String value) => _textValues[key] = value;
  void setDate(String key, DateTime? value) => _dateValues[key] = value;
  void setIpSegment(String key, int index, String value) {
    _textValues['$key.$index'] = value;
  }

  bool matchesText(String key, String? value) =>
      matchesTextFilter(value, text(key));
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
}

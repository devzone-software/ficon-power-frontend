String normalizeFilterValue(String value) => value.trim().toLowerCase();

bool matchesTextFilter(String? value, String query) {
  final normalizedQuery = normalizeFilterValue(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeFilterValue(value ?? '').contains(normalizedQuery);
}

bool matchesDateFilter(DateTime? value, DateTime? selectedDate) {
  if (selectedDate == null) return true;
  if (value == null) return false;
  final localValue = value.toLocal();
  return localValue.year == selectedDate.year &&
      localValue.month == selectedDate.month &&
      localValue.day == selectedDate.day;
}

List<String> uniqueColumnOptions<T>(
  List<T> rows,
  String? Function(T row) valueForRow,
) {
  final byNormalizedValue = <String, String>{};
  for (final row in rows) {
    final cleanValue = valueForRow(row)?.trim();
    if (cleanValue == null || cleanValue.isEmpty || cleanValue == '—') {
      continue;
    }
    byNormalizedValue.putIfAbsent(
      normalizeFilterValue(cleanValue),
      () => cleanValue,
    );
  }
  return byNormalizedValue.values.toList()..sort(
    (a, b) => normalizeFilterValue(a).compareTo(normalizeFilterValue(b)),
  );
}

Iterable<String> rankedFilterMatches(List<String> options, String query) {
  final normalizedQuery = normalizeFilterValue(query);
  if (normalizedQuery.isEmpty) return options.take(30);

  final prefixMatches = <String>[];
  final start = lowerBoundByNormalized(options, normalizedQuery);
  for (
    var index = start;
    index < options.length && prefixMatches.length < 20;
    index++
  ) {
    final option = options[index];
    if (!normalizeFilterValue(option).startsWith(normalizedQuery)) break;
    prefixMatches.add(option);
  }

  final seen = prefixMatches.toSet();
  final containsMatches = <String>[];
  for (final option in options) {
    if (prefixMatches.length + containsMatches.length >= 30) break;
    if (seen.contains(option)) continue;
    if (normalizeFilterValue(option).contains(normalizedQuery)) {
      containsMatches.add(option);
    }
  }

  return [...prefixMatches, ...containsMatches];
}

int lowerBoundByNormalized(List<String> options, String query) {
  var low = 0;
  var high = options.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (normalizeFilterValue(options[middle]).compareTo(query) < 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

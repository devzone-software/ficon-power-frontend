/// Compact calendar labels without altering dates stored in the history.
String compactDailyChartLabel(String value) {
  final label = value.trim();
  final short = RegExp(r'^(\d{1,2})/(\d{1,2})$').firstMatch(label);
  if (short != null) {
    return '${short[1]!.padLeft(2, '0')}/${short[2]!.padLeft(2, '0')}';
  }
  final date = DateTime.tryParse(label);
  if (date == null) return label;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

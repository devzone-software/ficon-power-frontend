String peruLocalPhoneDigits(String value) {
  var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0051')) {
    digits = digits.substring(4);
  } else if (digits.length > 9 && digits.startsWith('51')) {
    digits = digits.substring(2);
  }
  return digits;
}

String? normalizePeruMobilePhone(String value) {
  final local = peruLocalPhoneDigits(value);
  return RegExp(r'^9[0-9]{8}$').hasMatch(local) ? '51$local' : null;
}

String formatPeruMobilePhone(String value, {bool includeCountryCode = true}) {
  final digits = peruLocalPhoneDigits(value);
  final visible = digits.length > 9 ? digits.substring(0, 9) : digits;
  final groups = <String>[];
  for (var index = 0; index < visible.length; index += 3) {
    final end = index + 3 < visible.length ? index + 3 : visible.length;
    groups.add(visible.substring(index, end));
  }
  final formatted = groups.join(' ');
  return includeCountryCode && formatted.isNotEmpty
      ? '+51 $formatted'
      : formatted;
}

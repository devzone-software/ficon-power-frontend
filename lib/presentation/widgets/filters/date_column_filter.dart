import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';

class DateColumnFilter extends StatelessWidget {
  const DateColumnFilter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 180,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Limpiar fecha',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.close),
                ),
        ),
        child: InkWell(
          onTap: () => _pickDate(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              value == null ? 'Cualquier fecha' : formatDateOnly(value!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value == null ? FiconColors.slate : FiconColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) onChanged(picked);
  }
}

String formatDateOnly(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';

class DateColumnFilter extends StatelessWidget {
  const DateColumnFilter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 180,
    this.wideOnMobile = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final double width;
  final bool wideOnMobile;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 720;
    final effectiveWidth = compact
        ? wideOnMobile
              ? screenWidth - 56
              : ((screenWidth - 64) / 2).clamp(132.0, width)
        : width;
    if (compact) {
      return Container(
        width: effectiveWidth,
        decoration: BoxDecoration(
          color: value == null ? Colors.white : FiconColors.logoBlue,
          border: Border.all(color: FiconColors.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _pickDate(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: value == null
                            ? FiconColors.logoBlue
                            : Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          value == null ? label : formatDateOnly(value!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: value == null
                                ? FiconColors.deepAlt
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: 'Limpiar fecha',
                onPressed: () => onChanged(null),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      width: effectiveWidth,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: compact,
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

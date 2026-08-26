import 'package:flutter/material.dart';

/// Lista horizontal de opciones existentes con selección única.
class OptionsChipFilter extends StatelessWidget {
  const OptionsChipFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final compact = MediaQuery.sizeOf(context).width < 720;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in options) ...[
                ChoiceChip(
                  label: Text(option),
                  selected: value == option,
                  showCheckmark: false,
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -3,
                  ),
                  onSelected: (selected) => onChanged(selected ? option : ''),
                ),
                if (option != options.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
    return compact
        ? SizedBox(width: MediaQuery.sizeOf(context).width - 56, child: content)
        : content;
  }
}

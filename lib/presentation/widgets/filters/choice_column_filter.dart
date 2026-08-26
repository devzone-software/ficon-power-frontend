import 'package:flutter/material.dart';

/// Filtro de selección única para valores cerrados como estados y roles.
///
/// Una segunda pulsación sobre la opción activa elimina el criterio. Nunca
/// permite seleccionar dos opciones de la misma columna simultáneamente.
class ChoiceColumnFilter extends StatelessWidget {
  const ChoiceColumnFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labels = const {},
  });

  final String label;
  final String value;
  final List<String> options;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final selected = value.isEmpty ? <String>{} : <String>{value};
    final control = SegmentedButton<String>(
      segments: [
        for (final option in options)
          ButtonSegment<String>(
            value: option,
            label: Text(
              labels[option] ?? option,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: selected,
      emptySelectionAllowed: true,
      multiSelectionEnabled: false,
      showSelectedIcon: !compact,
      expandedInsets: compact ? EdgeInsets.zero : null,
      style: compact
          ? const ButtonStyle(
              visualDensity: VisualDensity(horizontal: -3, vertical: -3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onSelectionChanged: (selection) =>
          onChanged(selection.isEmpty ? '' : selection.single),
    );

    return Semantics(
      container: true,
      label: 'Filtro $label',
      child: compact
          ? SizedBox(
              width: MediaQuery.sizeOf(context).width - 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  control,
                ],
              ),
            )
          : InputDecorator(
              decoration: InputDecoration(labelText: label),
              child: control,
            ),
    );
  }
}

import 'package:flutter/material.dart';

import 'column_filter_state.dart';

/// Orden exclusivo para columnas numéricas; una segunda pulsación lo elimina.
class SortColumnControl extends StatelessWidget {
  const SortColumnControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ColumnSortDirection? value;
  final ValueChanged<ColumnSortDirection?> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final selected = value == null ? <ColumnSortDirection>{} : {value!};
    final control = SegmentedButton<ColumnSortDirection>(
      segments: const [
        ButtonSegment(
          value: ColumnSortDirection.ascending,
          icon: Icon(Icons.arrow_upward),
          label: Text('Menor'),
        ),
        ButtonSegment(
          value: ColumnSortDirection.descending,
          icon: Icon(Icons.arrow_downward),
          label: Text('Mayor'),
        ),
      ],
      selected: selected,
      emptySelectionAllowed: true,
      multiSelectionEnabled: false,
      showSelectedIcon: false,
      expandedInsets: compact ? EdgeInsets.zero : null,
      style: compact
          ? const ButtonStyle(
              visualDensity: VisualDensity(horizontal: -2, vertical: -3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onSelectionChanged: (selection) =>
          onChanged(selection.isEmpty ? null : selection.single),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        control,
      ],
    );
    return compact
        ? SizedBox(width: MediaQuery.sizeOf(context).width - 56, child: content)
        : content;
  }
}

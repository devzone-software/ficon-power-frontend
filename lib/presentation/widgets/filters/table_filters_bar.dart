import 'package:flutter/material.dart';

class TableFiltersBar extends StatelessWidget {
  const TableFiltersBar({super.key, required this.filters, this.trailing});

  final List<Widget> filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty && trailing == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final content = Wrap(
          spacing: compact ? 8 : 12,
          runSpacing: compact ? 8 : 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [...filters, ?trailing],
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Card(
              child: ExpansionTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                leading: Icon(
                  Icons.tune_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Filtrar y ordenar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                initiallyExpanded: false,
                children: [
                  Align(alignment: Alignment.centerLeft, child: content),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Card(
            child: Padding(padding: const EdgeInsets.all(16), child: content),
          ),
        );
      },
    );
  }
}

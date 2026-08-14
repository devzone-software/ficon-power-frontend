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
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [...filters, ?trailing],
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Card(
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: const Icon(Icons.filter_alt_outlined),
                title: const Text('Filtros'),
                subtitle: Text('${filters.length} disponibles'),
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

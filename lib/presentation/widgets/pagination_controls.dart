import 'package:flutter/material.dart';

import '../../domain/paged_result.dart';
import '../theme/ficon_theme.dart';

class PaginationControls<T> extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.page,
    required this.onPageChanged,
  });

  final PagedResult<T> page;
  final ValueChanged<int> onPageChanged;

  int get _currentPage => page.page;
  int get _lastPage => page.totalPages <= 0 ? 0 : page.totalPages - 1;

  @override
  Widget build(BuildContext context) {
    if (page.totalItems == 0) return const SizedBox.shrink();
    final from = page.page * page.size + 1;
    final to = (from + page.items.length - 1).clamp(0, page.totalItems);
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 12, compact ? 12 : 24, 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $from-$to de ${page.totalItems}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FiconColors.slate,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PageButton(
                    label: '<<',
                    enabled: page.hasPrevious,
                    onTap: () => onPageChanged(0),
                  ),
                  _PageButton(
                    label: '<',
                    enabled: page.hasPrevious,
                    onTap: () => onPageChanged(_currentPage - 1),
                  ),
                  for (final number in visiblePageNumbers(page.page, page.totalPages))
                    _PageButton(
                      label: '${number + 1}',
                      selected: number == page.page,
                      onTap: () => onPageChanged(number),
                    ),
                  _PageButton(
                    label: '>',
                    enabled: page.hasNext,
                    onTap: () => onPageChanged(_currentPage + 1),
                  ),
                  _PageButton(
                    label: '>>',
                    enabled: page.hasNext,
                    onTap: () => onPageChanged(_lastPage),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<int> visiblePageNumbers(int currentPage, int totalPages) {
  if (totalPages <= 0) return const [];
  const maxVisible = 5;
  if (totalPages <= maxVisible) {
    return [for (var index = 0; index < totalPages; index++) index];
  }
  var start = currentPage - 2;
  var end = currentPage + 2;
  if (start < 0) {
    end += -start;
    start = 0;
  }
  if (end >= totalPages) {
    start -= end - totalPages + 1;
    end = totalPages - 1;
  }
  return [for (var index = start; index <= end; index++) index];
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    this.enabled = true,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? FiconColors.cyan : Colors.white;
    final foreground = selected ? Colors.white : FiconColors.ink;
    return OutlinedButton(
      onPressed: enabled || selected ? onTap : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(38, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(
          color: selected ? FiconColors.cyan : FiconColors.cardBorder,
        ),
      ),
      child: Text(label),
    );
  }
}

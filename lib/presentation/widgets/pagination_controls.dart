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
    final label = compact
        ? '$from-$to / ${page.totalItems}'
        : 'Mostrando $from-$to de ${page.totalItems}';

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 10, compact ? 12 : 24, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: FiconColors.cardBorderSoft),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: FiconColors.ink.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 9,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FiconColors.cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: FiconColors.cyan.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: FiconColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PageButton(
                          label: '«',
                          enabled: page.hasPrevious,
                          onTap: () => onPageChanged(0),
                        ),
                        _PageButton(
                          label: '‹',
                          enabled: page.hasPrevious,
                          onTap: () => onPageChanged(_currentPage - 1),
                        ),
                        for (final number
                            in visiblePageNumbers(page.page, page.totalPages))
                          _PageButton(
                            label: '${number + 1}',
                            selected: number == page.page,
                            onTap: () => onPageChanged(number),
                          ),
                        _PageButton(
                          label: '›',
                          enabled: page.hasNext,
                          onTap: () => onPageChanged(_currentPage + 1),
                        ),
                        _PageButton(
                          label: '»',
                          enabled: page.hasNext,
                          onTap: () => onPageChanged(_lastPage),
                        ),
                      ],
                    ),
                  ),
                ),
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
    final active = enabled || selected;
    final background = selected
        ? FiconColors.cyan
        : active
            ? FiconColors.cyan.withValues(alpha: 0.08)
            : FiconColors.cardBorderSoft.withValues(alpha: 0.35);
    final foreground = selected
        ? FiconColors.ink
        : active
            ? FiconColors.deepAlt
            : FiconColors.slate.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: OutlinedButton(
        onPressed: enabled || selected ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(34, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(
            color: selected
                ? FiconColors.cyan
                : FiconColors.cardBorder.withValues(
                    alpha: active ? 0.75 : 0.25,
                  ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

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
        ? '${page.page + 1}/${page.totalPages} · $from-$to'
        : 'Mostrando $from-$to de ${page.totalItems}';

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 24, 8, compact ? 10 : 24, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: compact
                ? FiconColors.cyan.withValues(alpha: 0.28)
                : FiconColors.cardBorderSoft,
          ),
          borderRadius: BorderRadius.circular(compact ? 14 : 12),
          boxShadow: [
            BoxShadow(
              color: FiconColors.ink.withValues(alpha: compact ? 0.10 : 0.04),
              blurRadius: compact ? 18 : 14,
              offset: Offset(0, compact ? 8 : 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: compact ? 96 : 220),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 7 : 6,
                ),
                decoration: BoxDecoration(
                  color: compact
                      ? FiconColors.cyan.withValues(alpha: 0.16)
                      : FiconColors.cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: FiconColors.cyan.withValues(
                      alpha: compact ? 0.36 : 0.22,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: FiconColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11.5 : null,
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 10),
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
                          compact: compact,
                        ),
                        _PageButton(
                          label: '‹',
                          enabled: page.hasPrevious,
                          onTap: () => onPageChanged(_currentPage - 1),
                          compact: compact,
                        ),
                        for (final number
                            in visiblePageNumbers(
                              page.page,
                              page.totalPages,
                              maxVisible: compact ? 3 : 5,
                            ))
                          _PageButton(
                            label: '${number + 1}',
                            selected: number == page.page,
                            onTap: () => onPageChanged(number),
                            compact: compact,
                          ),
                        _PageButton(
                          label: '›',
                          enabled: page.hasNext,
                          onTap: () => onPageChanged(_currentPage + 1),
                          compact: compact,
                        ),
                        _PageButton(
                          label: '»',
                          enabled: page.hasNext,
                          onTap: () => onPageChanged(_lastPage),
                          compact: compact,
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

List<int> visiblePageNumbers(
  int currentPage,
  int totalPages, {
  int maxVisible = 5,
}) {
  if (totalPages <= 0) return const [];
  if (totalPages <= maxVisible) {
    return [for (var index = 0; index < totalPages; index++) index];
  }
  final side = maxVisible ~/ 2;
  var start = currentPage - side;
  var end = start + maxVisible - 1;
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
    this.compact = false,
  });

  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = enabled || selected;
    final background = compact
        ? selected
            ? FiconColors.cyan
            : active
            ? FiconColors.cyan.withValues(alpha: 0.12)
            : FiconColors.cardBorderSoft.withValues(alpha: 0.50)
        : selected
        ? FiconColors.cyan
        : active
        ? FiconColors.cyan.withValues(alpha: 0.08)
        : FiconColors.cardBorderSoft.withValues(alpha: 0.35);
    final foreground = compact
        ? selected
            ? FiconColors.ink
            : active
            ? FiconColors.deepAlt
            : FiconColors.slate.withValues(alpha: 0.45)
        : selected
        ? FiconColors.ink
        : active
        ? FiconColors.deepAlt
        : FiconColors.slate.withValues(alpha: 0.45);
    return Padding(
      padding: EdgeInsets.only(left: compact ? 3 : 5),
      child: OutlinedButton(
        onPressed: enabled || selected ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: compact ? const Size(30, 36) : const Size(34, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(
            color: selected
                ? FiconColors.cyan
                : compact
                ? FiconColors.cyan.withValues(alpha: active ? 0.32 : 0.10)
                : FiconColors.cardBorder.withValues(
                    alpha: active ? 0.75 : 0.25,
                  ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 11 : 9),
          ),
          textStyle: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

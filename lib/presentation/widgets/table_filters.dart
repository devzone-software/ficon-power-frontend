import 'package:flutter/material.dart';

import '../theme/ficon_theme.dart';

String normalizeFilterValue(String value) => value.trim().toLowerCase();

bool matchesTextFilter(String? value, String query) {
  final normalizedQuery = normalizeFilterValue(query);
  if (normalizedQuery.isEmpty) return true;
  return normalizeFilterValue(value ?? '').contains(normalizedQuery);
}

bool matchesDateFilter(DateTime? value, DateTime? selectedDate) {
  if (selectedDate == null) return true;
  if (value == null) return false;
  final localValue = value.toLocal();
  return localValue.year == selectedDate.year &&
      localValue.month == selectedDate.month &&
      localValue.day == selectedDate.day;
}

List<String> uniqueColumnOptions<T>(
  List<T> rows,
  String? Function(T row) valueForRow,
) {
  final byNormalizedValue = <String, String>{};
  for (final row in rows) {
    final cleanValue = valueForRow(row)?.trim();
    if (cleanValue == null || cleanValue.isEmpty || cleanValue == '—') {
      continue;
    }
    byNormalizedValue.putIfAbsent(
      normalizeFilterValue(cleanValue),
      () => cleanValue,
    );
  }
  return byNormalizedValue.values.toList()..sort(
    (a, b) => normalizeFilterValue(a).compareTo(normalizeFilterValue(b)),
  );
}

class TableFiltersBar extends StatelessWidget {
  const TableFiltersBar({super.key, required this.filters, this.trailing});

  final List<Widget> filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty && trailing == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...filters, ?trailing],
          ),
        ),
      ),
    );
  }
}

class TextColumnFilter extends StatefulWidget {
  const TextColumnFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 220,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  State<TextColumnFilter> createState() => _TextColumnFilterState();
}

class _TextColumnFilterState extends State<TextColumnFilter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant TextColumnFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: RawAutocomplete<String>(
        textEditingController: _controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          return rankedFilterMatches(widget.options, textEditingValue.text);
        },
        onSelected: (selected) {
          _controller.text = selected;
          _controller.selection = TextSelection.collapsed(
            offset: selected.length,
          );
          widget.onChanged(selected);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: 'Filtrar',
                  prefixIcon: const Icon(Icons.filter_alt_outlined),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar filtro',
                          onPressed: () {
                            controller.clear();
                            widget.onChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: widget.onChanged,
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final visibleOptions = options.toList();
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 280,
                  maxWidth: widget.width,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: visibleOptions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = visibleOptions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        option,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 1),
            );
            if (picked != null) onChanged(picked);
          },
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
}

Iterable<String> rankedFilterMatches(List<String> options, String query) {
  final normalizedQuery = normalizeFilterValue(query);
  if (normalizedQuery.isEmpty) return options.take(30);

  final prefixMatches = <String>[];
  final start = lowerBoundByNormalized(options, normalizedQuery);
  for (
    var index = start;
    index < options.length && prefixMatches.length < 20;
    index++
  ) {
    final option = options[index];
    if (!normalizeFilterValue(option).startsWith(normalizedQuery)) break;
    prefixMatches.add(option);
  }

  final seen = prefixMatches.toSet();
  final containsMatches = <String>[];
  for (final option in options) {
    if (prefixMatches.length + containsMatches.length >= 30) break;
    if (seen.contains(option)) continue;
    if (normalizeFilterValue(option).contains(normalizedQuery)) {
      containsMatches.add(option);
    }
  }

  return [...prefixMatches, ...containsMatches];
}

int lowerBoundByNormalized(List<String> options, String query) {
  var low = 0;
  var high = options.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (normalizeFilterValue(options[middle]).compareTo(query) < 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

String formatDateOnly(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

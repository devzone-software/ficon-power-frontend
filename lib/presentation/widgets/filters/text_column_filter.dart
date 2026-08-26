import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';
import 'filter_matching.dart';

class TextColumnFilter extends StatefulWidget {
  const TextColumnFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 220,
    this.wideOnMobile = false,
    this.hint,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double width;
  final bool wideOnMobile;
  final String? hint;

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 720;
    final effectiveWidth = compact
        ? widget.wideOnMobile
              ? screenWidth - 56
              : ((screenWidth - 64) / 2).clamp(132.0, widget.width)
        : widget.width;
    return SizedBox(
      width: effectiveWidth,
      child: RawAutocomplete<String>(
        textEditingController: _controller,
        focusNode: _focusNode,
        optionsBuilder: (value) =>
            rankedFilterMatches(widget.options, value.text),
        onSelected: _select,
        fieldViewBuilder: (context, controller, focusNode, submit) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                isDense: compact,
                labelText: compact ? null : widget.label,
                hintText: compact ? widget.hint ?? widget.label : 'Filtrar',
                prefixIcon: const Icon(Icons.search),
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
              onSubmitted: (_) => submit(),
            ),
          );
        },
        optionsViewBuilder: (context, select, options) => _OptionsList(
          options: options.toList(),
          query: _controller.text,
          width: effectiveWidth,
          onSelected: select,
        ),
      ),
    );
  }

  void _select(String selected) {
    _controller
      ..text = selected
      ..selection = TextSelection.collapsed(offset: selected.length);
    widget.onChanged(selected);
  }
}

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    required this.options,
    required this.query,
    required this.width,
    required this.onSelected,
  });

  final List<String> options;
  final String query;
  final double width;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      shadowColor: FiconColors.deep.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FiconColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Text(
                  'Sugerencias',
                  style: TextStyle(
                    color: FiconColors.logoBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.search,
                        size: 18,
                        color: FiconColors.logoBlue,
                      ),
                      title: _HighlightedSuggestion(
                        option: option,
                        query: query,
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedSuggestion extends StatelessWidget {
  const _HighlightedSuggestion({required this.option, required this.query});

  final String option;
  final String query;

  @override
  Widget build(BuildContext context) {
    final normalizedOption = normalizeFilterValue(option);
    final normalizedQuery = normalizeFilterValue(query);
    final start = normalizedQuery.isEmpty
        ? -1
        : normalizedOption.indexOf(normalizedQuery);
    if (start < 0) {
      return Text(option, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final end = start + normalizedQuery.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: option.substring(0, start)),
          TextSpan(
            text: option.substring(start, end),
            style: const TextStyle(
              color: FiconColors.logoBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: option.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

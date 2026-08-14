import 'package:flutter/material.dart';

import 'filter_matching.dart';

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
              onSubmitted: (_) => submit(),
            ),
          );
        },
        optionsViewBuilder: (context, select, options) => _OptionsList(
          options: options.toList(),
          width: widget.width,
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
    required this.width,
    required this.onSelected,
  });

  final List<String> options;
  final double width;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 280, maxWidth: width),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = options[index];
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
  }
}

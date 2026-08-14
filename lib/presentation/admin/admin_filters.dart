part of '../pages/admin_page.dart';

class _SearchableTableFilter extends StatefulWidget {
  const _SearchableTableFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchableTableFilter> createState() => _SearchableTableFilterState();
}

class _SearchableTableFilterState extends State<_SearchableTableFilter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SearchableTableFilter oldWidget) {
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
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        return _rankedMatches(widget.options, textEditingValue.text);
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
                hintText: 'Escribe o selecciona un valor',
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
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
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
    );
  }
}

class _DateColumnFilter extends StatelessWidget {
  const _DateColumnFilter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
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
            value == null ? 'Cualquier fecha' : _formatDateOnly(value!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _IpColumnFilter extends StatefulWidget {
  const _IpColumnFilter({
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final void Function(int index, String value) onChanged;

  @override
  State<_IpColumnFilter> createState() => _IpColumnFilterState();
}

class _IpColumnFilterState extends State<_IpColumnFilter> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (var index = 0; index < 4; index++)
        TextEditingController(
          text: index < widget.values.length ? widget.values[index] : '',
        ),
    ];
  }

  @override
  void didUpdateWidget(covariant _IpColumnFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var index = 0; index < _controllers.length; index++) {
      final value = index < widget.values.length ? widget.values[index] : '';
      if (_controllers[index].text != value) {
        _controllers[index].text = value;
        _controllers[index].selection = TextSelection.collapsed(
          offset: value.length,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lan_outlined),
        suffixIcon: _controllers.every((controller) => controller.text.isEmpty)
            ? null
            : IconButton(
                tooltip: 'Limpiar IP',
                onPressed: () {
                  for (var index = 0; index < _controllers.length; index++) {
                    _controllers[index].clear();
                    widget.onChanged(index, '');
                  }
                },
                icon: const Icon(Icons.close),
              ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _controllers.length; index++) ...[
            Expanded(
              child: TextField(
                controller: _controllers[index],
                maxLength: 3,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: index == 0 ? '198' : '',
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  final cleanValue = value.replaceAll(RegExp('[^0-9]'), '');
                  final nextValue = cleanValue.length > 3
                      ? cleanValue.substring(0, 3)
                      : cleanValue;
                  if (nextValue != value) {
                    _controllers[index].text = nextValue;
                    _controllers[index].selection = TextSelection.collapsed(
                      offset: nextValue.length,
                    );
                  }
                  widget.onChanged(index, nextValue);
                },
              ),
            ),
            if (index < _controllers.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Iterable<String> _rankedMatches(List<String> options, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return options.take(30);

  final prefixMatches = <String>[];
  final start = _lowerBoundByNormalized(options, normalizedQuery);
  for (
    var index = start;
    index < options.length && prefixMatches.length < 20;
    index++
  ) {
    final option = options[index];
    if (!_normalize(option).startsWith(normalizedQuery)) break;
    prefixMatches.add(option);
  }

  final seen = prefixMatches.toSet();
  final containsMatches = <String>[];
  for (final option in options) {
    if (prefixMatches.length + containsMatches.length >= 30) break;
    if (seen.contains(option)) continue;
    if (_normalize(option).contains(normalizedQuery)) {
      containsMatches.add(option);
    }
  }

  return [...prefixMatches, ...containsMatches];
}

int _lowerBoundByNormalized(List<String> options, String query) {
  var low = 0;
  var high = options.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (_normalize(options[middle]).compareTo(query) < 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low;
}

String _normalize(String value) => value.trim().toLowerCase();

String _formatDateOnly(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

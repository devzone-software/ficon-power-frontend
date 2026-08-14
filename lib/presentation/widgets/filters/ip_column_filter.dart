import 'package:flutter/material.dart';

class IpColumnFilter extends StatefulWidget {
  const IpColumnFilter({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.width = 330,
  });

  final String label;
  final List<String> values;
  final void Function(int index, String value) onChanged;
  final double width;

  @override
  State<IpColumnFilter> createState() => _IpColumnFilterState();
}

class _IpColumnFilterState extends State<IpColumnFilter> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (var index = 0; index < 4; index++)
        TextEditingController(text: _valueAt(index)),
    ];
  }

  @override
  void didUpdateWidget(covariant IpColumnFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var index = 0; index < _controllers.length; index++) {
      final value = _valueAt(index);
      if (_controllers[index].text != value) {
        _controllers[index]
          ..text = value
          ..selection = TextSelection.collapsed(offset: value.length);
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

  String _valueAt(int index) =>
      index < widget.values.length ? widget.values[index] : '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.lan_outlined),
          suffixIcon: _controllers.every((item) => item.text.isEmpty)
              ? null
              : IconButton(
                  tooltip: 'Limpiar IP',
                  onPressed: _clear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < _controllers.length; index++) ...[
              Expanded(child: _segmentField(index)),
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
      ),
    );
  }

  Widget _segmentField(int index) {
    return TextField(
      controller: _controllers[index],
      maxLength: 3,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        counterText: '',
        hintText: index == 0 ? '198' : '',
        isDense: true,
        border: InputBorder.none,
      ),
      onChanged: (value) => _setSegment(index, value),
    );
  }

  void _setSegment(int index, String value) {
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    final next = digits.length > 3 ? digits.substring(0, 3) : digits;
    if (next != value) {
      _controllers[index]
        ..text = next
        ..selection = TextSelection.collapsed(offset: next.length);
    }
    widget.onChanged(index, next);
  }

  void _clear() {
    for (var index = 0; index < _controllers.length; index++) {
      _controllers[index].clear();
      widget.onChanged(index, '');
    }
  }
}

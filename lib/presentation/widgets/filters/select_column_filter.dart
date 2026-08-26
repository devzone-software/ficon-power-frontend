import 'package:flutter/material.dart';

/// Desplegable compacto para catálogos finitos obtenidos de la tabla.
class SelectColumnFilter extends StatelessWidget {
  const SelectColumnFilter({
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 720;
    final effectiveWidth = compact
        ? ((screenWidth - 64) / 2).clamp(132.0, width)
        : width;
    final availableOptions = {if (value.isNotEmpty) value, ...options}.toList();

    return SizedBox(
      width: effectiveWidth,
      child: DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: compact,
          labelText: label,
          prefixIcon: const Icon(Icons.tune_outlined),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar filtro',
                  onPressed: () => onChanged(''),
                  icon: const Icon(Icons.close),
                ),
        ),
        hint: const Text('Todos'),
        items: [
          for (final option in availableOptions)
            DropdownMenuItem<String>(
              value: option,
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (selected) => onChanged(selected ?? ''),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../application/mobile_data_export.dart';
import '../../theme/ficon_theme.dart';

class MobileExportSheet extends StatefulWidget {
  const MobileExportSheet({super.key});

  @override
  State<MobileExportSheet> createState() => _MobileExportSheetState();
}

class _MobileExportSheetState extends State<MobileExportSheet> {
  MobileExportDataset dataset = MobileExportDataset.devices;
  MobileExportFormat format = MobileExportFormat.csv;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exportar datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Elige el conjunto y el formato del archivo.'),
            const SizedBox(height: 20),
            const _FieldLabel('Datos'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in MobileExportDataset.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: dataset == option,
                    onSelected: (_) => setState(() => dataset = option),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Formato'),
            const SizedBox(height: 8),
            SegmentedButton<MobileExportFormat>(
              segments: const [
                ButtonSegment(
                  value: MobileExportFormat.csv,
                  label: Text('CSV'),
                  icon: Icon(Icons.table_rows_outlined),
                ),
                ButtonSegment(
                  value: MobileExportFormat.xlsx,
                  label: Text('XLSX'),
                  icon: Icon(Icons.grid_on_outlined),
                ),
              ],
              selected: {format},
              onSelectionChanged: (value) =>
                  setState(() => format = value.single),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  MobileExportRequest(dataset: dataset, format: format),
                ),
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Generar y compartir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: FiconColors.deepAlt,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.7,
    ),
  );
}

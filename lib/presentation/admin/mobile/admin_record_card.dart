import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';

class AdminRecordCard extends StatelessWidget {
  const AdminRecordCard({
    super.key,
    required this.title,
    required this.fields,
    this.subtitle,
    this.status,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? status;
  final Map<String, String> fields;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(color: FiconColors.slate),
                      ),
                  ],
                ),
              ),
              ?status,
            ],
          ),
          const Divider(height: 22),
          for (final field in fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      field.key,
                      style: const TextStyle(color: FiconColors.slate),
                    ),
                  ),
                  Expanded(
                    child: Text(field.value, textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          if (action != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: action),
          ],
        ],
      ),
    ),
  );
}

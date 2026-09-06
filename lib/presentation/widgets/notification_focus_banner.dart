import 'package:flutter/material.dart';

class NotificationFocusBanner extends StatelessWidget {
  const NotificationFocusBanner({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(label),
      trailing: TextButton(onPressed: onClear, child: const Text('Ver todos')),
    ),
  );
}

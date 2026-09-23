import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _supportEmail = Uri(
  scheme: 'mailto',
  path: 'soporte@ficon.pe',
);

Future<void> showLoginSupportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.support_agent),
      title: const Text('Acceso al sistema'),
      content: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Contacte con '),
          InkWell(
            onTap: () => launchUrl(
              _supportEmail,
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              'soporte',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text('.'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

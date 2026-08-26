import 'package:flutter/material.dart';

Future<void> showLoginSupportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.support_agent),
      title: const Text('Acceso al sistema'),
      content: const Text(
        'La recuperación y creación de cuentas se administra internamente. '
        'Contacta al responsable de FICON Power para verificar el usuario, '
        'restablecer la contraseña o desbloquear el acceso.',
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

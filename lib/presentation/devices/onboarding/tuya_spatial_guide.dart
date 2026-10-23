import 'package:flutter/material.dart';
import '../../../offline/local_console.dart';

class TuyaSpatialGuidePage extends StatelessWidget {
  const TuyaSpatialGuidePage({
    super.key,
    this.projectQrData = '',
    this.account = '',
    this.password = '',
  });
  final String projectQrData;
  final String account;
  final String password;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guía de dispositivos')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final step in [
          (
            '1. Agregar un dispositivo',
            'Abre Operaciones con el icono de conexión eléctrica en la barra superior. Selecciona Agregar dispositivo, escribe el nombre y elige el distrito.',
          ),
          (
            '2. Consultar la ficha',
            'En Dispositivos, pulsa la tarjeta del medidor. La ficha incluye estadísticas, incidentes y eventos. Puedes editar su nombre y distrito si tienes permisos.',
          ),
          (
            '3. Registrar un corte',
            'En Operaciones, pulsa Registrar corte. Se abre un incidente y se actualizan el estado del dispositivo, las notificaciones y las estadísticas.',
          ),
          (
            '4. Atender el incidente',
            'En el resumen o en la ficha del dispositivo, selecciona el incidente y confirma su atención. El incidente continúa abierto hasta el retorno de energía.',
          ),
          (
            '5. Restaurar la energía',
            'Regresa a Operaciones y pulsa Restaurar energía. El incidente se resuelve y su duración queda registrada en el historial.',
          ),
          (
            '6. Usuarios y WhatsApp',
            'El superadministrador administra usuarios y números opcionales. Las pruebas y alertas se registran como mensajes simulados: no se envían mensajes reales.',
          ),
          (
            '7. Exportar y conservar',
            'Usa Exportar para guardar los dispositivos, incidentes o eventos en CSV o Excel. Los datos de trabajo se conservan al cerrar la aplicación.',
          ),
        ])
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.$1, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(step.$2),
                ],
              ),
            ),
          ),
        if (LocalConsole.session.user?.canEditDevices == true)
          FilledButton.icon(
            onPressed: () => LocalConsole.open(context),
            icon: const Icon(Icons.electrical_services),
            label: const Text('Abrir operaciones'),
          ),
      ],
    ),
  );
}

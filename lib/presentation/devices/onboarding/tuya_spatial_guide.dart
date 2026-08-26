import 'package:flutter/material.dart';

import '../../theme/ficon_theme.dart';

class TuyaSpatialGuidePage extends StatelessWidget {
  const TuyaSpatialGuidePage({super.key});

  static const steps = [
    (
      Icons.qr_code_scanner,
      'Abrir Tuya Spatial',
      'Inicia Tuya Spatial y escanea el código QR autorizado del proyecto.',
    ),
    (
      Icons.login,
      'Iniciar sesión',
      'Ingresa la cuenta y contraseña habilitadas para la instalación.',
    ),
    (
      Icons.location_city_outlined,
      'Seleccionar el espacio',
      'Elige la sede o crea el espacio que identifica el cuarto de redes.',
    ),
    (
      Icons.devices_other_outlined,
      'Abrir Dispositivos',
      'Entra a Devices y selecciona la acción para agregar un equipo cercano.',
    ),
    (
      Icons.electric_meter_outlined,
      'Elegir el medidor',
      'Selecciona WIFI Energy Meter cuando aparezca en la búsqueda.',
    ),
    (
      Icons.wifi,
      'Configurar la red',
      'Selecciona la red Wi-Fi de la sede e ingresa su contraseña.',
    ),
    (
      Icons.bolt,
      'Mantener el equipo energizado',
      'No cierres Tuya Spatial ni retires la energía durante el emparejamiento.',
    ),
    (
      Icons.verified_outlined,
      'Confirmar el registro',
      'Finaliza el asistente y verifica que el medidor aparezca en la lista.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar un medidor')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FiconColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'El alta se realiza en Tuya Spatial. El dashboard sincroniza el '
              'medidor después del registro y no reemplaza ese proceso.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < steps.length; index++)
            _GuideStep(index: index + 1, step: steps[index]),
          const SizedBox(height: 8),
          const Text(
            'Si el dispositivo no aparece, comprueba energía, proximidad, Wi-Fi '
            'compatible y permisos del espacio antes de repetir el enlace.',
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.index, required this.step});

  final int index;
  final (IconData, String, String) step;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: FiconColors.logoBlue.withValues(alpha: 0.12),
          child: Icon(step.$1, color: FiconColors.logoBlue),
        ),
        title: Text('$index. ${step.$2}'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(step.$3),
        ),
      ),
    );
  }
}

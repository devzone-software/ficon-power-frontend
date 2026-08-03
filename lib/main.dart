import 'package:flutter/material.dart';

import 'adapters/http/ficon_monitoring_repository.dart';
import 'presentation/pages/devices_page.dart';
import 'usecase/get_devices_service.dart';

void main() {
  // Ensamblaje de la arquitectura hexagonal: el adaptador HTTP
  // implementa el puerto de salida y el caso de uso expone el
  // puerto de entrada que consume la presentación.
  final repository = FiconMonitoringRepository();
  final getDevices = GetDevicesService(repository);
  runApp(FiconPowerApp(getDevices: getDevices));
}

class FiconPowerApp extends StatelessWidget {
  const FiconPowerApp({super.key, required this.getDevices});

  final GetDevicesService getDevices;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FICON Power',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: DevicesPage(getDevices: getDevices),
    );
  }
}

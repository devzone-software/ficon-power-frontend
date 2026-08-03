import '../../domain/monitoring_overview.dart';

/// Puerto de entrada: caso de uso para obtener la vista general
/// de monitoreo que alimenta el dashboard.
abstract interface class GetMonitoringOverview {
  Future<MonitoringOverview> call();
}

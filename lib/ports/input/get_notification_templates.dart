import '../../domain/notification_template.dart';

/// Puerto de entrada: caso de uso para listar la configuración
/// de plantillas Meta de WhatsApp.
abstract interface class GetNotificationTemplates {
  Future<List<NotificationTemplate>> call();
}

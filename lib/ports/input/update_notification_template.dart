import '../../domain/notification_template.dart';

/// Puerto de entrada: caso de uso para actualizar el mensaje
/// de una plantilla de notificación.
abstract interface class UpdateNotificationTemplate {
  Future<NotificationTemplate> call(String eventType, String body);
}

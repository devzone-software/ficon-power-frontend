import '../../domain/notification_template.dart';

/// Puerto de salida: acceso a las plantillas de notificación del backend.
/// Espejo de `NotificationTemplateRepository` del backend.
abstract interface class NotificationTemplateRepository {
  Future<List<NotificationTemplate>> fetchNotificationTemplates();

  Future<NotificationTemplate> updateNotificationTemplate(
    String eventType,
    String body,
  );
}

import '../../domain/notification_template.dart';

/// Puerto de entrada: caso de uso para listar las plantillas
/// de mensajes de notificación editables.
abstract interface class GetNotificationTemplates {
  Future<List<NotificationTemplate>> call();
}

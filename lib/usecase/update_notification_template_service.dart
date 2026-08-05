import '../../domain/notification_template.dart';
import '../../ports/input/update_notification_template.dart';
import '../../ports/output/notification_template_repository.dart';

/// Implementación del caso de uso [UpdateNotificationTemplate].
class UpdateNotificationTemplateService implements UpdateNotificationTemplate {
  const UpdateNotificationTemplateService(this._repository);

  final NotificationTemplateRepository _repository;

  @override
  Future<NotificationTemplate> call(String eventType, String body) =>
      _repository.updateNotificationTemplate(eventType, body);
}

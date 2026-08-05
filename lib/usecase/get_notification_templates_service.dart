import '../../domain/notification_template.dart';
import '../../ports/input/get_notification_templates.dart';
import '../../ports/output/notification_template_repository.dart';

/// Implementación del caso de uso [GetNotificationTemplates].
class GetNotificationTemplatesService implements GetNotificationTemplates {
  const GetNotificationTemplatesService(this._repository);

  final NotificationTemplateRepository _repository;

  @override
  Future<List<NotificationTemplate>> call() =>
      _repository.fetchNotificationTemplates();
}

/// Plantilla de mensaje de notificación. Espejo del recurso
/// `/api/notification-templates` del backend.
class NotificationTemplate {
  const NotificationTemplate({
    required this.eventType,
    this.metaTemplateName,
    this.metaTemplateLanguage,
    this.metaTemplateParams = const [],
    this.availableVariables = const [],
  });

  /// `power_outage` o `power_restored`.
  final String eventType;
  final String? metaTemplateName;
  final String? metaTemplateLanguage;
  final List<String> metaTemplateParams;
  final List<NotificationTemplateVariable> availableVariables;

  bool get usesMetaTemplate =>
      (metaTemplateName != null && metaTemplateName!.isNotEmpty);

  String get summary {
    if (!usesMetaTemplate) {
      return 'Sin plantilla Meta configurada: no se enviará WhatsApp para este evento.';
    }
    final params = metaTemplateParams
        .map(labelForVariable)
        .where((value) => value.isNotEmpty)
        .join(', ');
    return 'Plantilla Meta activa: $metaTemplateName · '
        '${metaTemplateLanguage ?? ''}'
        '${params.isEmpty ? '' : ' · Variables: $params'}';
  }

  /// Nombre amigable del evento para mostrar en la UI.
  String get displayName => switch (eventType) {
        'power_outage' => 'Corte de energía',
        'power_restored' => 'Retorno de energía',
        _ => eventType,
      };

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      eventType: json['eventType'] as String? ?? '',
      metaTemplateName: json['metaTemplateName'] as String?,
      metaTemplateLanguage: json['metaTemplateLanguage'] as String?,
      metaTemplateParams:
          (json['metaTemplateParams'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      availableVariables:
          (json['availableVariables'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NotificationTemplateVariable.fromJson)
          .toList(),
    );
  }

  String labelForVariable(String key) {
    for (final variable in availableVariables) {
      if (variable.key == key && variable.label.isNotEmpty) {
        return variable.label;
      }
    }
    return _fallbackLabel(key);
  }

  static String _fallbackLabel(String key) => switch (key) {
        'dispositivo' => 'Nombre del dispositivo',
        'fechaCorte' => 'Fecha del corte',
        'fechaRetorno' => 'Fecha de retorno',
        _ => key,
      };
}

class NotificationTemplateVariable {
  const NotificationTemplateVariable({
    required this.key,
    required this.label,
    required this.token,
    required this.requiredForText,
    required this.requiredForMetaTemplate,
    required this.description,
  });

  final String key;
  final String label;
  final String token;
  final bool requiredForText;
  final bool requiredForMetaTemplate;
  final String description;

  factory NotificationTemplateVariable.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateVariable(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      token: json['token'] as String? ?? '',
      requiredForText: json['requiredForText'] as bool? ?? false,
      requiredForMetaTemplate:
          json['requiredForMetaTemplate'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }
}

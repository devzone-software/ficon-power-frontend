/// Plantilla de mensaje de notificación. Espejo del recurso
/// `/api/notification-templates` del backend.
class NotificationTemplate {
  const NotificationTemplate({required this.eventType, required this.body});

  /// `power_outage` o `power_restored`.
  final String eventType;
  final String body;

  /// Nombre amigable del evento para mostrar en la UI.
  String get displayName => switch (eventType) {
        'power_outage' => 'Corte de energía',
        'power_restored' => 'Retorno de energía',
        _ => eventType,
      };

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      eventType: json['eventType'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

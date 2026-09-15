class WhatsAppRecipient {
  const WhatsAppRecipient({
    required this.id,
    required this.label,
    required this.phone,
    required this.siteId,
    required this.siteName,
    required this.notifyOutage,
    required this.notifyRestored,
    required this.active,
    required this.lastTestStatus,
    required this.lastTestMessage,
    required this.lastTestAt,
  });

  final String id;
  final String label;
  final String phone;
  final String? siteId;
  final String? siteName;
  final bool notifyOutage;
  final bool notifyRestored;
  final bool active;
  final String? lastTestStatus;
  final String? lastTestMessage;
  final DateTime? lastTestAt;

  bool get global => siteId == null;

  factory WhatsAppRecipient.fromJson(Map<String, dynamic> json) =>
      WhatsAppRecipient(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        siteId: json['siteId'] as String?,
        siteName: json['siteName'] as String?,
        notifyOutage: json['notifyOutage'] as bool? ?? true,
        notifyRestored: json['notifyRestored'] as bool? ?? true,
        active: json['active'] as bool? ?? true,
        lastTestStatus: json['lastTestStatus'] as String?,
        lastTestMessage: json['lastTestMessage'] as String?,
        lastTestAt: DateTime.tryParse(json['lastTestAt'] as String? ?? ''),
      );
}

class WhatsAppTestResult {
  const WhatsAppTestResult({
    required this.configured,
    required this.accepted,
    required this.message,
  });

  final bool configured;
  final bool accepted;
  final String message;

  factory WhatsAppTestResult.fromJson(Map<String, dynamic> json) =>
      WhatsAppTestResult(
        configured: json['configured'] as bool? ?? false,
        accepted: json['accepted'] as bool? ?? false,
        message: json['message'] as String? ?? 'Respuesta no disponible.',
      );
}

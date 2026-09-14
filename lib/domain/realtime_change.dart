class RealtimeChange {
  const RealtimeChange({
    required this.id,
    required this.eventType,
    required this.entityType,
    this.entityId,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  factory RealtimeChange.fromJson(Map<String, dynamic> json) => RealtimeChange(
    id: json['id'].toString(),
    eventType: json['eventType'] as String? ?? '',
    entityType: json['entityType'] as String? ?? '',
    entityId: json['entityId']?.toString(),
    payload: (json['payload'] as Map<dynamic, dynamic>? ?? const {})
        .cast<String, dynamic>(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}

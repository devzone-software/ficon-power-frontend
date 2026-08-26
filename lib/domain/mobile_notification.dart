class MobileNotification {
  const MobileNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.eventType,
    required this.status,
    required this.createdAt,
    required this.readAt,
    required this.unread,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, String> data;
  final String eventType;
  final String status;
  final DateTime? createdAt;
  final DateTime? readAt;
  final bool unread;

  factory MobileNotification.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as Map<dynamic, dynamic>? ?? const {});
    return MobileNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notificación',
      body: json['body'] as String? ?? '',
      data: rawData.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      eventType: json['eventType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
      unread: json['unread'] as bool? ?? false,
    );
  }

  MobileNotification markRead() => MobileNotification(
    id: id,
    title: title,
    body: body,
    data: data,
    eventType: eventType,
    status: status == 'SENT' ? 'READ' : status,
    createdAt: createdAt,
    readAt: readAt ?? DateTime.now(),
    unread: false,
  );
}

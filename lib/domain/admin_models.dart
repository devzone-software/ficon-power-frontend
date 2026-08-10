class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    required this.active,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;
  final bool active;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      displayName: json['displayName'] as String? ?? '',
      active: json['active'] as bool? ?? false,
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorUsername,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.ipAddress,
    required this.userAgent,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String? actorUsername;
  final String? actorRole;
  final String action;
  final String entityType;
  final String? entityId;
  final String? ipAddress;
  final String? userAgent;
  final String? metadata;
  final DateTime? createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String? ?? '',
      actorUsername: json['actorUsername'] as String?,
      actorRole: json['actorRole'] as String?,
      action: json['action'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      metadata: json['metadata'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class LoginAttempt {
  const LoginAttempt({
    required this.id,
    required this.username,
    required this.ipAddress,
    required this.userAgent,
    required this.success,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String? username;
  final String? ipAddress;
  final String? userAgent;
  final bool success;
  final String? reason;
  final DateTime? createdAt;

  factory LoginAttempt.fromJson(Map<String, dynamic> json) {
    return LoginAttempt(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      success: json['success'] as bool? ?? false,
      reason: json['reason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class AdminSession {
  const AdminSession({
    required this.id,
    required this.username,
    required this.role,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
  });

  final String id;
  final String username;
  final String role;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  bool get active => revokedAt == null && (expiresAt?.isAfter(DateTime.now()) ?? false);

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      revokedAt: DateTime.tryParse(json['revokedAt'] as String? ?? ''),
    );
  }
}

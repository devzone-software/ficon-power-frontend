class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.email,
    this.whatsappPhone,
    this.whatsappEnabled = false,
    required this.active,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;
  final String? email;
  final String? whatsappPhone;
  final bool whatsappEnabled;
  final bool active;

  bool get hasWhatsapp => whatsappPhone?.isNotEmpty == true;

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      whatsappPhone: json['whatsappPhone'] as String?,
      whatsappEnabled: json['whatsappEnabled'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }
}

class UserWhatsAppDelivery {
  const UserWhatsAppDelivery({
    required this.id,
    required this.eventType,
    required this.templateName,
    required this.status,
    required this.errorMessage,
    required this.sentAt,
    required this.createdAt,
  });

  final int id;
  final String? eventType;
  final String? templateName;
  final String status;
  final String? errorMessage;
  final DateTime? sentAt;
  final DateTime? createdAt;

  factory UserWhatsAppDelivery.fromJson(Map<String, dynamic> json) =>
      UserWhatsAppDelivery(
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventType: json['eventType'] as String?,
        templateName: json['templateName'] as String?,
        status: json['status'] as String? ?? 'FAILED',
        errorMessage: json['errorMessage'] as String?,
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
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

  bool get active =>
      revokedAt == null && (expiresAt?.isAfter(DateTime.now()) ?? false);

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

class BlockedLoginUser {
  const BlockedLoginUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.ipAddress,
    required this.userAgent,
    required this.failedAttempts,
    required this.reason,
    required this.blockedAt,
    required this.expiresAt,
    required this.unblockedAt,
    required this.unblockedByUsername,
    required this.unblockReason,
    required this.active,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? ipAddress;
  final String? userAgent;
  final int failedAttempts;
  final String reason;
  final DateTime? blockedAt;
  final DateTime? expiresAt;
  final DateTime? unblockedAt;
  final String? unblockedByUsername;
  final String? unblockReason;
  final bool active;

  factory BlockedLoginUser.fromJson(Map<String, dynamic> json) {
    return BlockedLoginUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      unblockedAt: DateTime.tryParse(json['unblockedAt'] as String? ?? ''),
      unblockedByUsername: json['unblockedByUsername'] as String?,
      unblockReason: json['unblockReason'] as String?,
      active: json['active'] as bool? ?? false,
    );
  }
}

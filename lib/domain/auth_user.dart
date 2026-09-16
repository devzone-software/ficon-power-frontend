class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.email,
    this.whatsappPhone,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;
  final String? email;
  final String? whatsappPhone;

  bool get canEditMessages => role == 'ADMIN' || role == 'SUPERADMIN';
  bool get canEditDevices => role == 'ADMIN' || role == 'SUPERADMIN';
  bool get canAccessAdmin => role == 'ADMIN' || role == 'SUPERADMIN';
  bool get canManageUsers => role == 'SUPERADMIN';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      whatsappPhone: json['whatsappPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'displayName': displayName,
      'email': email,
      'whatsappPhone': whatsappPhone,
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
  });

  final String id;
  final String username;
  final String role;
  final String displayName;

  bool get canEditMessages => role == 'ADMIN' || role == 'SUPERADMIN';
  bool get canEditDevices => role == 'ADMIN' || role == 'SUPERADMIN';
  bool get canManageUsers => role == 'SUPERADMIN';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'USER',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

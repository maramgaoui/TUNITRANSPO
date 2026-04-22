enum SessionRole { guest, user, admin }

class SessionResult {
  const SessionResult({
    required this.role,
    this.adminRole,
    this.adminMatricule,
    this.adminName,
  });

  final SessionRole role;
  final String? adminRole;
  final String? adminMatricule;
  final String? adminName;

  bool get isAdmin => role == SessionRole.admin;
  bool get isGuest => role == SessionRole.guest;
}

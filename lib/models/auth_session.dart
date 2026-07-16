class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });

  final int id;
  final String fullName;
  final String phoneNumber;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '');
    if (id == null) throw const FormatException('Login user id is invalid.');
    return AuthUser(
      id: id,
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.nextScreen,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final String nextScreen;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final access = json['access']?.toString().trim() ?? '';
    final refresh = json['refresh']?.toString().trim() ?? '';
    final userJson = json['user'];
    if (access.isEmpty ||
        refresh.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const FormatException('Login response is incomplete.');
    }
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      user: AuthUser.fromJson(userJson),
      nextScreen: json['next_screen']?.toString() ?? '',
    );
  }
}

class AuthSession {
  final String token;
  final String? userId;
  final String? email;

  const AuthSession({
    required this.token,
    this.userId,
    this.email,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? json['access_token'] as String? ?? '',
      userId: json['userId'] as String? ?? (json['user'] as Map<String, dynamic>?)?['id'] as String?,
      email: json['email'] as String? ?? (json['user'] as Map<String, dynamic>?)?['email'] as String?,
    );
  }
}

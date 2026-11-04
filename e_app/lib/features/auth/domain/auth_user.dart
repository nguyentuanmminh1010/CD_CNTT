enum AuthProviderType { local, google, facebook }

AuthProviderType authProviderFromString(String value) {
  switch (value) {
    case 'GOOGLE':
      return AuthProviderType.google;
    case 'FACEBOOK':
      return AuthProviderType.facebook;
    default:
      return AuthProviderType.local;
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.authProvider,
    this.avatar,
    this.isAdmin = false,
    this.surveyDone = true,
  });

  final String id;
  final String? email;
  final String displayName;
  final AuthProviderType authProvider;

  /// Ảnh đại diện dạng data URL (base64), null nếu chưa đặt.
  final String? avatar;

  /// Có quyền quản trị nội dung (email nằm trong `app.admin-emails` ở backend).
  final bool isAdmin;

  /// Đã hoàn thành khảo sát cá nhân hoá (backend lưu `startMode` ở bước cuối). Tài khoản mới tạo bằng
  /// Google/Facebook hoặc người bỏ dở khảo sát có giá trị false → app đưa tới màn khảo sát.
  final bool surveyDone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      authProvider: authProviderFromString(json['authProvider'] as String? ?? 'LOCAL'),
      avatar: json['avatar'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      surveyDone: json['startMode'] != null,
    );
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

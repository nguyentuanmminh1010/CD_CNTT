import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final GraphQLClient _client;

  static const _userFields = r'''
    id
    email
    displayName
    avatar
    isAdmin
    authProvider
    startMode
  ''';

  Future<AuthResult> register(String email, String password, String displayName) {
    return _mutateAuth(
      document: '''
        mutation Register(\$email: String!, \$password: String!, \$displayName: String!) {
          register(email: \$email, password: \$password, displayName: \$displayName) {
            token
            user { $_userFields }
          }
        }
      ''',
      variables: {'email': email, 'password': password, 'displayName': displayName},
      operationField: 'register',
    );
  }

  Future<AuthResult> login(String email, String password) {
    return _mutateAuth(
      document: '''
        mutation Login(\$email: String!, \$password: String!) {
          login(email: \$email, password: \$password) {
            token
            user { $_userFields }
          }
        }
      ''',
      variables: {'email': email, 'password': password},
      operationField: 'login',
    );
  }

  Future<AuthResult> loginWithGoogle(String idToken) {
    return _mutateAuth(
      document: '''
        mutation LoginWithGoogle(\$idToken: String!) {
          loginWithGoogle(idToken: \$idToken) {
            token
            user { $_userFields }
          }
        }
      ''',
      variables: {'idToken': idToken},
      operationField: 'loginWithGoogle',
    );
  }

  Future<AuthResult> loginWithFacebook(String accessToken) {
    return _mutateAuth(
      document: '''
        mutation LoginWithFacebook(\$accessToken: String!) {
          loginWithFacebook(accessToken: \$accessToken) {
            token
            user { $_userFields }
          }
        }
      ''',
      variables: {'accessToken': accessToken},
      operationField: 'loginWithFacebook',
    );
  }

  /// Ghi dữ liệu khảo sát cá nhân hoá (hoặc tên hiển thị) lên `User` đang đăng
  /// nhập. Tham số nào null thì backend giữ nguyên giá trị cũ.
  Future<AuthUser> updateProfile({
    String? displayName,
    DateTime? dob,
    String? gender,
    String? learningPurpose,
    int? dailyMinutes,
    String? startMode,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql('''
          mutation UpdateProfile(
            \$displayName: String
            \$dob: String
            \$gender: Gender
            \$learningPurpose: LearningPurpose
            \$dailyMinutes: Int
            \$startMode: StartMode
          ) {
            updateProfile(
              displayName: \$displayName
              dob: \$dob
              gender: \$gender
              learningPurpose: \$learningPurpose
              dailyMinutes: \$dailyMinutes
              startMode: \$startMode
            ) { $_userFields }
          }
        '''),
        variables: {
          'displayName': displayName,
          'dob': dob == null ? null : _formatIsoDate(dob),
          'gender': gender,
          'learningPurpose': learningPurpose,
          'dailyMinutes': dailyMinutes,
          'startMode': startMode,
        },
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return AuthUser.fromJson(result.data!['updateProfile'] as Map<String, dynamic>);
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Yêu cầu mã đặt lại mật khẩu (backend luôn trả thành công — không lộ email có tồn tại hay không).
  Future<void> requestPasswordReset(String email) async {
    final result = await _client.mutate(MutationOptions(
      document: gql('mutation(\$e: String!) { requestPasswordReset(email: \$e) }'),
      variables: {'e': email},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
  }

  /// Đặt mật khẩu mới bằng mã 6 số nhận được.
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(
        'mutation(\$e: String!, \$c: String!, \$p: String!) { resetPassword(email: \$e, code: \$c, newPassword: \$p) }',
      ),
      variables: {'e': email, 'c': code, 'p': newPassword},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
  }

  /// Đặt ảnh đại diện (data URL); null/rỗng để xoá.
  Future<AuthUser> updateAvatar(String? avatar) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql('''
          mutation UpdateAvatar(\$avatar: String) {
            updateAvatar(avatar: \$avatar) { $_userFields }
          }
        '''),
        variables: {'avatar': avatar},
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return AuthUser.fromJson(result.data!['updateAvatar'] as Map<String, dynamic>);
  }

  /// Trả về user hiện tại theo token đã lưu, hoặc null nếu chưa đăng nhập /
  /// token đã hết hạn.
  Future<AuthUser?> me() async {
    final result = await _client.query(
      QueryOptions(
        document: gql('{ me { $_userFields } }'),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final me = result.data?['me'] as Map<String, dynamic>?;
    return me == null ? null : AuthUser.fromJson(me);
  }

  Future<AuthResult> _mutateAuth({
    required String document,
    required Map<String, dynamic> variables,
    required String operationField,
  }) async {
    final result = await _client.mutate(
      MutationOptions(document: gql(document), variables: variables),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final payload = result.data![operationField] as Map<String, dynamic>;
    return AuthResult(
      token: payload['token'] as String,
      user: AuthUser.fromJson(payload['user'] as Map<String, dynamic>),
    );
  }
}

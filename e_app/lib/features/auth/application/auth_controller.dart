import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(graphQLClientProvider));
});

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final token = await ref.read(tokenStorageProvider).readToken();
    if (token == null) return null;

    try {
      final user = await ref.read(authRepositoryProvider).me();
      if (user == null) {
        await ref.read(tokenStorageProvider).clearToken();
      }
      return user;
    } catch (_) {
      // Token hỏng/hết hạn hoặc backend không phản hồi — coi như chưa đăng nhập,
      // không chặn app khởi động vì lỗi mạng tạm thời.
      return null;
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    final result = await ref.read(authRepositoryProvider).register(email, password, displayName);
    await _persistSession(result);
  }

  Future<void> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(email, password);
    await _persistSession(result);
  }

  Future<void> loginWithGoogle(String idToken) async {
    final result = await ref.read(authRepositoryProvider).loginWithGoogle(idToken);
    await _persistSession(result);
  }

  Future<void> loginWithFacebook(String accessToken) async {
    final result = await ref.read(authRepositoryProvider).loginWithFacebook(accessToken);
    await _persistSession(result);
  }

  Future<void> updateProfile({
    String? displayName,
    DateTime? dob,
    String? gender,
    String? learningPurpose,
    int? dailyMinutes,
    String? startMode,
  }) async {
    final user = await ref.read(authRepositoryProvider).updateProfile(
          displayName: displayName,
          dob: dob,
          gender: gender,
          learningPurpose: learningPurpose,
          dailyMinutes: dailyMinutes,
          startMode: startMode,
        );
    state = AsyncData(user);
  }

  Future<void> updateAvatar(String? avatar) async {
    final user = await ref.read(authRepositoryProvider).updateAvatar(avatar);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearToken();
    state = const AsyncData(null);
  }

  Future<void> _persistSession(AuthResult result) async {
    await ref.read(tokenStorageProvider).saveToken(result.token);
    state = AsyncData(result.user);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

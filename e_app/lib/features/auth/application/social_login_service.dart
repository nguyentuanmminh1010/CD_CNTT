import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/social_auth_config.dart';

/// Lỗi khi đăng nhập Google/Facebook — message tiếng Việt, hiển thị được
/// thẳng cho người dùng (SnackBar).
class SocialAuthException implements Exception {
  const SocialAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _googleInitialized = false;
bool _facebookInitialized = false;

/// Trả về Google ID token để gửi lên backend (`loginWithGoogle`).
/// Ném [SocialAuthException] nếu chưa cấu hình Client ID hoặc người dùng huỷ.
Future<String> signInWithGoogleIdToken() async {
  if (googleSignInClientId.isEmpty) {
    throw const SocialAuthException(
      'Đăng nhập Google chưa được cấu hình cho ứng dụng này.',
    );
  }
  try {
    if (!_googleInitialized) {
      // Web dùng `clientId`; Android (Credential Manager) cần `serverClientId` = Client ID loại Web
      // để nhận được ID token cho backend (đồng thời phải có OAuth client loại Android khớp
      // package + SHA-1 trong cùng dự án Google Cloud).
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? googleSignInClientId : null,
        serverClientId: kIsWeb ? null : googleSignInClientId,
      );
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const SocialAuthException('Không lấy được token từ Google.');
    }
    return idToken;
  } on GoogleSignInException catch (e) {
    debugPrint('Google Sign-In: code=${e.code} description=${e.description}');
    if (e.code == GoogleSignInExceptionCode.canceled) {
      throw const SocialAuthException('Bạn đã huỷ đăng nhập Google.');
    }
    if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        e.code == GoogleSignInExceptionCode.providerConfigurationError) {
      debugPrint('Google Sign-In chưa cấu hình đúng: ${e.description}');
      throw const SocialAuthException(
        'Đăng nhập Google chưa được cấu hình cho bản Android này (cần OAuth client Android khớp package và SHA-1).',
      );
    }
    throw SocialAuthException('Đăng nhập Google thất bại: ${e.description ?? e.code}');
  } on SocialAuthException {
    rethrow;
  } catch (e) {
    debugPrint('Google Sign-In lỗi: $e');
    throw const SocialAuthException('Không đăng nhập được bằng Google. Vui lòng thử lại.');
  }
}

/// Trả về Facebook access token để gửi lên backend (`loginWithFacebook`).
/// Ném [SocialAuthException] nếu chưa cấu hình App ID hoặc người dùng huỷ.
Future<String> signInWithFacebookAccessToken() async {
  if (facebookAppId.isEmpty) {
    throw const SocialAuthException(
      'Đăng nhập Facebook chưa được cấu hình cho ứng dụng này.',
    );
  }
  if (kIsWeb && Uri.base.scheme != 'https') {
    // Facebook JS SDK chặn FB.login trên trang http:// (kể cả localhost).
    throw const SocialAuthException(
      'Facebook chỉ cho đăng nhập trên trang HTTPS hoặc ứng dụng điện thoại. Hãy dùng app Android/iOS hoặc đăng nhập bằng Email/Google.',
    );
  }
  if (!_facebookInitialized) {
    // Cần thiết trên Web (nạp Facebook JS SDK); vô hại trên Android/iOS.
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: facebookAppId,
      cookie: true,
      xfbml: true,
      version: 'v19.0',
    );
    _facebookInitialized = true;
  }

  final LoginResult result;
  try {
    result = await FacebookAuth.instance.login(permissions: facebookLoginPermissions);
  } catch (e) {
    debugPrint('Facebook Login lỗi: $e');
    throw const SocialAuthException(
      'Không đăng nhập được bằng Facebook (kiểm tra cấu hình ứng dụng Facebook: key hash, client token). Vui lòng thử lại.',
    );
  }
  switch (result.status) {
    case LoginStatus.success:
      final token = result.accessToken?.token;
      if (token == null) {
        throw const SocialAuthException('Không lấy được token từ Facebook.');
      }
      return token;
    case LoginStatus.cancelled:
      throw const SocialAuthException('Bạn đã huỷ đăng nhập Facebook.');
    case LoginStatus.operationInProgress:
      throw const SocialAuthException('Đang xử lý đăng nhập Facebook, vui lòng đợi.');
    case LoginStatus.failed:
      debugPrint('Facebook Login failed: ${result.message}');
      throw SocialAuthException(
        result.message == null
            ? 'Đăng nhập Facebook thất bại.'
            : 'Đăng nhập Facebook thất bại: ${result.message}',
      );
  }
}

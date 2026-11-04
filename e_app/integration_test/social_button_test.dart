// Bấm nút Google/Facebook ở màn đăng nhập trên thiết bị thật rồi chờ 45 giây để người kiểm thử
// (hoặc adb screencap) quan sát giao diện hệ thống hiện ra. Chạy:
//   flutter drive -d <id> --dart-define=SOCIAL=google|facebook --driver=test_driver/integration_test.dart \
//     --target=integration_test/social_button_test.dart
import 'package:e_app/core/network/token_storage.dart';
import 'package:e_app/core/router/app_router.dart';
import 'package:e_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryTokenStorage extends TokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

const _which = String.fromEnvironment('SOCIAL', defaultValue: 'google');

/// Số giây chờ sau khi bấm (để người kiểm thử kịp bấm "Tiếp tục" trong hộp thoại Google/Facebook).
const _waitSeconds = int.fromEnvironment('WAIT', defaultValue: 45);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bấm nút $_which', (tester) async {
    Future<void> pumpFor(double seconds) async {
      final end = DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_MemoryTokenStorage())],
        child: const MyApp(),
      ),
    );
    await pumpFor(4);
    final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container.read(appRouterProvider).go('/login');
    await pumpFor(2.5);

    final icon = find.byIcon(_which == 'facebook' ? Icons.facebook_rounded : Icons.g_mobiledata_rounded);
    expect(icon, findsOneWidget);
    await tester.tap(icon);
    debugPrint('SOCIAL_WAIT_START $_which');
    await pumpFor(_waitSeconds.toDouble());
    // Sau khi chờ: in ra thông báo lỗi (SnackBar) nếu có để biết kết quả.
    final snack = find.byType(SnackBar);
    if (snack.evaluate().isNotEmpty) {
      final texts = find.descendant(of: snack, matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data);
      debugPrint('SOCIAL_SNACKBAR ${texts.join(' | ')}');
    } else {
      debugPrint('SOCIAL_SNACKBAR (none)');
    }
    debugPrint('SOCIAL_HOME ${find.text('Trang chủ').evaluate().isNotEmpty} SURVEY ${find.text('Chúng tôi có thể gọi bạn là gì?').evaluate().isNotEmpty} LOGIN ${find.text('Đăng nhập').evaluate().isNotEmpty}');
    debugPrint('SOCIAL_DONE');
  });
}

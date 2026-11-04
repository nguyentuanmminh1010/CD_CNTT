// Đặt lại lựa chọn giao diện đang lưu trên thiết bị (mặc định: tối). Chạy khi một bài kiểm thử khác
// đã đổi chế độ giao diện: flutter drive ... --dart-define=THEME=dark|light|system
import 'package:e_app/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _theme = String.fromEnvironment('THEME', defaultValue: 'dark');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Đặt chế độ giao diện $_theme', (tester) async {
    final mode = switch (_theme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeControllerProvider); // khởi tạo: bắt đầu đọc giá trị đã lưu
    await Future<void>.delayed(const Duration(seconds: 2)); // đợi đọc xong, tránh ghi đè giá trị vừa đặt
    await container.read(themeControllerProvider.notifier).setMode(mode);
    await Future<void>.delayed(const Duration(seconds: 1));
    // Kiểm tra giá trị ĐÃ LƯU bằng một container mới
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    fresh.read(themeControllerProvider);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(fresh.read(themeControllerProvider), mode);
    debugPrint('THEME_SET $_theme');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Brightness _platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Chế độ "theo hệ thống": đổi theo cài đặt sáng/tối của thiết bị ngay khi người dùng đổi.
  @override
  void didChangePlatformBrightness() {
    setState(() => _platform = WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeControllerProvider);
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => _platform == Brightness.dark,
    };
    // Bảng màu phải được chọn TRƯỚC khi dựng cây UI; đổi chế độ thì \`key\` mới buộc dựng lại toàn bộ
    // (các màn dùng \`AppColors\` ở khắp nơi, kể cả widget const).
    AppColors.setDark(dark);
    return MaterialApp.router(
      key: ValueKey(dark),
      title: 'Learn E',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}


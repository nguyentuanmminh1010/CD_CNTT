import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Lưu ảnh chụp từ `binding.takeScreenshot` vào `build/android_shots/`.
Future<void> main() async {
  await Directory('build/android_shots').create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('build/android_shots/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}

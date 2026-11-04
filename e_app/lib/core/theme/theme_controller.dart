import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeKey = 'theme_mode';

/// Lựa chọn giao diện của người dùng: theo hệ thống, sáng hoặc tối. Lưu cục bộ trên thiết bị
/// (cùng kho `flutter_secure_storage` với token) để lần sau mở app vẫn giữ.
class ThemeController extends Notifier<ThemeMode> {
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _themeKey);
      final mode = switch (saved) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      if (mode != state) state = mode;
    } catch (e) {
      debugPrint('Không đọc được cài đặt giao diện: $e');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (e) {
      debugPrint('Không lưu được cài đặt giao diện: $e');
    }
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

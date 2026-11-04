import 'package:flutter/material.dart';

/// Design tokens rút ra từ bộ UI Kit "Learn E" (xem CLAUDE.md > Design System).
///
/// Có 2 bảng màu: sáng (mặc định) và tối. Các màu **nền/chữ/viền** là getter đọc bảng màu hiện tại
/// ([setDark]) nên không dùng được trong ngữ cảnh `const`; các màu nhấn (xanh lá, đỏ, vàng, xanh dương,
/// tím) giống nhau ở cả hai chế độ nên vẫn là `const`. Gốc ứng dụng ([MyApp]) gọi [setDark] trước khi dựng
/// và dựng lại toàn bộ cây khi đổi chế độ.
abstract final class AppColors {
  static bool _dark = false;

  /// Đang dùng bảng màu tối.
  static bool get isDark => _dark;

  /// Chọn bảng màu; gọi trước khi dựng UI (xem `MyApp`).
  static void setDark(bool value) => _dark = value;

  // ---- Màu nhấn: giống nhau ở cả hai chế độ ----
  static const Color primary = Color(0xFF2FAE60);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2FAE60);
  static const Color error = Color(0xFFE5484D);
  static const Color accentYellow = Color(0xFFF5A623);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF9B8AFB);

  // ---- Màu theo chế độ sáng/tối ----
  static Color get primaryDark => _dark ? const Color(0xFF6FD9A0) : const Color(0xFF1F7A4D);
  static Color get primaryLight => _dark ? const Color(0xFF1D3A2B) : const Color(0xFFE6F7ED);

  static Color get textPrimary => _dark ? const Color(0xFFEDF1EE) : const Color(0xFF1E2A25);
  static Color get textSecondary => _dark ? const Color(0xFF9AA5A0) : const Color(0xFF6B7280);

  static Color get background => _dark ? const Color(0xFF121614) : const Color(0xFFFFFFFF);
  static Color get surface => _dark ? const Color(0xFF1C2220) : const Color(0xFFF5F6F8);
  static Color get border => _dark ? const Color(0xFF2E3733) : const Color(0xFFE5E7EB);

  /// Màn làm bài (theo bộ UI Kit "Learn E"): xanh dương của ô đáp án đang chọn / nút nghe.
  static const Color quizBlue = Color(0xFF1A8CF0);

  /// Nền ô đáp án / chip từ / ô chữ cái chưa chọn (xanh dương rất nhạt).
  static Color get quizTile => _dark ? const Color(0xFF1C2B3B) : const Color(0xFFE3F1FC);

  /// Nút chính bị tắt (Kiểm tra khi chưa chọn đáp án).
  static Color get disabledFill => _dark ? const Color(0xFF2E3733) : const Color(0xFFD5D7DC);

  /// Nền thẻ Flashcard (mint/teal nhạt; tối hơn ở chế độ tối) — theo ảnh Inspiration `Flashcards.png`.
  static Color get flashcardTeal => _dark ? const Color(0xFF285F52) : const Color(0xFFAEE0D3);
  static Color get flashcardTealDark => _dark ? const Color(0xFF1D4A40) : const Color(0xFF7FC7B4);
}

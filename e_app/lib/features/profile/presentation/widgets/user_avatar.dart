import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ảnh đại diện tròn: hiện ảnh người dùng đã đặt (data URL base64 lưu ở backend)
/// hoặc icon người mặc định nếu chưa đặt/ảnh lỗi.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.avatar, this.radius = 24});

  final String? avatar;
  final double radius;

  Uint8List? _bytes() {
    final a = avatar;
    if (a == null || !a.startsWith('data:image/')) return null;
    final comma = a.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(a.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Icon(Icons.person, color: AppColors.primary, size: radius * 1.05)
          : null,
    );
  }
}

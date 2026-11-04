import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Hình minh hoạ của một mục: [url] là URL http(s) hoặc data URL base64 (ảnh người dùng chọn).
/// Lỗi/URL hỏng thì ẩn đi (không làm vỡ thẻ).
class ItemImage extends StatelessWidget {
  const ItemImage({super.key, required this.url, this.height = 120, this.radius = 14});

  final String url;
  final double height;
  final double radius;

  static Uint8List? _decode(String url) {
    if (!url.startsWith('data:image/')) return null;
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(url.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(url);
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, height: height, fit: BoxFit.cover, errorBuilder: _fallback);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      image = Image.network(url, height: height, fit: BoxFit.cover, errorBuilder: _fallback);
    } else {
      return const SizedBox.shrink();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) => Container(
        height: height,
        width: height,
        color: AppColors.surface,
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
      );
}

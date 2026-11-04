import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Giấy chứng nhận hoàn thành một khoá học (hiện ở tab "Thành tựu" của Hồ sơ).
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.courseTitle,
    required this.userName,
    this.issuedAt,
    this.width = 240,
  });

  final String courseTitle;
  final String userName;

  /// Ngày hoàn thành lần đầu (ngày cấp).
  final DateTime? issuedAt;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF3A3220) : const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentYellow, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.accentYellow, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Giấy chứng nhận',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text('đã hoàn thành khoá học',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(courseTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark)),
          if (issuedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Cấp ngày ${issuedAt!.day.toString().padLeft(2, '0')}/${issuedAt!.month.toString().padLeft(2, '0')}/${issuedAt!.year}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

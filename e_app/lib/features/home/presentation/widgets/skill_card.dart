import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  /// `null` để card hiện trạng thái tắt (không bấm được) — dùng cho kỹ năng chưa có bài tập thật.
  final VoidCallback? onTap;
  /// Hiện badge "Sắp ra mắt" + làm mờ card — không đổi `onTap` (đã `null` từ
  /// nơi gọi), chỉ là gợi ý hiển thị.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? AppColors.textSecondary : color;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        hoverColor: effectiveColor.withValues(alpha: 0.08),
        splashColor: effectiveColor.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveColor, size: 19),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: locked ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
              // Luôn chừa 1 dòng phụ (kể cả card không khoá) để 4 card thẳng hàng;
              // card khoá chỉ thêm badge vào dòng này.
              const SizedBox(height: 2),
              SizedBox(
                height: 14,
                child: locked
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Sắp ra mắt',
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

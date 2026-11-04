import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attempt.dart';

/// Một dòng trong lịch sử bài kiểm tra: icon loại bài, tên, ngày giờ, % điểm.
class AttemptTile extends StatelessWidget {
  const AttemptTile({super.key, required this.attempt});

  final Attempt attempt;

  Color get _scoreColor {
    if (attempt.scorePercent >= 75) return AppColors.success;
    if (attempt.scorePercent >= 40) return AppColors.accentYellow;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/attempt/${attempt.id}', extra: attempt),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(padding: const EdgeInsets.all(12), child: _content()),
      ),
    );
  }

  Widget _content() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(attempt.type.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attempt.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${attempt.type.label} · ${attempt.dateLabel}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${attempt.scorePercent}%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _scoreColor,
              ),
            ),
            Text(
              '${attempt.correctCount}/${attempt.totalQuestions} câu',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

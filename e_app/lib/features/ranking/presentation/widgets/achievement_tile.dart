import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ranking_models.dart';

IconData _iconFor(String code) => switch (code) {
      'STREAK' => Icons.local_fire_department_rounded,
      'MASTERED' => Icons.military_tech_rounded,
      'ATTEMPTS' => Icons.rocket_launch_rounded,
      'PERFECT' => Icons.star_rounded,
      'COURSES' => Icons.school_rounded,
      _ => Icons.emoji_events_rounded,
    };

/// Màu huy hiệu riêng cho từng loại thành tựu (khoá = `Achievement.code`).
const _badgeColors = {
  'STREAK': Color(0xFFEF6C00),
  'MASTERED': AppColors.primary,
  'ATTEMPTS': AppColors.accentBlue,
  'PERFECT': AppColors.accentYellow,
  'COURSES': AppColors.accentPurple,
};

/// Một thành tựu nhiều bậc ("Bậc 1 trên 4") kèm thanh tiến độ tới mốc kế tiếp.
class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final badgeColor = _badgeColors[a.code] ?? AppColors.accentYellow;
    final color = a.unlocked ? badgeColor : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('Bậc ${a.tier} trên ${a.maxTier}',
                    style: TextStyle(
                        color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(a.description,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                if (a.maxed)
                  const Text('Đã đạt bậc cao nhất',
                      style: TextStyle(
                          color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12))
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('${a.current}/${a.nextTarget}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: a.unlocked ? 0.9 : 0.25),
                    width: a.unlocked ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(_iconFor(a.code), color: color, size: 28),
              ),
              if (a.unlocked)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('${a.tier}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

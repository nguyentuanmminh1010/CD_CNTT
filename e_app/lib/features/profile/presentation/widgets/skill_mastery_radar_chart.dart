import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../skills/domain/skill_mastery.dart';
import '../../../skills/domain/skill_type.dart';

/// Radar chart % câu đúng theo từng kỹ năng (Đọc/Viết/Nghe/Nói) — dữ liệu
/// thật từ `skillMasteryProvider`. Nghe/Nói chưa có bài tập thật (cần package
/// audio/mic mới, chưa được duyệt) nên trục của 2 kỹ năng này giữ ở 0% cho
/// tới khi có dữ liệu — không phải lỗi hiển thị.
class SkillMasteryRadarChart extends StatelessWidget {
  const SkillMasteryRadarChart({super.key, required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty || skills.every((s) => s.totalAttempts == 0)) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Chưa có dữ liệu luyện tập để hiển thị.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          radarBorderData: BorderSide(color: AppColors.border),
          gridBorderData: BorderSide(color: AppColors.border, width: 1),
          radarBackgroundColor: Colors.transparent,
          titlePositionPercentageOffset: 0.18,
          getTitle: (index, angle) {
            final s = skills[index];
            return RadarChartTitle(text: s.skill.label);
          },
          titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.accentBlue.withValues(alpha: 0.25),
              borderColor: AppColors.accentBlue,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: skills.map((s) => RadarEntry(value: s.ratio * 100)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../progress/domain/activity_models.dart';

/// Radar chart tỉ lệ đã thuộc theo từng mảng nội dung (Vocabulary/Grammar/
/// Sentence) — dữ liệu thật từ `masteryByCategoryProvider`, không phải số tĩnh.
class SkillRadarChart extends StatelessWidget {
  const SkillRadarChart({super.key, required this.categories});

  final List<CategoryMastery> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || categories.every((c) => c.totalItems == 0)) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Chưa có dữ liệu tiến độ để hiển thị.',
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
            final c = categories[index];
            return RadarChartTitle(text: c.label);
          },
          titleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.accentPurple.withValues(alpha: 0.25),
              borderColor: AppColors.accentPurple,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: categories
                  .map((c) => RadarEntry(value: c.ratio * 100))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

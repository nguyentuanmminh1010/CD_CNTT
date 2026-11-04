import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../progress/domain/activity_models.dart';

/// Biểu đồ tròn: số mục ĐÃ THUỘC chia theo mảng nội dung (Từ vựng / Ngữ pháp / Mẫu câu).
class MasteryPieChart extends StatelessWidget {
  const MasteryPieChart({super.key, required this.categories});

  final List<CategoryMastery> categories;

  static const _colors = {
    'VOCABULARY': AppColors.primary,
    'GRAMMAR': AppColors.accentBlue,
    'SENTENCE': AppColors.accentPurple,
  };

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (a, c) => a + c.masteredItems);
    if (total == 0) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('Chưa có mục nào đã thuộc để hiển thị.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (final c in categories)
                  if (c.masteredItems > 0)
                    PieChartSectionData(
                      value: c.masteredItems.toDouble(),
                      color: _colors[c.category] ?? AppColors.textSecondary,
                      radius: 38,
                      title: '${(c.masteredItems / total * 100).round()}%',
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colors[c.category] ?? AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.label,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                      Text('${c.masteredItems}/${c.totalItems}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

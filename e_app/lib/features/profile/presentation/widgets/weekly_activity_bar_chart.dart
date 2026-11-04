import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../progress/domain/activity_models.dart';

/// Biểu đồ cột: số câu đã làm mỗi ngày trong 7 ngày gần nhất (hôm nay ở ngoài cùng bên phải).
class WeeklyActivityBarChart extends StatelessWidget {
  const WeeklyActivityBarChart({super.key, required this.days, DateTime? today})
      : _today = today;

  final List<ActivityDay> days;
  final DateTime? _today;

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final now = _today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDate = <DateTime, int>{
      for (final d in days) DateTime(d.date.year, d.date.month, d.date.day): d.itemsCompleted,
    };
    // 7 ngày, cũ → mới
    final series = [
      for (var i = 6; i >= 0; i--)
        (day: today.subtract(Duration(days: i)), count: byDate[today.subtract(Duration(days: i))] ?? 0),
    ];
    final maxCount = series.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final maxY = (maxCount < 5 ? 5 : maxCount * 1.25).toDouble();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => Text(
                  v.round().toString(),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= series.length) return const SizedBox.shrink();
                  final isToday = i == series.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[series[i].day.weekday - 1],
                      style: TextStyle(
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${rod.toY.round()} câu',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: series[i].count.toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    color: i == series.length - 1 ? AppColors.primary : AppColors.accentBlue,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

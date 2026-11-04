import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_models.dart';

const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Chuỗi ngày học + lịch hoạt động 4 tuần gần nhất (dữ liệu thật từ `myActivity`) — trước là tab
/// "Tiến độ" riêng, nay nằm trong phân đoạn "Tiến trình" của Hồ sơ.
class ActivityOverview extends StatelessWidget {
  const ActivityOverview({super.key, required this.activity});

  final ActivitySummary activity;

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final activeDates = activity.recentDays.map((d) => _dateKey(d.date)).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Lưới bắt đầu từ thứ Hai để cột khớp nhãn T2..CN.
    final start = today.subtract(Duration(days: 21 + (today.weekday - 1)));
    final days = List.generate(28, (i) => start.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MiniStat(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.error,
              value: '${activity.currentStreak}',
              label: 'Ngày liên tiếp',
            ),
            const SizedBox(width: 10),
            _MiniStat(
              icon: Icons.event_available_rounded,
              color: AppColors.primary,
              value: '${activity.totalActiveDays}',
              label: 'Ngày đã học',
            ),
            const SizedBox(width: 10),
            _MiniStat(
              icon: Icons.task_alt_rounded,
              color: AppColors.accentBlue,
              value: '${activity.totalItemsCompleted}',
              label: 'Câu đã làm',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lịch hoạt động', style: Theme.of(context).textTheme.titleMedium),
                  Text('4 tuần gần nhất',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            )),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final day in days)
                    _DayCell(
                      day: day,
                      active: activeDates.contains(_dateKey(day)),
                      isToday: day == today,
                      future: day.isAfter(today),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.currentStreak > 0
                          ? 'Bạn đang giữ chuỗi ${activity.currentStreak} ngày — học thêm hôm nay để không đứt chuỗi!'
                          : 'Làm một bài bất kỳ hôm nay để bắt đầu chuỗi ngày học.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.active,
    required this.isToday,
    required this.future,
  });

  final DateTime day;
  final bool active;
  final bool isToday;
  final bool future;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday
              ? AppColors.primary
              : (active ? Colors.transparent : AppColors.border),
          width: isToday ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: active
              ? Colors.white
              : AppColors.textSecondary.withValues(alpha: future ? 0.35 : 1),
        ),
      ),
    );
  }
}

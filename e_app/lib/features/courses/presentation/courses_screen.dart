import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';
import '../application/course_providers.dart';
import '../domain/course.dart';

/// Danh sách khoá học ("Chọn mục tiêu" ở `Home.png`) — mỗi thẻ hiện tiến độ
/// thật nếu đã đăng ký, bấm vào mở chi tiết lộ trình Level → Unit.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Chọn mục tiêu'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không tải được danh sách khoá học.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(coursesProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (courses) => RefreshIndicator(
                onRefresh: () async => ref.refresh(coursesProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text(
                      'Lựa chọn mục tiêu phù hợp với bạn, SUMO sẽ giúp bạn đạt được mục tiêu đó!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 16),
                    for (final course in courses) ...[
                      CourseCard(
                        course: course,
                        onTap: () async {
                          await context.push('/courses/${course.id}');
                          ref.invalidate(coursesProvider);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap, this.width});

  final Course course;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          hoverColor: AppColors.primary.withValues(alpha: 0.06),
          splashColor: AppColors.primary.withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(topicIconFor(course.icon), color: AppColors.primary),
                    ),
                    const Spacer(),
                    if (course.completed)
                      const _Badge(label: 'Hoàn thành', color: AppColors.success)
                    else if (course.certified)
                      // Đã có chứng chỉ nhưng khoá vừa có thêm nội dung chưa học.
                      const _Badge(label: 'Có bài mới', color: AppColors.accentYellow)
                    else if (course.enrolled)
                      const _Badge(label: 'Đang học', color: AppColors.accentBlue),
                  ],
                ),
                const SizedBox(height: 12),
                Text(course.title,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  course.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '${course.unitCount} bài học · ${course.totalItems} câu hỏi',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (course.enrolled) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.completedUnits}/${course.unitCount} bài · ${(course.progress * 100).round()}%',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }
}

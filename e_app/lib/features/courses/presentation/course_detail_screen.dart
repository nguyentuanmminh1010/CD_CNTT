import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../ranking/application/ranking_providers.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';
import '../application/course_providers.dart';
import '../domain/course.dart';
import '../domain/level_test_args.dart';

/// Chi tiết khoá học ("Thông tin khoá học" ở `Home.png`): tab "Lộ trình" (Level
/// → Unit, mỗi Unit là một chủ đề học có sẵn) và "Mô tả", cùng nút đăng ký /
/// tiếp tục học.
class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _enrolling = false;

  Future<void> _enroll() async {
    setState(() => _enrolling = true);
    try {
      await ref.read(courseRepositoryProvider).enroll(widget.courseId);
      ref.invalidate(courseDetailProvider(widget.courseId));
      ref.invalidate(achievementsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đăng ký được khoá học. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _openUnit(CourseUnit unit) async {
    if (unit.locked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Hãy đạt từ $levelTestPassPercent% ở Level Test của Level ${unit.level - 1} để mở khoá bài này.'),
      ));
      return;
    }
    await context.push(AppRoutes.lesson, extra: unit);
    if (!mounted) return;
    ref.invalidate(courseDetailProvider(widget.courseId));
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Thông tin khoá học'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: courseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không tải được khoá học.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(courseDetailProvider(widget.courseId)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: _buildBody,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Course course) {
    final byLevel = <int, List<CourseUnit>>{};
    for (final u in course.units) {
      byLevel.putIfAbsent(u.level, () => []).add(u);
    }
    final next = course.nextUnit;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(topicIconFor(course.icon), color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khoá học',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(course.title,
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        '${course.unitCount} bài học · ${course.totalItems} câu hỏi',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${course.completedUnits}/${course.unitCount} bài hoàn thành',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('${(course.progress * 100).round()}%',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [Tab(text: 'Lộ trình'), Tab(text: 'Mô tả khoá học')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    for (final entry in byLevel.entries) ...[
                      Text('Level ${entry.key}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(height: 8),
                      for (final unit in entry.value) ...[
                        Opacity(
                          opacity: unit.locked ? 0.55 : 1,
                          child: _UnitTile(unit: unit, onTap: () => _openUnit(unit)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _LevelTestTile(
                        level: entry.key,
                        result: course.resultFor(entry.key),
                        questionCount: LevelTestArgs(
                          courseId: course.id,
                          courseTitle: course.title,
                          level: entry.key,
                          units: entry.value,
                        ).questionCount,
                        onTap: () async {
                          await context.push(
                            AppRoutes.levelTest,
                            extra: LevelTestArgs(
                              courseId: course.id,
                              courseTitle: course.title,
                              level: entry.key,
                              units: entry.value,
                            ),
                          );
                          if (!mounted) return;
                          ref.invalidate(courseDetailProvider(widget.courseId));
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Text('Chi tiết khoá học',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(course.description ?? '',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 16),
                    _InfoRow(Icons.layers_rounded, '${byLevel.length} level'),
                    _InfoRow(Icons.menu_book_rounded, '${course.unitCount} bài học'),
                    _InfoRow(Icons.quiz_rounded, '${course.totalItems} câu hỏi'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: _actionButton(course, next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(Course course, CourseUnit? next) {
    if (!course.enrolled) {
      return ElevatedButton(
        onPressed: _enrolling ? null : _enroll,
        child: Text(_enrolling ? 'Đang đăng ký...' : 'Đăng ký khoá học'),
      );
    }
    if (course.completed || next == null) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.verified_rounded),
        label: const Text('Đã hoàn thành khoá học'),
      );
    }
    return ElevatedButton(
      onPressed: () => _openUnit(next),
      // Đã có chứng chỉ (lưu vĩnh viễn) nhưng khoá có thêm nội dung: học tiếp phần mới, chứng chỉ không mất.
      child: Text(course.certified ? 'Học bài mới: ${next.topic.name}' : 'Tiếp tục: ${next.topic.name}'),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.unit, required this.onTap});

  final CourseUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = unit.completed;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        splashColor: AppColors.primary.withValues(alpha: 0.16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: done ? AppColors.primary : AppColors.border,
              width: done ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topicIconFor(unit.topic.icon),
                    color: AppColors.accentYellow, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.topic.name,
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(
                      '${unit.categoryLabel} · ${unit.masteredItems}/${unit.totalItems} câu đã thuộc',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (!done && unit.masteredItems > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: unit.progress,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                unit.locked
                    ? Icons.lock_rounded
                    : done
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                color: done && !unit.locked ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô "Level Test" cuối mỗi Level — ôn lại toàn bộ chủ đề của Level đó.
class _LevelTestTile extends StatelessWidget {
  const _LevelTestTile({
    required this.level,
    required this.questionCount,
    required this.result,
    required this.onTap,
  });

  final int level;
  final int questionCount;
  final LevelResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.12),
        splashColor: AppColors.primary.withValues(alpha: 0.22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level Test',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(
                      result == null || !result!.attempted
                          ? 'Đạt từ $levelTestPassPercent% để mở khoá Level tiếp theo · $questionCount câu'
                          : result!.passed
                              ? 'Đã vượt · điểm cao nhất ${result!.bestPercent}%'
                              : 'Chưa đạt · cao nhất ${result!.bestPercent}% (cần $levelTestPassPercent%)',
                      style: TextStyle(
                        color: result?.passed == true
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight:
                            result?.passed == true ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                result?.passed == true ? Icons.verified_rounded : Icons.chevron_right_rounded,
                color: result?.passed == true ? AppColors.success : AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }
}

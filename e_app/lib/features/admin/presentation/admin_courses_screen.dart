import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../courses/application/course_providers.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';

/// Quản trị khoá học (chỉ admin — nút vào ở Hồ sơ chỉ hiện khi `AuthUser.isAdmin`;
/// backend vẫn kiểm tra quyền ở từng mutation): xem, tạo, xoá khoá học.
class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm khoá học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(hintText: 'Tên khoá học'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Mô tả'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    try {
      final course = await ref
          .read(courseRepositoryProvider)
          .createCourse(title.text.trim(), description.text.trim());
      ref.invalidate(coursesProvider);
      if (context.mounted) context.push('${AppRoutes.adminCourses}/${course.id}');
    } catch (e) {
      if (context.mounted) _error(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá khoá học?'),
        content: Text('Khoá "$title" và việc đăng ký của người học sẽ bị xoá. Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(courseRepositoryProvider).deleteCourse(id);
      ref.invalidate(coursesProvider);
    } catch (e) {
      if (context.mounted) _error(context, e);
    }
  }

  void _error(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Quản trị khoá học'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.adminTopics),
            icon: const Icon(Icons.library_books_rounded, size: 18),
            label: const Text('Nội dung'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm khoá học'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(coursesProvider),
                  child: const Text('Không tải được danh sách. Thử lại'),
                ),
              ),
              data: (courses) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = courses[i];
                  return Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      hoverColor: AppColors.primary.withValues(alpha: 0.06),
                      onTap: () async {
                        await context.push('${AppRoutes.adminCourses}/${c.id}');
                        ref.invalidate(coursesProvider);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(topicIconFor(c.icon), color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title,
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  Text('${c.unitCount} bài học · ${c.totalItems} câu hỏi',
                                      style: TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xoá khoá học',
                              onPressed: () => _delete(context, ref, c.id, c.title),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

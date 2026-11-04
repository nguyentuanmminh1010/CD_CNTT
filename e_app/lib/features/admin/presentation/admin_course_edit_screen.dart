import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../courses/application/course_providers.dart';
import '../../courses/domain/course.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';

/// Sửa lộ trình một khoá học (admin): thêm/xoá Unit theo Level. Mỗi Unit là một
/// chủ đề học có sẵn (Từ vựng/Ngữ pháp/Mẫu câu) — không có nội dung riêng.
class AdminCourseEditScreen extends ConsumerWidget {
  const AdminCourseEditScreen({super.key, required this.courseId});

  final String courseId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(courseDetailProvider(courseId));
    ref.invalidate(coursesProvider);
  }

  void _error(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _addUnit(BuildContext context, WidgetRef ref, Course course) async {
    final vocab = ref.read(vocabularyTopicsProvider).valueOrNull ?? [];
    final grammar = ref.read(grammarTopicsProvider).valueOrNull ?? [];
    final sentences = ref.read(sentenceTopicsProvider).valueOrNull ?? [];
    final used = course.units.map((u) => u.topic.id).toSet();
    final options = <(String, VocabularyTopic)>[
      for (final t in vocab) ('Từ vựng', t),
      for (final t in grammar) ('Ngữ pháp', t),
      for (final t in sentences) ('Mẫu câu', t),
    ].where((o) => !used.contains(o.$2.id)).toList();

    final maxLevel = course.units.fold(1, (m, u) => u.level > m ? u.level : m);
    var level = maxLevel;
    VocabularyTopic? selected;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Thêm bài học (Unit)'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Level', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: level > 1 ? () => setState(() => level--) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text('$level',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    IconButton(
                      onPressed: () => setState(() => level++),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (options.isEmpty)
                  const Text('Mọi chủ đề đã có trong khoá học này.')
                else
                  DropdownButtonFormField<VocabularyTopic>(
                    isExpanded: true,
                    hint: const Text('Chọn chủ đề'),
                    initialValue: selected,
                    items: [
                      for (final o in options)
                        DropdownMenuItem(
                          value: o.$2,
                          child: Text('${o.$1} · ${o.$2.name}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => selected = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    try {
      await ref.read(courseRepositoryProvider).addUnit(courseId, level, selected!.id);
      _refresh(ref);
    } catch (e) {
      if (context.mounted) _error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nạp sẵn danh sách chủ đề để hộp thoại "Thêm Unit" có dữ liệu ngay.
    ref.watch(vocabularyTopicsProvider);
    ref.watch(grammarTopicsProvider);
    ref.watch(sentenceTopicsProvider);
    final courseAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(courseAsync.valueOrNull?.title ?? 'Sửa khoá học'),
      ),
      floatingActionButton: courseAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _addUnit(context, ref, courseAsync.value!),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm Unit'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: courseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(courseDetailProvider(courseId)),
                  child: const Text('Không tải được khoá học. Thử lại'),
                ),
              ),
              data: (course) {
                final byLevel = <int, List<CourseUnit>>{};
                for (final u in course.units) {
                  byLevel.putIfAbsent(u.level, () => []).add(u);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  children: [
                    if ((course.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(course.description!,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13.5, height: 1.4)),
                      ),
                    if (course.units.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Khoá học chưa có Unit nào. Bấm "Thêm Unit" để bắt đầu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                    for (final entry in byLevel.entries) ...[
                      Text('Level ${entry.key}',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      for (final u in entry.value)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(topicIconFor(u.topic.icon),
                                  color: AppColors.accentYellow, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.topic.name,
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                    Text('${u.categoryLabel} · ${u.totalItems} câu hỏi',
                                        style: TextStyle(
                                            color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Xoá Unit',
                                onPressed: () async {
                                  try {
                                    await ref.read(courseRepositoryProvider).removeUnit(u.id);
                                    _refresh(ref);
                                  } catch (e) {
                                    if (context.mounted) _error(context, e);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline_rounded,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

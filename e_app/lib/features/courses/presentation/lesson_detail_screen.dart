import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../reviews/presentation/topic_reviews_section.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../../vocabulary/presentation/widgets/difficulty_badge.dart';
import '../../vocabulary/presentation/widgets/study_mode_sheet.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';
import '../domain/course.dart';
import '../domain/level_test_args.dart';

/// Các mục của một bài học (chủ đề) theo category — gọi đúng repository của mảng đó.
final lessonItemsProvider = FutureProvider.autoDispose
    .family<List<VocabularyItem>, ({String category, String topicId})>((ref, key) {
  return switch (key.category) {
    'GRAMMAR' => ref.watch(grammarRepositoryProvider).fetchItems(key.topicId),
    'SENTENCE' => ref.watch(sentenceRepositoryProvider).fetchItems(key.topicId),
    _ => ref.watch(vocabularyRepositoryProvider).fetchItems(key.topicId),
  };
});

/// Chi tiết một bài học ("Thông tin bài học" ở `Home.png`): tab **Lý thuyết**
/// (danh sách mục + nghĩa + ví dụ), **Hướng dẫn** (cách học hiệu quả) và
/// **Đánh giá** (sao + nhận xét của người học), cùng nút "Học ngay".
class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.unit});

  final CourseUnit unit;

  String get _basePath => switch (unit.category) {
        'GRAMMAR' => AppRoutes.grammar,
        'SENTENCE' => AppRoutes.sentences,
        _ => AppRoutes.vocabulary,
      };

  Future<void> _study(BuildContext context) async {
    final mode = await showStudyModeSheet(context, unit.topic.name);
    if (mode == null || !context.mounted) return;
    final path = studyModePath(_basePath, unit.topic.id, mode);
    context.push(path, extra: unit.topic.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Thông tin bài học'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: DefaultTabController(
              length: 3,
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
                            color: AppColors.accentYellow.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(topicIconFor(unit.topic.icon),
                              color: AppColors.accentYellow, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bài học · ${unit.categoryLabel}',
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                              Text(unit.topic.name,
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22)),
                              const SizedBox(height: 4),
                              Text('${unit.totalItems} câu hỏi · ${unit.masteredItems} đã thuộc',
                                  style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    tabs: [Tab(text: 'Lý thuyết'), Tab(text: 'Hướng dẫn'), Tab(text: 'Đánh giá')],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TheoryTab(unit: unit),
                        _GuideTab(unit: unit),
                        TopicReviewsSection(topicId: unit.topic.id),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _study(context),
                        child: const Text('Học ngay'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TheoryTab extends ConsumerWidget {
  const _TheoryTab({required this.unit});
  final CourseUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (category: unit.category, topicId: unit.topic.id);
    final itemsAsync = ref.watch(lessonItemsProvider(key));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        if ((unit.topic.description ?? '').isNotEmpty) ...[
          Text(unit.topic.description!,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
        ],
        itemsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(lessonItemsProvider(key)),
              child: const Text('Không tải được nội dung. Thử lại'),
            ),
          ),
          data: (items) => Column(
            children: [for (final item in items) _ItemTile(item: item)],
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.term,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5)),
              ),
              if (item.mastered)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              DifficultyBadge(item: item),
            ],
          ),
          if (item.phonetic != null) ...[
            const SizedBox(height: 2),
            Text(item.phonetic!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
          const SizedBox(height: 6),
          Text(item.meaning,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 13.5, height: 1.4)),
          if (item.example != null && item.example != item.term) ...[
            const SizedBox(height: 6),
            Text('Ví dụ: ${item.example}',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _GuideTab extends StatelessWidget {
  const _GuideTab({required this.unit});
  final CourseUnit unit;

  List<(IconData, String, String)> get _steps => [
        (
          Icons.menu_book_rounded,
          'Đọc phần Lý thuyết',
          unit.category == 'GRAMMAR'
              ? 'Đọc kỹ từng điểm ngữ pháp, chú ý công thức và ví dụ đi kèm.'
              : unit.category == 'SENTENCE'
                  ? 'Đọc to từng mẫu câu và nghĩa tiếng Việt để làm quen nhịp điệu câu.'
                  : 'Xem lướt toàn bộ từ vựng, nghĩa và ví dụ trước khi luyện.'
        ),
        (
          Icons.style_rounded,
          'Ôn bằng Flashcard',
          'Lật thẻ, đánh dấu "Đã thuộc" cho mục chắc chắn và "Cần ôn tập" cho mục còn lung túng.'
        ),
        (
          Icons.quiz_rounded,
          'Kiểm tra bằng Trắc nghiệm',
          'Chọn nghĩa đúng — câu sai sẽ được lưu vào mục Ôn tập lỗi sai để luyện lại.'
        ),
        (
          Icons.swap_horiz_rounded,
          'Luyện Sắp xếp câu',
          'Ghép các từ thành câu hoàn chỉnh để nhớ cấu trúc và thứ tự từ.'
        ),
        (
          Icons.flag_rounded,
          'Vượt Level Test',
          'Khi đã thuộc các bài trong Level, làm Level Test (đạt từ $levelTestPassPercent%) để mở khoá Level tiếp theo.'
        ),
      ];

  /// Các bước do biên tập viên/admin nhập cho chủ đề này (mỗi dòng một bước); rỗng = dùng bước mặc định.
  List<String> get _customSteps => (unit.topic.guide ?? '')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final custom = _customSteps;
    if (custom.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        children: [
          Text('Hướng dẫn: ${unit.topic.name}',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          for (var i = 0; i < custom.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(custom[i],
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 13.5, height: 1.45)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('Cách học hiệu quả',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_steps[i].$1, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${_steps[i].$2}',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(_steps[i].$3,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
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

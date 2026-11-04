import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../practice/domain/practice_models.dart';

/// Cách học một chủ đề: Flashcard (tự đánh giá) hoặc một dạng bài trên engine làm bài chung.
enum StudyMode { flashcard, mixed, meaning, reverse, cloze, listen, spelling, matching, wordOrder }

extension StudyModeInfo on StudyMode {
  /// null = Flashcard.
  PracticeKind? get practiceKind => switch (this) {
        StudyMode.flashcard => null,
        StudyMode.mixed => PracticeKind.mixed,
        StudyMode.meaning => PracticeKind.meaning,
        StudyMode.reverse => PracticeKind.reverse,
        StudyMode.cloze => PracticeKind.cloze,
        StudyMode.listen => PracticeKind.listen,
        StudyMode.spelling => PracticeKind.spelling,
        StudyMode.matching => PracticeKind.matching,
        StudyMode.wordOrder => PracticeKind.wordOrder,
      };
}

/// Route mở chủ đề [topicId] (thuộc `/vocabulary`, `/grammar` hoặc `/sentences`) theo [mode].
String studyModePath(String basePath, String topicId, StudyMode mode) {
  final kind = mode.practiceKind;
  return kind == null ? '$basePath/$topicId' : '$basePath/$topicId/practice/${kind.slug}';
}

Future<StudyMode?> showStudyModeSheet(BuildContext context, String topicName) {
  return showModalBottomSheet<StudyMode>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      void pick(StudyMode m) => Navigator.of(context).pop(m);
      const grid = [
        StudyMode.meaning,
        StudyMode.reverse,
        StudyMode.matching,
        StudyMode.cloze,
        StudyMode.listen,
        StudyMode.spelling,
        StudyMode.wordOrder,
      ];
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(topicName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Chọn cách bạn muốn học', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _FeaturedTile(onTap: () => pick(StudyMode.mixed)),
                const SizedBox(height: 12),
                _ModeTile(
                  icon: Icons.style_rounded,
                  color: AppColors.primary,
                  title: 'Flashcard',
                  subtitle: 'Lật thẻ, tự đánh giá đã thuộc',
                  onTap: () => pick(StudyMode.flashcard),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final width = (c.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final m in grid)
                          SizedBox(
                            width: width,
                            child: _ModeTile(
                              icon: m.practiceKind!.icon,
                              color: m.practiceKind!.color,
                              title: m.practiceKind!.label,
                              subtitle: m.practiceKind!.subtitle,
                              compact: true,
                              onTap: () => pick(m),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.08),
        splashColor: Colors.white.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Luyện tổng hợp',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Trộn nhiều dạng bài — khuyên dùng',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Icon(icon, color: color, size: compact ? 22 : 24),
    );
    final texts = [
      Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: compact ? 14 : 15,
            color: AppColors.textPrimary,
          )),
      const SizedBox(height: 2),
      Text(subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: AppColors.textSecondary,
          )),
    ];
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.06),
        splashColor: color.withValues(alpha: 0.16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          // Ô lưới cao bằng nhau dù mô tả 1 hay 2 dòng.
          constraints: compact ? const BoxConstraints(minHeight: 136) : null,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [iconBox, const SizedBox(height: 10), ...texts],
                )
              : Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: texts),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
        ),
      ),
    );
  }
}

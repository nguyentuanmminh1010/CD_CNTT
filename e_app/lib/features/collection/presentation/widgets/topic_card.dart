import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vocabulary/domain/vocabulary_models.dart';
import '../../../vocabulary/presentation/widgets/study_mode_sheet.dart';
import '../../../vocabulary/presentation/widgets/topic_icon.dart';

/// Một chủ đề Flashcard gộp từ cả 3 mảng (Vocabulary/Grammar/Sentence), gắn
/// kèm route gốc đúng mảng đó — dùng chung cho tab Thư viện và màn "Xem tất cả".
class CategoryEntry {
  const CategoryEntry(this.category, this.basePath, this.topic);
  final String category;
  final String basePath;
  final VocabularyTopic topic;
}

class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.entry, this.width = 140});

  final CategoryEntry entry;

  /// `null` để thẻ giãn hết chiều rộng cha (vd trong `GridView`) — mặc định
  /// 140 để khớp danh sách cuộn ngang ở tab Thư viện.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final mode = await showStudyModeSheet(context, entry.topic.name);
          if (mode == null || !context.mounted) return;
          final path = studyModePath(entry.basePath, entry.topic.id, mode);
          context.push(path, extra: entry.topic.name);
        },
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(topicIconFor(entry.topic.icon), color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              Text(
                entry.topic.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.topic.wordCount} flashcard',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

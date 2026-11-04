import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../recommendation/recommendation.dart';
import '../../../review/application/review_providers.dart';
import '../../../vocabulary/presentation/widgets/study_mode_sheet.dart';
import '../../../vocabulary/presentation/widgets/topic_icon.dart';

/// "Gợi ý cho bạn": chủ đề có điểm thành thạo (mastery) thấp nhất còn mục chưa thuộc, kèm độ khó
/// nên luyện — backend cập nhật mastery sau mỗi câu trả lời nên gợi ý đổi theo tiến trình.
class RecommendationCard extends ConsumerWidget {
  const RecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recommendedTopicsProvider).valueOrNull?.firstOrNull;
    if (rec == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.accentBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: AppColors.accentBlue.withValues(alpha: 0.08),
          onTap: () async {
            final mode = await showStudyModeSheet(context, rec.topic.name);
            if (mode == null || !context.mounted) return;
            final path = studyModePath(rec.basePath, rec.topic.id, mode);
            await context.push(path, extra: rec.topic.name);
            ref.invalidate(recommendedTopicsProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(topicIconFor(rec.topic.icon), color: AppColors.accentBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gợi ý cho bạn',
                          style: TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      Text('${rec.categoryLabel} · ${rec.topic.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Thành thạo ${(rec.score * 100).round()}% · nên luyện mức ${rec.difficultyLabel}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Ôn đến hạn": số mục đến hạn ôn lại theo lịch lặp lại ngắt quãng (sai ⇒ ôn ngay; đúng nhiều lần
/// ⇒ giãn dần 1/2/4/8/16 ngày). Chỉ hiện khi có mục đến hạn.
class DueReviewBanner extends ConsumerWidget {
  const DueReviewBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(dueItemCountProvider).valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.accentYellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: AppColors.accentYellow.withValues(alpha: 0.10),
          onTap: () async {
            final items = await ref.read(dueItemsProvider.future);
            if (items.length < 2) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cần ít nhất 2 mục đến hạn để làm bài ôn.')),
                );
              }
              return;
            }
            if (!context.mounted) return;
            await context.push(AppRoutes.reviewQuiz, extra: [...items]..shuffle());
            ref.invalidate(dueItemCountProvider);
            ref.invalidate(dueItemsProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.alarm_rounded, color: AppColors.accentYellow, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count mục đến hạn ôn',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      Text('Ôn đúng lúc để nhớ lâu hơn',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../attempts/application/attempt_providers.dart';
import '../../attempts/domain/attempt.dart';
import '../../attempts/presentation/attempt_history_screen.dart';
import '../../attempts/presentation/widgets/attempt_tile.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../ranking/presentation/widgets/leaderboard_view.dart';
import '../../review/domain/wrong_item.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../domain/assessment_test.dart';

class _QuickCard {
  const _QuickCard(this.category, this.title, this.icon, this.color, this.questionCount);
  final ReviewCategory? category; // null = "Tất cả"
  final String title;
  final IconData icon;
  final Color color;
  final int questionCount;
}

/// Tab "Đánh giá" — theo ảnh Inspiration `Assessments.png`, gồm 3 phân đoạn:
/// **Bài test** (nhiều bài test riêng biệt theo cấp độ/mảng + luyện nhanh theo
/// loại), **Lịch sử** (các lượt đã làm, lấy từ `myAttempts`) và **Xếp hạng**
/// (leaderboard theo số mục đã thuộc). Đề lấy ngẫu nhiên từ kho nội dung,
/// chấm ngay ở `AssessmentQuizScreen` như các dạng Trắc nghiệm khác.
class AssessmentsTab extends StatelessWidget {
  const AssessmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text('Bài đánh giá',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 24)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Làm bài test để biết năng lực hiện tại và theo dõi tiến bộ của bạn.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: [Tab(text: 'Bài test'), Tab(text: 'Lịch sử'), Tab(text: 'Xếp hạng')],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [_TestsPane(), _HistoryPane(), LeaderboardView()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestsPane extends ConsumerWidget {
  const _TestsPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabTopics = ref.watch(vocabularyTopicsProvider).valueOrNull ?? [];
    final grammarTopics = ref.watch(grammarTopicsProvider).valueOrNull ?? [];
    final sentenceTopics = ref.watch(sentenceTopicsProvider).valueOrNull ?? [];
    final latest = ref.watch(myAttemptsProvider).valueOrNull?.firstOrNull;

    int sumWords(List<VocabularyTopic> topics) => topics.fold(0, (a, t) => a + t.wordCount);
    final vocabCount = sumWords(vocabTopics);
    final grammarCount = sumWords(grammarTopics);
    final sentenceCount = sumWords(sentenceTopics);

    final quick = [
      _QuickCard(null, 'Tất cả', Icons.grid_view_rounded, AppColors.textPrimary,
          vocabCount + grammarCount + sentenceCount),
      _QuickCard(ReviewCategory.vocabulary, 'Vocabulary', Icons.style_rounded,
          AppColors.primary, vocabCount),
      _QuickCard(ReviewCategory.grammar, 'Grammar', Icons.rule_rounded,
          AppColors.accentBlue, grammarCount),
      _QuickCard(ReviewCategory.sentence, 'Sentences', Icons.short_text_rounded,
          AppColors.accentPurple, sentenceCount),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        if (latest != null) ...[
          _LatestResultCard(attempt: latest),
          const SizedBox(height: 20),
        ],
        Text('Bài test', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final test in assessmentTests) ...[
          _TestCard(
            test: test,
            onTap: () => context.push(AppRoutes.assessmentIntro, extra: test),
          ),
          const SizedBox(height: 10),
        ],
        _SkillTestCard(
          title: 'Bài test nghe',
          subtitle: '8 câu · Nghe câu mẫu rồi chép lại',
          icon: Icons.headphones_rounded,
          color: AppColors.accentBlue,
          onTap: () => context.push(AppRoutes.listeningPractice),
        ),
        const SizedBox(height: 10),
        _SkillTestCard(
          title: 'Bài test nói',
          subtitle: '8 câu · Đọc to câu mẫu bằng micro',
          icon: Icons.mic_rounded,
          color: AppColors.accentYellow,
          onTap: () => context.push(AppRoutes.speakingPractice),
        ),
        const SizedBox(height: 14),
        Text('Luyện nhanh theo loại', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Làm toàn bộ bài trắc nghiệm của một mảng nội dung.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            for (final card in quick)
              _QuickGridCard(
                card: card,
                onTap: card.questionCount == 0
                    ? null
                    : () => context.push(AppRoutes.assessmentQuiz, extra: card.category),
              ),
          ],
        ),
      ],
    );
  }
}

/// Thẻ bài test theo kỹ năng (Nghe: chép chính tả; Nói: đọc to câu mẫu qua micro).
class _SkillTestCard extends StatelessWidget {
  const _SkillTestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.10),
        splashColor: color.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard({required this.attempt});
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${attempt.scorePercent}%',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kết quả gần nhất',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                Text(attempt.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('${attempt.correctCount}/${attempt.totalQuestions} câu · ${attempt.dateLabel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.onTap});

  final AssessmentTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        hoverColor: test.color.withValues(alpha: 0.08),
        splashColor: test.color.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: test.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(test.icon, color: test.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(test.title,
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      '${test.questionCount} câu · ${test.minutes} phút · ${test.levelLabel}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickGridCard extends StatelessWidget {
  const _QuickGridCard({required this.card, required this.onTap});

  final _QuickCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        hoverColor: card.color.withValues(alpha: 0.08),
        splashColor: card.color.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: card.color, size: 20),
              ),
              const Spacer(),
              Text(card.title,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text('${card.questionCount} câu hỏi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPane extends ConsumerWidget {
  const _HistoryPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(myAttemptsProvider);
    return attemptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(myAttemptsProvider),
          child: const Text('Không tải được lịch sử. Thử lại'),
        ),
      ),
      data: (attempts) => attempts.isEmpty
          ? const AttemptEmptyState()
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(myAttemptsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                itemCount: attempts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => AttemptTile(attempt: attempts[i]),
              ),
            ),
    );
  }
}

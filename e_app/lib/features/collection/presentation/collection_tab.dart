import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../review/application/review_providers.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import 'widgets/topic_card.dart';

/// Tab "Thư viện ôn tập" (thay cho tab "Ôn tập" cũ) — theo ảnh Inspiration
/// `Collection.png`: nơi tổng hợp mọi loại bài tập (Flashcard theo chủ đề của
/// cả 3 mảng), lối vào "Ôn tập lỗi sai", và lựa chọn học/quiz ngẫu nhiên.
class CollectionTab extends ConsumerWidget {
  const CollectionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabTopics = ref.watch(vocabularyTopicsProvider).valueOrNull ?? [];
    final grammarTopics = ref.watch(grammarTopicsProvider).valueOrNull ?? [];
    final sentenceTopics = ref.watch(sentenceTopicsProvider).valueOrNull ?? [];
    final wrongItemsAsync = ref.watch(wrongItemsProvider);
    final wrongCount = wrongItemsAsync.valueOrNull?.length ?? 0;

    final entries = [
      for (final t in vocabTopics) CategoryEntry('Vocabulary', AppRoutes.vocabulary, t),
      for (final t in grammarTopics) CategoryEntry('Grammar', AppRoutes.grammar, t),
      for (final t in sentenceTopics) CategoryEntry('Sentences', AppRoutes.sentences, t),
    ];

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text('Thư viện ôn tập',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 24)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  children: [
                    _MistakesCard(
                      count: wrongCount,
                      onOpen: () => context.push(AppRoutes.reviewMistakes),
                      onRandomQuiz: wrongCount < 2
                          ? null
                          : () {
                              final shuffled = [...wrongItemsAsync.value!]..shuffle();
                              context.push(AppRoutes.reviewQuiz, extra: shuffled);
                            },
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        hoverColor: AppColors.primary.withValues(alpha: 0.06),
                        onTap: () async {
                          await context.push(AppRoutes.myDecks);
                          ref.invalidate(vocabularyTopicsProvider);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bộ thẻ của tôi',
                                        style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15)),
                                    Text('Tự tạo thư mục và thẻ từ vựng riêng',
                                        style: TextStyle(
                                            color: AppColors.textSecondary, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Flashcards', style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              '${entries.length} chủ đề',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.allTopics),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Xem tất cả'),
                              Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => TopicCard(entry: entries[i]),
                        ),
                      ),
                  ],
                ),
              ),
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final entry = entries[Random().nextInt(entries.length)];
                        final path = '${entry.basePath}/${entry.topic.id}';
                        context.push(path, extra: entry.topic.name);
                      },
                      child: const Text('Học ngẫu nhiên'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MistakesCard extends StatelessWidget {
  const _MistakesCard({required this.count, required this.onOpen, required this.onRandomQuiz});

  final int count;
  final VoidCallback onOpen;
  final VoidCallback? onRandomQuiz;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ôn tập lỗi sai',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            )),
                        const SizedBox(height: 4),
                        Text('$count lỗi sai',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onOpen,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.chevron_right_rounded,
                            color: AppColors.primaryDark, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F7A4D),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                    disabledForegroundColor: const Color(0xFF1F7A4D).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onRandomQuiz,
                  child: const Text('Làm quiz ngẫu nhiên',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


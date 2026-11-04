import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../../vocabulary/presentation/widgets/difficulty_badge.dart';
import '../../vocabulary/presentation/widgets/item_image.dart';
import '../../vocabulary/presentation/widgets/speak_button.dart';
import '../../vocabulary/presentation/widgets/flashcard_nav_arrows.dart';
import '../../vocabulary/presentation/widgets/flip_card.dart';
import '../application/grammar_providers.dart';

class GrammarFlashcardScreen extends ConsumerStatefulWidget {
  const GrammarFlashcardScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  final String topicId;
  final String topicName;

  @override
  ConsumerState<GrammarFlashcardScreen> createState() =>
      _GrammarFlashcardScreenState();
}

class _GrammarFlashcardScreenState extends ConsumerState<GrammarFlashcardScreen> {
  int _index = 0;
  bool _flipped = false;
  int _masteredCount = 0;

  void _goTo(int next) {
    setState(() {
      _index = next;
      _flipped = false;
    });
  }

  Future<void> _mark(List<VocabularyItem> items, bool mastered) async {
    final item = items[_index];
    if (mastered) _masteredCount += 1;
    await ref
        .read(grammarItemsProvider(widget.topicId).notifier)
        .markMastered(item.id, mastered);
    if (!mounted) return;
    _goTo(_index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(grammarItemsProvider(widget.topicId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: switch (itemsAsync) {
              AsyncData(:final value) => _buildBody(context, value),
              AsyncError() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('Không tải được nội dung.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(grammarItemsProvider(widget.topicId)),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<VocabularyItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Chủ đề này chưa có nội dung.'));
    }

    if (_index >= items.length) {
      return _CompletionView(
        total: items.length,
        mastered: _masteredCount,
        onDone: () => context.pop(),
        onRestart: () => setState(() {
          _index = 0;
          _flipped = false;
          _masteredCount = 0;
        }),
      );
    }

    final item = items[_index];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.topicName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        )),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_index) / items.length,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DifficultyBadge(item: item),
              const SizedBox(width: 8),
              Text('${_index + 1}/${items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                FlashcardNavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: _index > 0 ? () => _goTo(_index - 1) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _flipped = !_flipped),
                    child: FlipCard(
                      flipped: _flipped,
                      front: _CardFace(
                        color: AppColors.flashcardTeal,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.imageUrl != null) ...[
                              ItemImage(url: item.imageUrl!, height: 110),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              item.term,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SpeakButton(text: item.term, audioUrl: item.audioUrl),
                            const SizedBox(height: 14),
                            Icon(Icons.touch_app_rounded,
                                color: AppColors.primaryDark, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Chạm để xem giải thích',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      back: _CardFace(
                        color: AppColors.flashcardTealDark,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.meaning,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (item.example != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                '"${item.example}"',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primaryDark,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (item.explanation != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                item.explanation!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FlashcardNavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _goTo(_index + 1),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _flipped ? () => _mark(items, false) : null,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Cần ôn tập'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _flipped ? () => _mark(items, true) : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Đã thuộc'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.total,
    required this.mastered,
    required this.onDone,
    required this.onRestart,
  });

  final int total;
  final int mastered;
  final VoidCallback onDone;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Hoàn thành!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Bạn đã thuộc $mastered/$total mục.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text('Quay lại danh sách'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRestart,
                child: const Text('Ôn tập lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

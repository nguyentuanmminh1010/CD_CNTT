import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../vocabulary/presentation/widgets/item_image.dart';
import '../../vocabulary/presentation/widgets/speak_button.dart';
import '../application/attempt_providers.dart';
import '../domain/attempt.dart';

/// Xem lại đáp án một lượt làm bài: từng câu với câu trả lời đã gửi và đáp án đúng (do backend lưu
/// khi chấm điểm). Các lượt cũ trước khi có chấm điểm ở backend không có chi tiết từng câu.
class AttemptDetailScreen extends ConsumerWidget {
  const AttemptDetailScreen({super.key, required this.attemptId, this.attempt});

  final String attemptId;
  final Attempt? attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answersAsync = ref.watch(attemptAnswersProvider(attemptId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(attempt?.title ?? 'Xem lại đáp án', overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: answersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(attemptAnswersProvider(attemptId)),
                  child: const Text('Không tải được chi tiết. Thử lại'),
                ),
              ),
              data: (answers) {
                if (answers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Lượt làm bài này không có chi tiết từng câu (làm trước khi app lưu đáp án).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final correct = answers.where((a) => a.correct).length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Đúng $correct/${answers.length} câu đã trả lời'
                        '${attempt != null ? ' · điểm ${attempt!.scorePercent}%' : ''}',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < answers.length; i++) ...[
                      _AnswerTile(index: i + 1, answer: answers[i]),
                      const SizedBox(height: 10),
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

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.index, required this.answer});

  final int index;
  final AttemptAnswerView answer;

  @override
  Widget build(BuildContext context) {
    final color = answer.correct ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(answer.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$index. ${answer.term}',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              SpeakButton(text: answer.term, size: 34, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text('Bạn trả lời: ${(answer.answer ?? '').isEmpty ? '(trống)' : answer.answer}',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
          if (!answer.correct) ...[
            const SizedBox(height: 4),
            Text('Đáp án đúng: ${answer.correctAnswer}',
                style: TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ],
          if (answer.imageUrl != null) ...[
            const SizedBox(height: 10),
            ItemImage(url: answer.imageUrl!, height: 110),
          ],
          if (answer.explanation != null && answer.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(answer.explanation!,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 12.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

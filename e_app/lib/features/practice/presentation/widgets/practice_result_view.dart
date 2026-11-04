import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/practice_models.dart';
import 'exercise_chrome.dart';

/// Màn kết quả cuối lượt: vòng % có hiệu ứng, số sao, thống kê, các câu cần ôn lại và nút hành động.
class PracticeResultView extends StatelessWidget {
  const PracticeResultView({
    super.key,
    required this.title,
    required this.outcome,
    required this.onExit,
    required this.exitLabel,
    this.onRestart,
    this.onRetryMistakes,
    this.extras = const [],
  });

  final String title;
  final PracticeOutcome outcome;
  final VoidCallback onExit;
  final String exitLabel;
  final VoidCallback? onRestart;
  final VoidCallback? onRetryMistakes;

  /// Phần riêng của từng loại bài (cấp độ ước tính, đạt/không đạt Level Test, xem lại đáp án...).
  final List<Widget> extras;

  String get _headline {
    final p = outcome.percent;
    if (p >= 90) return 'Xuất sắc!';
    if (p >= 70) return 'Làm tốt lắm!';
    if (p >= 40) return 'Cố lên nhé!';
    return 'Cần luyện thêm một chút';
  }

  int get _stars {
    final p = outcome.percent;
    if (p >= 90) return 3;
    if (p >= 60) return 2;
    if (p > 0) return 1;
    return 0;
  }

  String _time(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = outcome.percent >= 70
        ? AppColors.success
        : (outcome.percent >= 40 ? AppColors.accentYellow : AppColors.error);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: outcome.percent / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    width: 176,
                    height: 176,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: AppColors.isDark ? 0.14 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: v,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                        Center(
                          child: Text('${(v * 100).round()}%',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + i * 200),
                        curve: Curves.elasticOut,
                        builder: (context, t, child) => Transform.scale(scale: t, child: child),
                        child: Icon(
                          i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 40,
                          color: i < _stars ? AppColors.accentYellow : AppColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text('Hoàn thành $title',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatBox(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      value: '${outcome.correct}/${outcome.total}',
                      label: 'Câu đúng',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accentYellow,
                      value: '${outcome.bestStreak}',
                      label: 'Chuỗi đúng',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.timer_rounded,
                      color: AppColors.accentBlue,
                      value: _time(outcome.elapsed),
                      label: 'Thời gian',
                    ),
                  ],
                ),
                for (final w in extras) ...[const SizedBox(height: 14), w],
                if (outcome.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cần ôn lại (${outcome.mistakes.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  for (final m in outcome.mistakes)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.entry.item.term,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    )),
                                const SizedBox(height: 3),
                                Text.rich(
                                  TextSpan(children: [
                                    const TextSpan(
                                      text: 'Đáp án: ',
                                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(text: m.correctAnswer, style: TextStyle(color: AppColors.textPrimary)),
                                  ]),
                                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                                ),
                                if (m.given.isNotEmpty)
                                  Text('Bạn chọn: ${m.given}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: AppColors.error.withValues(alpha: 0.9),
                                        decoration: TextDecoration.lineThrough,
                                      )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onRetryMistakes != null && outcome.mistakes.isNotEmpty || onRestart != null) ...[
                  Row(
                    children: [
                      if (onRetryMistakes != null && outcome.mistakes.isNotEmpty)
                        Expanded(
                          child: _TonalPill(
                            icon: Icons.refresh_rounded,
                            label: 'Luyện ${outcome.mistakes.length} câu sai',
                            color: AppColors.error,
                            onTap: onRetryMistakes!,
                          ),
                        ),
                      if (onRetryMistakes != null && outcome.mistakes.isNotEmpty && onRestart != null)
                        const SizedBox(width: 10),
                      if (onRestart != null)
                        Expanded(
                          child: _TonalPill(
                            icon: Icons.replay_rounded,
                            label: 'Làm lại cả bài',
                            color: AppColors.quizBlue,
                            onTap: onRestart!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                ChunkyButton(label: exitLabel, onPressed: onExit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppColors.isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Nút phụ dạng pill nền nhạt cùng màu chữ (Luyện câu sai / Làm lại).
class _TonalPill extends StatelessWidget {
  const _TonalPill({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: AppColors.isDark ? 0.18 : 0.1),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.08),
        splashColor: color.withValues(alpha: 0.18),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill thông tin nhỏ trên màn kết quả (vd "Cấp độ ước tính: Trung bình").
class ResultPill extends StatelessWidget {
  const ResultPill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, color: color)),
    );
  }
}

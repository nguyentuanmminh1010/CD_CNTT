import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thanh trên của màn làm bài (theo UI Kit "Learn E"): nút tròn thoát, thanh tiến độ có bong bóng số câu hiện
/// tại ở đầu phần đã làm và tổng số câu ở cuối, cộng chuỗi đúng liên tiếp.
class ExerciseTopBar extends StatelessWidget {
  const ExerciseTopBar({
    super.key,
    required this.progress,
    required this.onClose,
    this.streak = 0,
    this.label,
    this.current,
    this.total,
  });

  /// 0..1.
  final double progress;
  final VoidCallback onClose;
  final int streak;

  /// Dòng nhỏ dưới thanh tiến độ (tên bài/chủ đề).
  final String? label;

  /// Số thứ tự câu đang làm / tổng số câu (hiện trong bong bóng); null = không hiện số.
  final int? current;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _CircleIconButton(icon: Icons.close_rounded, tooltip: 'Thoát', onTap: onClose),
              const SizedBox(width: 12),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress.clamp(0, 1)),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) =>
                      _ProgressTrack(value: value, current: current, total: total),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: streak >= 2
                    ? Padding(
                        key: ValueKey(streak),
                        padding: const EdgeInsets.only(left: 10),
                        child: _StreakBadge(streak: streak),
                      )
                    : const SizedBox(key: ValueKey('none'), width: 0),
              ),
            ],
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          hoverColor: AppColors.border,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentYellow.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.accentYellow, size: 17),
          const SizedBox(width: 2),
          Text('$streak',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.accentYellow,
              )),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value, this.current, this.total});

  final double value;
  final int? current;
  final int? total;

  static const _bubble = 22.0;

  @override
  Widget build(BuildContext context) {
    final showNumbers = current != null && total != null;
    return SizedBox(
      height: _bubble,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        // Tâm bong bóng chạy từ nửa bong bóng tới (cuối thanh − bong bóng tổng) để không đè lên nhau.
        final end = showNumbers ? w - _bubble * 1.5 - 4 : w;
        final x = _bubble / 2 + (end - _bubble / 2) * value;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.border),
              ),
            ),
            Container(
              width: showNumbers ? x : (w * value).clamp(10, w),
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            if (showNumbers) ...[
              Positioned(
                right: 0,
                child: _NumberBubble(text: '$total', filled: false),
              ),
              Positioned(
                left: x - _bubble / 2,
                child: _NumberBubble(text: '$current', filled: true),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _NumberBubble extends StatelessWidget {
  const _NumberBubble({required this.text, required this.filled});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: filled ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: filled
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

enum ChoiceState { idle, selected, correct, wrong, dimmed }

/// Ô đáp án nền xanh nhạt bo góc (UI Kit "Learn E"): chọn = xanh dương đặc chữ trắng, đúng = xanh lá, sai = đỏ.
/// Thu nhỏ nhẹ khi nhấn, sẫm lại khi rê chuột.
class ChoiceTile extends StatefulWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.badge,
    this.compact = false,
    this.center = false,
  });

  final String label;
  final ChoiceState state;
  final VoidCallback? onTap;

  /// Số thứ tự nhỏ bên trái (1, 2, 3...).
  final String? badge;

  /// Ô thấp hơn (Ghép cặp, chữ cái).
  final bool compact;
  final bool center;

  @override
  State<ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<ChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (widget.state) {
      ChoiceState.idle => (AppColors.quizTile, AppColors.textPrimary),
      ChoiceState.selected => (AppColors.quizBlue, Colors.white),
      ChoiceState.correct => (AppColors.success, Colors.white),
      ChoiceState.wrong => (AppColors.error, Colors.white),
      ChoiceState.dimmed => (AppColors.quizTile, AppColors.textSecondary),
    };
    final strong = widget.state == ChoiceState.selected ||
        widget.state == ChoiceState.correct ||
        widget.state == ChoiceState.wrong;
    final radius = BorderRadius.circular(widget.compact ? 14 : 16);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.state == ChoiceState.dimmed ? 0.55 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.96 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: strong
                ? [BoxShadow(color: bg.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              hoverColor: AppColors.quizBlue.withValues(alpha: 0.08),
              splashColor: (strong ? Colors.white : AppColors.quizBlue).withValues(alpha: 0.18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.compact ? 52 : 60),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 10 : 16,
                    vertical: widget.compact ? 10 : 14,
                  ),
                  child: Row(
                    children: [
                      if (widget.badge != null) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: strong
                                ? Colors.white.withValues(alpha: 0.22)
                                : AppColors.background.withValues(alpha: 0.8),
                          ),
                          child: Text(widget.badge!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: strong ? Colors.white : AppColors.quizBlue,
                              )),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.label,
                          textAlign: widget.center ? TextAlign.center : TextAlign.start,
                          style: TextStyle(
                            fontSize: widget.compact ? 14.5 : 16,
                            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
                            color: text,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (widget.state == ChoiceState.correct)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        ),
                      if (widget.state == ChoiceState.wrong)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút chính dạng viên thuốc (pill) full-width dùng cho Kiểm tra / Tiếp tục; tắt thì xám.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.shadow = const Color(0xFF1F7A4D),
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  /// Màu bóng đổ dưới nút.
  final Color shadow;
  final IconData? icon;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fill = enabled ? widget.color : AppColors.disabledFill;
    final fg = enabled ? Colors.white : AppColors.textSecondary;
    // container: true — không thì nút gộp cả cây semantics phía trên thành một "nút" (trình đọc màn hình
    // thấy cả màn hình là một nút bị tắt).
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(100),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: widget.shadow.withValues(alpha: _pressed ? 0.15 : 0.3),
                      blurRadius: _pressed ? 4 : 12,
                      offset: Offset(0, _pressed ? 1 : 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: enabled ? (v) => setState(() => _pressed = v) : null,
              hoverColor: Colors.white.withValues(alpha: 0.1),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phản hồi sau khi kiểm tra.
class FeedbackInfo {
  const FeedbackInfo({
    required this.correct,
    this.title,
    this.correctAnswer,
    this.note,
  });

  final bool correct;
  final String? title;

  /// Hiện khi trả lời sai.
  final String? correctAnswer;

  /// Nghĩa/giải thích/câu ví dụ thêm.
  final String? note;
}

/// Thanh đáy: lúc đang làm là nút "Kiểm tra" (+ "Bỏ qua"); sau khi kiểm tra hiện thẻ phản hồi xanh/đỏ (mặt cười
/// / mặt buồn, đáp án đúng, giải thích) và nút "Tiếp tục" cùng màu.
class CheckBar extends StatelessWidget {
  const CheckBar({
    super.key,
    required this.onCheck,
    required this.onContinue,
    this.feedback,
    this.onSkip,
    this.checkLabel = 'Kiểm tra',
    this.onRetry,
  });

  /// null = chưa có câu trả lời (nút xám).
  final VoidCallback? onCheck;
  final VoidCallback onContinue;
  final VoidCallback? onSkip;
  final FeedbackInfo? feedback;
  final String checkLabel;

  /// Nút "Thử lại" cạnh "Tiếp tục" khi trả lời sai (Luyện nói).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (f != null) ...[
                      _FeedbackCard(info: f),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        if (f == null && onSkip != null) ...[
                          SizedBox(
                            height: 54,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 54),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: onSkip,
                              child: Text('Bỏ qua',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (f != null && !f.correct && onRetry != null) ...[
                          SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 54),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: const StadiumBorder(),
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error, width: 1.5),
                              ),
                              onPressed: onRetry,
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text('Thử lại'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: f == null
                              ? ChunkyButton(label: checkLabel, onPressed: onCheck)
                              : ChunkyButton(
                                  key: const ValueKey('continue'),
                                  label: 'Tiếp tục',
                                  onPressed: onContinue,
                                  color: f.correct ? AppColors.success : AppColors.error,
                                  shadow: f.correct ? AppColors.success : AppColors.error,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ phản hồi bo góc nền xanh/đỏ nhạt (UI Kit: "Tuyệt vời!" / "Lỗi rồi :(").
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.info});

  final FeedbackInfo info;

  @override
  Widget build(BuildContext context) {
    final color = info.correct ? AppColors.success : AppColors.error;
    final note = info.note?.trim();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 24),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: AppColors.isDark ? 0.2 : 0.12), AppColors.background),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              info.correct ? Icons.sentiment_very_satisfied_rounded : Icons.sentiment_dissatisfied_rounded,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title ?? (info.correct ? 'Tuyệt vời!' : 'Lỗi rồi :('),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                  ),
                  if (!info.correct && info.correctAnswer != null && info.correctAnswer!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'Đáp án đúng: ',
                          style: TextStyle(fontWeight: FontWeight.w600, color: color),
                        ),
                        TextSpan(
                          text: info.correctAnswer,
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ]),
                      style: const TextStyle(fontSize: 14.5, height: 1.35),
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: color.withValues(alpha: 0.9),
                          height: 1.4,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận thoát giữa chừng. Trả về true nếu người dùng chọn thoát.
Future<bool> confirmExitExercise(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sentiment_dissatisfied_rounded, size: 42, color: AppColors.accentYellow),
              ),
            ),
            const SizedBox(height: 14),
            Text('Dừng bài giữa chừng?',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Các câu đã trả lời vẫn được lưu vào tiến độ, nhưng lượt này sẽ không có kết quả tổng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            ChunkyButton(label: 'Tiếp tục học', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 6),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48), shape: const StadiumBorder()),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thoát',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error)),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

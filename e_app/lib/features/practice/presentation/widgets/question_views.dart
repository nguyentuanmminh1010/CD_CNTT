import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../review/domain/wrong_item.dart';
import '../../../vocabulary/application/item_audio.dart';
import '../../../vocabulary/presentation/widgets/item_image.dart';
import '../../../vocabulary/presentation/widgets/word_chip.dart';
import '../../../vocabulary/presentation/widgets/word_drag.dart';
import '../../domain/practice_models.dart';
import 'exercise_chrome.dart';

// Bố cục mọi dạng câu (theo UI Kit "Learn E"): đầu trang là nhãn dạng bài + yêu cầu (căn giữa), giữa là đề
// (từ to/câu/nút nghe), cuối là vùng trả lời nằm sát nút "Kiểm tra". Engine bọc mỗi view trong khung có chiều
// cao tối thiểu = màn hình nên `MainAxisAlignment.spaceBetween` dàn ba phần ra hết chiều cao; màn thấp thì cuộn.

/// Câu trả lời đang chờ kiểm tra: [submit] gửi lên backend, [given] hiện lại cho người dùng, [correct] là
/// chấm tức thì ở client (backend vẫn chấm lại và dùng kết quả của nó cho tiến độ/điểm).
class PendingAnswer {
  const PendingAnswer({required this.submit, required this.given, required this.correct});

  final String submit;
  final String given;
  final bool correct;
}

/// Một lần ghép cặp đầu tiên của một mục (dùng để chấm — các lần thử lại sau không tính).
class MatchAttempt {
  const MatchAttempt({required this.entry, required this.meaning, required this.correct});

  final WrongItem entry;
  final String meaning;
  final bool correct;
}

/// Nhãn dạng bài (icon + tên, màu theo dạng) và câu yêu cầu, căn giữa.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.kind, required this.instruction});

  final PracticeKind kind;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    final c = kind.color;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: AppColors.isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: 14, color: c),
              const SizedBox(width: 5),
              Text(kind.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Cặp nút tròn xanh dương: nghe + nghe chậm.
class _AudioButtons extends StatelessWidget {
  const _AudioButtons({required this.text, this.audioUrl, this.size = 48});

  final String text;
  final String? audioUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ItemAudio.instance.speaking,
      builder: (context, speaking, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Đang phát thì nút chính thành "Dừng" (đặc tả: Nghe chép có play/pause).
          _RoundAudioButton(
            size: size,
            icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
            tooltip: speaking ? 'Dừng' : 'Nghe',
            onTap: () => speaking
                ? ItemAudio.instance.stop()
                : ItemAudio.instance.speak(text, audioUrl: audioUrl),
          ),
          SizedBox(width: size * 0.3),
          _RoundAudioButton(
            size: size >= 64 ? size * 0.7 : size,
            icon: Icons.slow_motion_video_rounded,
            tooltip: 'Nghe chậm',
            onTap: () => ItemAudio.instance.speak(text, audioUrl: audioUrl, slow: true),
          ),
        ],
      ),
    );
  }
}

class _RoundAudioButton extends StatefulWidget {
  const _RoundAudioButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_RoundAudioButton> createState() => _RoundAudioButtonState();
}

class _RoundAudioButtonState extends State<_RoundAudioButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.92 : 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.quizBlue.withValues(alpha: 0.3),
                blurRadius: s * 0.25,
                offset: Offset(0, s * 0.06),
              ),
            ],
          ),
          child: Material(
            color: AppColors.quizBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              hoverColor: Colors.white.withValues(alpha: 0.12),
              splashColor: Colors.white.withValues(alpha: 0.25),
              child: SizedBox(
                width: s,
                height: s,
                child: Icon(widget.icon, color: Colors.white, size: s * 0.48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Từ/câu đề lớn căn giữa, cỡ chữ giảm theo độ dài.
class _BigPrompt extends StatelessWidget {
  const _BigPrompt({super.key, required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final size = text.length > 48
        ? 19.0
        : text.length > 24
            ? 23.0
            : 32.0;
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        if (detail != null && detail!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              detail!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
      ],
    );
  }
}

/// Phần đề của câu trắc nghiệm (từ to / câu có chỗ trống / chỉ có nút nghe).
class _ChoicePrompt extends StatelessWidget {
  const _ChoicePrompt({
    required this.question,
    required this.revealed,
    required this.selected,
  });

  final ChoiceQuestion question;
  final bool revealed;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final item = q.entry.item;
    if (q.hidePrompt) {
      return Column(
        children: [
          _AudioButtons(text: q.speakText ?? q.prompt, audioUrl: item.audioUrl, size: revealed ? 48 : 84),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: revealed
                ? _BigPrompt(key: const ValueKey('shown'), text: q.prompt, detail: q.detail)
                : Text(
                    'Chạm để nghe lại · nút nhỏ để nghe chậm',
                    key: const ValueKey('hint'),
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
          ),
        ],
      );
    }
    if (q.promptIsSentence) {
      // Ô trống hiện đáp án đang chọn (xanh dương), sau khi kiểm tra hiện đáp án đúng (xanh lá).
      final fillIndex = revealed ? q.correctIndex : selected;
      return Column(
        children: [
          _SentenceWithBlank(
            text: q.prompt,
            fill: fillIndex == null ? null : q.options[fillIndex],
            fillColor: revealed ? AppColors.success : AppColors.quizBlue,
          ),
          if (q.detail != null && q.detail!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              q.detail!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
          if (q.speakText != null) ...[
            const SizedBox(height: 16),
            _AudioButtons(text: q.speakText!, audioUrl: item.audioUrl),
          ],
        ],
      );
    }
    final showImage = item.imageUrl != null && item.imageUrl!.isNotEmpty && q.kind == PracticeKind.meaning;
    return Column(
      children: [
        if (showImage) ...[
          ItemImage(url: item.imageUrl!, height: 120),
          const SizedBox(height: 16),
        ],
        _BigPrompt(text: q.prompt, detail: q.detail),
        if (q.speakText != null) ...[
          const SizedBox(height: 16),
          _AudioButtons(text: q.speakText!, audioUrl: item.audioUrl),
        ],
      ],
    );
  }
}

class _SentenceWithBlank extends StatelessWidget {
  const _SentenceWithBlank({required this.text, this.fill, this.fillColor = AppColors.quizBlue});

  final String text;
  final String? fill;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('_____');
    final base = TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.55,
    );
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 76),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: fill == null ? null : fillColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(
                      bottom: BorderSide(color: fill == null ? AppColors.textSecondary : fillColor, width: 2.5),
                    ),
                  ),
                  child: Text(
                    fill ?? ' ',
                    textAlign: TextAlign.center,
                    style: base.copyWith(color: fillColor, height: 1.3),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Khung 3 phần: đầu (yêu cầu), giữa (đề), cuối (vùng trả lời) — dàn ra hết chiều cao tối thiểu engine cấp.
class _QuestionLayout extends StatelessWidget {
  const _QuestionLayout({required this.header, required this.prompt, required this.answer});

  final Widget header;
  final Widget prompt;
  final Widget answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: prompt),
        answer,
      ],
    );
  }
}

/// Trắc nghiệm một đáp án (Trắc nghiệm, ngược, Điền chỗ trống, Nghe & chọn).
class ChoiceQuestionView extends StatefulWidget {
  const ChoiceQuestionView({
    super.key,
    required this.question,
    required this.revealed,
    required this.onAnswer,
  });

  final ChoiceQuestion question;
  final bool revealed;
  final ValueChanged<PendingAnswer?> onAnswer;

  @override
  State<ChoiceQuestionView> createState() => _ChoiceQuestionViewState();
}

class _ChoiceQuestionViewState extends State<ChoiceQuestionView> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q.autoplay && q.speakText != null) {
      // Chờ màn chuyển xong rồi mới đọc (tránh bị cắt ngang khi câu trước còn đang đọc).
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) ItemAudio.instance.speak(q.speakText!, audioUrl: q.entry.item.audioUrl);
      });
    }
  }

  void _select(int i) {
    if (widget.revealed) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
    final q = widget.question;
    widget.onAnswer(PendingAnswer(
      submit: q.answers[i],
      given: q.options[i],
      correct: i == q.correctIndex,
    ));
  }

  ChoiceState _state(int i) {
    if (!widget.revealed) return i == _selected ? ChoiceState.selected : ChoiceState.idle;
    if (i == widget.question.correctIndex) return ChoiceState.correct;
    if (i == _selected) return ChoiceState.wrong;
    return ChoiceState.dimmed;
  }

  Widget _tile(int i, {required bool grid}) => ChoiceTile(
        label: widget.question.options[i],
        badge: grid ? null : '${i + 1}',
        center: grid,
        state: _state(i),
        onTap: widget.revealed ? null : () => _select(i),
      );

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final n = q.options.length;
    final useGrid = n == 4 && q.options.every((o) => o.length <= 18);
    final Widget answers;
    if (useGrid) {
      answers = Column(
        children: [
          for (var r = 0; r < 2; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == 0 ? 12 : 0),
              child: Row(
                children: [
                  Expanded(child: SizedBox(height: 86, child: _tile(r * 2, grid: true))),
                  const SizedBox(width: 12),
                  Expanded(child: SizedBox(height: 86, child: _tile(r * 2 + 1, grid: true))),
                ],
              ),
            ),
        ],
      );
    } else {
      answers = Column(
        children: [
          for (var i = 0; i < n; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == n - 1 ? 0 : 10),
              child: _tile(i, grid: false),
            ),
        ],
      );
    }
    return _QuestionLayout(
      header: _QuestionHeader(kind: q.kind, instruction: q.instruction),
      prompt: _ChoicePrompt(question: q, revealed: widget.revealed, selected: _selected),
      answer: answers,
    );
  }
}

/// Gõ câu trả lời (Dịch câu, Nghe chép). Enter = Kiểm tra (engine xử lý qua [onSubmit]).
class TypingQuestionView extends StatefulWidget {
  const TypingQuestionView({
    super.key,
    required this.question,
    required this.revealed,
    required this.correct,
    required this.onAnswer,
    required this.onSubmit,
  });

  final TypingQuestion question;
  final bool revealed;
  final bool? correct;
  final ValueChanged<PendingAnswer?> onAnswer;
  final VoidCallback onSubmit;

  @override
  State<TypingQuestionView> createState() => _TypingQuestionViewState();
}

class _TypingQuestionViewState extends State<TypingQuestionView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q.autoplay && q.speakText != null) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) ItemAudio.instance.speak(q.speakText!, audioUrl: q.entry.item.audioUrl);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final q = widget.question;
    widget.onAnswer(text.trim().isEmpty
        ? null
        : PendingAnswer(
            submit: text,
            given: text.trim(),
            correct: normalizeTyped(text) == normalizeTyped(q.expected),
          ));
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final resultColor = switch (widget.correct) {
      true => AppColors.success,
      false => AppColors.error,
      null => null,
    };
    final listenOnly = q.prompt.isEmpty && q.speakText != null;
    return _QuestionLayout(
      header: _QuestionHeader(kind: q.kind, instruction: q.instruction),
      prompt: Column(
        children: [
          if (listenOnly)
            _AudioButtons(text: q.speakText!, audioUrl: q.entry.item.audioUrl, size: 84)
          else ...[
            _BigPrompt(text: q.prompt),
            if (q.speakText != null) ...[
              const SizedBox(height: 16),
              _AudioButtons(text: q.speakText!, audioUrl: q.entry.item.audioUrl),
            ],
          ],
          if (q.hint != null) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showHint || widget.revealed
                  ? Text(
                      q.hint!,
                      key: const ValueKey('hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 14.5,
                      ),
                    )
                  : TextButton.icon(
                      key: const ValueKey('btn'),
                      style: TextButton.styleFrom(shape: const StadiumBorder()),
                      onPressed: () => setState(() => _showHint = true),
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      label: const Text('Xem gợi ý nghĩa'),
                    ),
            ),
          ],
        ],
      ),
      answer: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: !widget.revealed,
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: _changed,
        onSubmitted: (_) => widget.onSubmit(),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: resultColor ?? AppColors.textPrimary,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Gõ câu trả lời bằng tiếng Anh...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: resultColor == null
              ? AppColors.surface
              : Color.alphaBlend(resultColor.withValues(alpha: 0.08), AppColors.background),
          contentPadding: const EdgeInsets.all(18),
          enabledBorder: _border(Colors.transparent, 2),
          disabledBorder: _border(resultColor ?? Colors.transparent, 2),
          focusedBorder: _border(AppColors.quizBlue, 2),
        ),
      ),
    );
  }
}

/// Ô chữ cái để chạm (Đánh vần).
class _LetterTile extends StatefulWidget {
  const _LetterTile({required this.letter, required this.onTap});

  final String letter;
  final VoidCallback? onTap;

  @override
  State<_LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<_LetterTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      label: widget.letter.toUpperCase(),
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _pressed ? 0.9 : 1,
      child: Material(
        color: AppColors.quizTile,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          hoverColor: AppColors.quizBlue.withValues(alpha: 0.1),
          splashColor: AppColors.quizBlue.withValues(alpha: 0.2),
          child: SizedBox(
            width: 46,
            height: 50,
            child: Center(
              child: Text(
                widget.letter.toUpperCase(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Đánh vần: chạm chữ cái để ghép vào ô, chạm ô đã điền để trả chữ về.
class SpellingQuestionView extends StatefulWidget {
  const SpellingQuestionView({
    super.key,
    required this.question,
    required this.revealed,
    required this.correct,
    required this.onAnswer,
  });

  final SpellingQuestion question;
  final bool revealed;
  final bool? correct;
  final ValueChanged<PendingAnswer?> onAnswer;

  @override
  State<SpellingQuestionView> createState() => _SpellingQuestionViewState();
}

class _SpellingQuestionViewState extends State<SpellingQuestionView> {
  /// Chỉ số (trong `letters`) của các chữ đã chọn, theo thứ tự.
  final List<int> _picked = [];

  void _notify() {
    final q = widget.question;
    if (_picked.length < q.letters.length) {
      widget.onAnswer(null);
      return;
    }
    final word = q.assemble([for (final i in _picked) q.letters[i]]);
    widget.onAnswer(PendingAnswer(
      submit: word,
      given: word,
      correct: normalizeTyped(word) == normalizeTyped(q.target),
    ));
  }

  void _pick(int i) {
    if (widget.revealed || _picked.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _picked.add(i));
    _notify();
  }

  void _unpick(int slot) {
    if (widget.revealed || slot >= _picked.length) return;
    setState(() => _picked.removeAt(slot));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final item = q.entry.item;
    final (Color slotBg, Color slotText) = switch (widget.correct) {
      true => (AppColors.success, Colors.white),
      false => (AppColors.error, Colors.white),
      null => (AppColors.quizTile, AppColors.textPrimary),
    };
    const gap = 5.0;
    const wordGap = 18.0;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return _QuestionLayout(
      header: _QuestionHeader(kind: q.kind, instruction: q.instruction),
      prompt: Column(
        children: [
          if (hasImage) ...[
            ItemImage(url: item.imageUrl!, height: 120),
            const SizedBox(height: 16),
          ],
          _BigPrompt(text: item.meaning),
          const SizedBox(height: 16),
          _AudioButtons(text: item.term, audioUrl: item.audioUrl),
        ],
      ),
      answer: Column(
        children: [
          LayoutBuilder(builder: (context, c) {
            // Ô co lại để cả từ nằm trên một hàng (từ dài tới 14 chữ trên màn 360px).
            final letters = q.letters.length;
            final gaps = gap * (letters - q.groups.length) + wordGap * (q.groups.length - 1);
            final slotWidth = ((c.maxWidth - gaps) / letters).clamp(20.0, 40.0);
            var slot = 0;
            return Wrap(
              spacing: wordGap,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final len in q.groups)
                  Wrap(
                    spacing: gap,
                    children: [
                      for (var k = 0; k < len; k++)
                        () {
                          final s = slot++;
                          final filled = s < _picked.length;
                          // Ô trống = vạch gạch dưới; ô đã điền = ô chữ nền xanh nhạt (đúng/sai: xanh lá/đỏ).
                          return GestureDetector(
                            onTap: filled ? () => _unpick(s) : null,
                            child: SizedBox(
                              width: slotWidth,
                              height: 48,
                              child: filled
                                  ? AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: slotBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        q.letters[_picked[s]].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: slotWidth < 28 ? 15 : 18,
                                          fontWeight: FontWeight.w800,
                                          color: slotText,
                                        ),
                                      ),
                                    )
                                  : Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 2.5,
                                        decoration: BoxDecoration(
                                          color: AppColors.textSecondary.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }(),
                    ],
                  ),
              ],
            );
          }),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < q.letters.length; i++)
                // Chữ đã chọn để lại chỗ trống (giữ nguyên vị trí các chữ còn lại).
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _picked.contains(i) ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _picked.contains(i),
                    child: ExcludeSemantics(
                      excluding: _picked.contains(i),
                      child: _LetterTile(
                        letter: q.letters[i],
                        onTap: widget.revealed ? null : () => _pick(i),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 44,
            child: !widget.revealed && _picked.isNotEmpty
                ? TextButton.icon(
                    style: TextButton.styleFrom(shape: const StadiumBorder()),
                    onPressed: () {
                      setState(_picked.clear);
                      _notify();
                    },
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Xoá hết'),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Nền kẻ dòng như vở cho khu câu trả lời Sắp xếp câu: mỗi dòng cao [lineHeight], chip nằm trên vạch.
class _RuledLinesPainter extends CustomPainter {
  const _RuledLinesPainter({required this.color, required this.lineHeight});

  final Color color;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var y = lineHeight - 4; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RuledLinesPainter old) => old.color != color || old.lineHeight != lineHeight;
}

/// Sắp xếp câu: chạm hoặc kéo-thả các từ vào khung câu.
class WordOrderQuestionView extends StatefulWidget {
  const WordOrderQuestionView({
    super.key,
    required this.question,
    required this.revealed,
    required this.correct,
    required this.onAnswer,
  });

  final WordOrderPracticeQuestion question;
  final bool revealed;
  final bool? correct;
  final ValueChanged<PendingAnswer?> onAnswer;

  @override
  State<WordOrderQuestionView> createState() => _WordOrderQuestionViewState();
}

class _WordOrderQuestionViewState extends State<WordOrderQuestionView> {
  static const _line = 56.0; // = chiều cao chip (44) + khoảng cách dòng (12)

  final List<String> _placed = [];
  late final List<String> _pool = List.of(widget.question.shuffledWords);

  void _notify() {
    if (_pool.isNotEmpty) {
      widget.onAnswer(null);
      return;
    }
    final q = widget.question;
    final sentence = _placed.join(' ');
    widget.onAnswer(PendingAnswer(
      submit: sentence,
      given: sentence,
      correct: sentence == q.correctWords.join(' '),
    ));
  }

  void _update(VoidCallback change) {
    if (widget.revealed) return;
    HapticFeedback.selectionClick();
    setState(change);
    _notify();
  }

  void _drop(WordDrag d, {int? insertAt}) => _update(() {
        final word = d.fromPool ? _pool.removeAt(d.index) : _placed.removeAt(d.index);
        var at = insertAt ?? _placed.length;
        if (!d.fromPool && insertAt != null && d.index < insertAt) at -= 1;
        _placed.insert(at.clamp(0, _placed.length), word);
      });

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final enabled = !widget.revealed;
    final chipState = switch (widget.correct) {
      true => WordChipState.correct,
      false => WordChipState.wrong,
      null => WordChipState.placed,
    };
    return _QuestionLayout(
      header: _QuestionHeader(kind: q.kind, instruction: q.instruction),
      prompt: _BigPrompt(text: q.entry.item.meaning),
      answer: Column(
        children: [
          WordDropTarget(
            enabled: enabled,
            onDrop: (d) => _drop(d),
            builder: (hovering) => CustomPaint(
              painter: _RuledLinesPainter(
                color: hovering ? AppColors.quizBlue : AppColors.border,
                lineHeight: _line,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: _line * 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < _placed.length; i++)
                      WordDropTarget(
                        enabled: enabled,
                        onDrop: (d) => _drop(d, insertAt: i),
                        builder: (_) => DraggableWordChip(
                          drag: WordDrag(fromPool: false, index: i, label: _placed[i]),
                          enabled: enabled,
                          label: _placed[i],
                          state: chipState,
                          onTap: () => _update(() => _pool.add(_placed.removeAt(i))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          WordDropTarget(
            enabled: enabled,
            onDrop: (d) {
              if (!d.fromPool) _update(() => _pool.add(_placed.removeAt(d.index)));
            },
            builder: (hovering) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hovering ? AppColors.quizBlue.withValues(alpha: 0.06) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _pool.length; i++)
                    DraggableWordChip(
                      drag: WordDrag(fromPool: true, index: i, label: _pool[i]),
                      enabled: enabled,
                      label: _pool[i],
                      state: WordChipState.pool,
                      onTap: () => _update(() => _placed.add(_pool.removeAt(i))),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghép cặp: chạm một mục bên trái và một nghĩa bên phải. Đúng thì cả hai loé xanh rồi mờ đi; sai thì nháy đỏ.
class MatchingQuestionView extends StatefulWidget {
  const MatchingQuestionView({super.key, required this.question, required this.onComplete});

  final MatchingQuestion question;

  /// Gọi một lần khi đã ghép xong tất cả: lần ghép ĐẦU TIÊN của mỗi mục (để chấm) + số lần sai.
  final void Function(List<MatchAttempt> firstAttempts, int mistakes) onComplete;

  @override
  State<MatchingQuestionView> createState() => _MatchingQuestionViewState();
}

class _MatchingQuestionViewState extends State<MatchingQuestionView> {
  int? _left;
  int? _right; // vị trí trong rightOrder
  final Set<int> _done = {};
  final Map<int, MatchAttempt> _first = {};
  (int, int)? _wrongFlash;
  int? _okFlash; // chỉ số cặp vừa ghép đúng (loé xanh)
  int _mistakes = 0;
  Timer? _flashTimer;
  Timer? _okTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _okTimer?.cancel();
    super.dispose();
  }

  void _tryMatch() {
    final l = _left;
    final r = _right;
    if (l == null || r == null) return;
    final q = widget.question;
    final pairIndex = q.rightOrder[r];
    final ok = pairIndex == l;
    // Chấm theo lần chọn đầu của mục bên trái (gửi nghĩa đã chọn để backend chấm).
    _first.putIfAbsent(
      l,
      () => MatchAttempt(entry: q.pairs[l], meaning: q.pairs[pairIndex].item.meaning, correct: ok),
    );
    if (ok) {
      HapticFeedback.lightImpact();
      setState(() {
        _done.add(l);
        _okFlash = l;
        _left = null;
        _right = null;
      });
      _okTimer?.cancel();
      _okTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _okFlash = null);
      });
      if (_done.length == q.pairs.length) {
        widget.onComplete(_first.values.toList(), _mistakes);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _mistakes++;
        _wrongFlash = (l, r);
        _left = null;
        _right = null;
      });
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 550), () {
        if (mounted) setState(() => _wrongFlash = null);
      });
    }
  }

  ChoiceState _leftState(int i) {
    if (_okFlash == i) return ChoiceState.correct;
    if (_done.contains(i)) return ChoiceState.dimmed;
    if (_wrongFlash?.$1 == i) return ChoiceState.wrong;
    return _left == i ? ChoiceState.selected : ChoiceState.idle;
  }

  ChoiceState _rightState(int pos) {
    final pairIndex = widget.question.rightOrder[pos];
    if (_okFlash == pairIndex) return ChoiceState.correct;
    if (_done.contains(pairIndex)) return ChoiceState.dimmed;
    if (_wrongFlash?.$2 == pos) return ChoiceState.wrong;
    return _right == pos ? ChoiceState.selected : ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return _QuestionLayout(
      header: _QuestionHeader(kind: q.kind, instruction: q.instruction),
      prompt: Text(
        'Đã ghép ${_done.length}/${q.pairs.length} cặp',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
      answer: Column(
        children: [
          for (var i = 0; i < q.pairs.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == q.pairs.length - 1 ? 0 : 12),
              // Hai ô cùng hàng cao bằng nhau dù nghĩa dài hơn từ.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ChoiceTile(
                        label: q.pairs[i].item.term,
                        compact: true,
                        center: true,
                        state: _leftState(i),
                        onTap: _done.contains(i)
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _left = i);
                                _tryMatch();
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceTile(
                        label: q.pairs[q.rightOrder[i]].item.meaning,
                        compact: true,
                        center: true,
                        state: _rightState(i),
                        onTap: _done.contains(q.rightOrder[i])
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _right = i);
                                _tryMatch();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

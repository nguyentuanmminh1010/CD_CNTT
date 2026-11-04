import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../answers/application/answer_providers.dart';
import '../../answers/data/answer_repository.dart';
import '../../attempts/application/attempt_providers.dart';
import '../../attempts/domain/attempt.dart';
import '../../review/domain/wrong_item.dart';
import '../../skills/application/skill_providers.dart';
import '../../skills/domain/skill_type.dart';
import '../../vocabulary/application/item_audio.dart';
import '../application/practice_builder.dart';
import '../domain/practice_models.dart';
import 'widgets/exercise_chrome.dart';
import 'widgets/practice_result_view.dart';
import 'widgets/question_views.dart';

/// Cấu hình một lượt làm bài trên engine chung.
class PracticeConfig {
  const PracticeConfig({
    required this.title,
    required this.kind,
    required this.load,
    this.limit,
    this.keepOrder = false,
    this.skill,
    this.attemptType,
    this.attemptTitle,
    this.refKey,
    this.onExit,
    this.exitLabel = 'Hoàn thành',
    this.resultExtras,
    this.onAnswered,
    this.allowRetry = true,
    this.emptyMessage = 'Chưa đủ nội dung để làm dạng bài này.',
  });

  /// Tên hiện ở thanh trên và màn kết quả.
  final String title;
  final PracticeKind kind;

  /// Lấy các mục làm đề (một chủ đề, lỗi sai, đề đánh giá...).
  final Future<List<WrongItem>> Function(WidgetRef ref) load;
  final int? limit;

  /// Giữ thứ tự đề (backend đã sắp độ khó) thay vì xáo trộn.
  final bool keepOrder;

  /// Kỹ năng cộng cho MỌI câu (vd Luyện Đọc); null = theo từng dạng câu (Nghe/Viết...).
  final SkillType? skill;

  /// Khác null thì kết thúc lượt bằng `finishAttempt` (vào lịch sử bài kiểm tra, backend tính điểm).
  final AttemptType? attemptType;
  final String? attemptTitle;
  final String? refKey;

  /// Rời màn (mặc định `context.pop()`).
  final VoidCallback? onExit;
  final String exitLabel;

  /// Phần thêm ở màn kết quả; [attemptId] là id lượt đã lưu (null nếu chưa/không lưu).
  final List<Widget> Function(BuildContext context, PracticeOutcome outcome, String? attemptId)?
      resultExtras;

  /// Gọi sau khi chấm một mục (vd gỡ khỏi danh sách lỗi sai khi trả lời đúng).
  final void Function(WidgetRef ref, WrongItem entry, bool correct)? onAnswered;

  /// Cho phép "Làm lại"/"Luyện lại câu sai" (tắt cho bài kiểm tra để giữ kết quả).
  final bool allowRetry;
  final String emptyMessage;
}

/// Màn làm bài chung kiểu Duolingo: chọn/nhập câu trả lời → "Kiểm tra" → bảng phản hồi trượt lên ở đáy
/// (đúng/sai, đáp án, giải thích) → "Tiếp tục". Mọi câu trả lời gửi lên backend để chấm (`submitAnswer`).
class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key, required this.config});

  final PracticeConfig config;

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  static const _praise = ['Chính xác!', 'Tuyệt vời!', 'Giỏi quá!', 'Đúng rồi!', 'Xuất sắc!'];

  final _rng = Random();
  late Future<void> _loading;
  List<WrongItem> _entries = const [];
  List<PracticeQuestion> _questions = const [];
  late AttemptSession _session;

  int _round = 0;
  int _index = 0;
  PendingAnswer? _pending;
  FeedbackInfo? _feedback;
  int _streak = 0;
  int _bestStreak = 0;
  int _correct = 0;
  int _graded = 0;
  final List<PracticeMistake> _mistakes = [];
  DateTime _startedAt = DateTime.now();
  PracticeOutcome? _outcome;
  bool _recordAttempt = true;
  String? _savedAttemptId;

  PracticeConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _session = AttemptSession(ref.read(answerRepositoryProvider));
    _loading = _load();
  }

  @override
  void dispose() {
    ItemAudio.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _config.load(ref);
    _entries = entries;
    _questions = buildPractice(entries, _config.kind,
        limit: _config.limit, keepOrder: _config.keepOrder, random: _rng);
    _startedAt = DateTime.now();
  }

  void _start(List<WrongItem> entries, {required bool record}) {
    ItemAudio.instance.stop();
    setState(() {
      _session = AttemptSession(ref.read(answerRepositoryProvider));
      _questions = buildPractice(entries, _config.kind, random: _rng);
      _round++;
      _index = 0;
      _pending = null;
      _feedback = null;
      _streak = 0;
      _bestStreak = 0;
      _correct = 0;
      _graded = 0;
      _mistakes.clear();
      _outcome = null;
      _savedAttemptId = null;
      _recordAttempt = record;
      _startedAt = DateTime.now();
    });
  }

  // ---- Chấm ----

  AnswerMode _modeOf(PracticeQuestion q) => switch (q) {
        ChoiceQuestion(:final mode) => mode,
        TypingQuestion() => AnswerMode.term,
        SpellingQuestion() => AnswerMode.term,
        WordOrderPracticeQuestion() => AnswerMode.sentence,
        MatchingQuestion() => AnswerMode.meaning,
      };

  String _correctAnswerOf(PracticeQuestion q) => switch (q) {
        ChoiceQuestion(:final answers, :final options, :final correctIndex, :final kind) =>
          kind == PracticeKind.cloze && answers[correctIndex] != options[correctIndex]
              ? answers[correctIndex]
              : options[correctIndex],
        TypingQuestion(:final expected) => expected,
        SpellingQuestion(:final target) => target,
        WordOrderPracticeQuestion(:final correctWords) => correctWords.join(' '),
        MatchingQuestion() => '',
      };

  String? _noteOf(PracticeQuestion q) {
    final item = q.entries.first.item;
    switch (q.kind) {
      case PracticeKind.listen:
      case PracticeKind.dictation:
        return '${item.term} — ${item.meaning}';
      case PracticeKind.meaning:
        final explanation = item.explanation?.trim();
        if (explanation != null && explanation.isNotEmpty) return explanation;
        return item.example;
      case PracticeKind.matching:
        return null;
      default:
        return '${item.term} — ${item.meaning}';
    }
  }

  void _grade(WrongItem e, PracticeQuestion q, String submit, String given, bool correct) {
    _graded++;
    if (correct) {
      _correct++;
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
    } else {
      _streak = 0;
      _mistakes.add(PracticeMistake(
        entry: e,
        given: given,
        correctAnswer: q is MatchingQuestion ? e.item.meaning : _correctAnswerOf(q),
      ));
    }
    _session.submit(
      itemId: e.item.id,
      mode: _modeOf(q),
      answer: submit,
      skill: _config.skill ?? q.skill,
    );
    _config.onAnswered?.call(ref, e, correct);
  }

  void _check() {
    final p = _pending;
    if (p == null || _feedback != null || _outcome != null) return;
    final q = _questions[_index];
    _grade(q.entries.single, q, p.submit, p.given, p.correct);
    p.correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _feedback = FeedbackInfo(
        correct: p.correct,
        title: p.correct ? _praise[_rng.nextInt(_praise.length)] : null,
        correctAnswer: p.correct ? null : _correctAnswerOf(q),
        note: _noteOf(q),
      );
    });
  }

  void _skip() {
    if (_feedback != null) return;
    final q = _questions[_index];
    _grade(q.entries.single, q, '', '', false);
    HapticFeedback.heavyImpact();
    setState(() {
      _feedback = FeedbackInfo(
        correct: false,
        title: 'Đã bỏ qua',
        correctAnswer: _correctAnswerOf(q),
        note: _noteOf(q),
      );
    });
  }

  void _matchingDone(MatchingQuestion q, List<MatchAttempt> attempts, int mistakes) {
    for (final a in attempts) {
      _grade(a.entry, q, a.meaning, a.meaning, a.correct);
    }
    setState(() {
      _feedback = FeedbackInfo(
        correct: mistakes == 0,
        title: mistakes == 0 ? 'Ghép đúng tất cả!' : 'Đã ghép xong',
        note: mistakes == 0 ? null : 'Sai $mistakes lần — các cặp sai sẽ có trong mục "Cần ôn lại".',
      );
    });
  }

  void _continue() {
    if (_feedback == null) return;
    ItemAudio.instance.stop();
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _pending = null;
      _feedback = null;
    });
  }

  Future<void> _finish() async {
    setState(() {
      _outcome = PracticeOutcome(
        correct: _correct,
        total: _graded,
        bestStreak: _bestStreak,
        elapsed: DateTime.now().difference(_startedAt),
        mistakes: List.of(_mistakes),
      );
    });
    final type = _config.attemptType;
    if (type == null || !_recordAttempt) return;
    final container = ProviderScope.containerOf(context, listen: false);
    await _session.settle();
    final saved = await saveAttempt(
      container,
      type: type,
      title: _config.attemptTitle ?? _config.title,
      attemptKey: _session.key,
      expectedTotal: _graded,
      refKey: _config.refKey,
    );
    if (mounted && saved != null) setState(() => _savedAttemptId = saved.id);
  }

  // ---- Rời màn ----

  void _invalidate() {
    invalidateAfterAnswers(ref.invalidate);
    invalidateAttemptData(ref.invalidate);
    ref.invalidate(skillMasteryProvider);
  }

  void _leave() {
    ItemAudio.instance.stop();
    _invalidate();
    if (_config.onExit != null) {
      _config.onExit!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      // Mở thẳng bằng đường dẫn (deep link/thông báo): không có gì để pop.
      context.go(AppRoutes.home);
    }
  }

  Future<void> _close() async {
    if (_outcome == null && _graded > 0) {
      if (!await confirmExitExercise(context)) return;
      if (!mounted) return;
    }
    _leave();
  }

  // ---- Giao diện ----

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _outcome != null || _graded == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ItemAudio.instance.stop();
          _invalidate();
        } else {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<void>(
            future: _loading,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _shell(const Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return _shell(_message(
                  icon: Icons.cloud_off_rounded,
                  text: 'Không tải được bài. Kiểm tra kết nối rồi thử lại.',
                  action: OutlinedButton(
                    onPressed: () => setState(() => _loading = _load()),
                    child: const Text('Thử lại'),
                  ),
                ));
              }
              if (_questions.isEmpty) {
                return _shell(_message(
                  icon: Icons.info_outline_rounded,
                  text: _config.emptyMessage,
                  action: OutlinedButton(onPressed: _leave, child: const Text('Quay lại')),
                ));
              }
              if (_outcome != null) return _result(_outcome!);
              return _buildSession();
            },
          ),
        ),
      ),
    );
  }

  Widget _constrained(Widget child) => Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
      );

  Widget _shell(Widget body) => Column(
        children: [
          _constrained(ExerciseTopBar(progress: 0, onClose: _leave, label: _config.title)),
          Expanded(child: body),
        ],
      );

  Widget _message({required IconData icon, required String text, required Widget action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }

  Widget _result(PracticeOutcome outcome) {
    final retry = _config.allowRetry;
    final mistakeEntries = {
      for (final m in outcome.mistakes) m.entry.item.id: m.entry,
    }.values.toList();
    return _constrained(PracticeResultView(
      title: _config.title,
      outcome: outcome,
      exitLabel: _config.exitLabel,
      onExit: _leave,
      onRestart: retry ? () => _start(_entries, record: false) : null,
      onRetryMistakes: retry && mistakeEntries.isNotEmpty
          ? () => _start(mistakeEntries, record: false)
          : null,
      extras: _config.resultExtras?.call(context, outcome, _savedAttemptId) ?? const [],
    ));
  }

  Widget _buildSession() {
    final q = _questions[_index];
    final revealed = _feedback != null;
    final progress = (_index + (revealed ? 1 : 0)) / _questions.length;
    final view = switch (q) {
      ChoiceQuestion() => ChoiceQuestionView(
          question: q,
          revealed: revealed,
          onAnswer: (a) => setState(() => _pending = a),
        ),
      TypingQuestion() => TypingQuestionView(
          question: q,
          revealed: revealed,
          correct: _feedback?.correct,
          onAnswer: (a) => setState(() => _pending = a),
          onSubmit: () => revealed ? _continue() : _check(),
        ),
      SpellingQuestion() => SpellingQuestionView(
          question: q,
          revealed: revealed,
          correct: _feedback?.correct,
          onAnswer: (a) => setState(() => _pending = a),
        ),
      WordOrderPracticeQuestion() => WordOrderQuestionView(
          question: q,
          revealed: revealed,
          correct: _feedback?.correct,
          onAnswer: (a) => setState(() => _pending = a),
        ),
      MatchingQuestion() => MatchingQuestionView(
          question: q,
          onComplete: (attempts, mistakes) => _matchingDone(q, attempts, mistakes),
        ),
    };
    final isMatching = q is MatchingQuestion;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (revealed) {
            _continue();
            return KeyEventResult.handled;
          }
          if (_pending != null) {
            _check();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          _constrained(ExerciseTopBar(
            progress: progress,
            onClose: _close,
            streak: _streak,
            current: _index + 1,
            total: _questions.length,
            label: _config.title,
          )),
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _constrained(
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    // Chiều cao tối thiểu = vùng nhìn thấy: view dàn đề ra giữa, đáp án xuống sát nút Kiểm tra.
                    child: KeyedSubtree(
                      key: ValueKey('q$_round-$_index'),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: max(0, viewport.maxHeight - 32)),
                        child: view,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!isMatching || revealed)
            CheckBar(
              feedback: _feedback,
              onCheck: _pending == null ? null : _check,
              onSkip: isMatching ? null : _skip,
              onContinue: _continue,
            ),
        ],
      ),
    );
  }
}

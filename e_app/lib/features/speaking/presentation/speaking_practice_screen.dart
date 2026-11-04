import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../answers/application/answer_providers.dart';
import '../../answers/data/answer_repository.dart';
import '../../attempts/application/attempt_providers.dart';
import '../../attempts/domain/attempt.dart';
import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/widgets/exercise_chrome.dart';
import '../../practice/presentation/widgets/practice_result_view.dart';
import '../../progress/application/progress_providers.dart';
import '../../review/application/review_providers.dart';
import '../../review/domain/wrong_item.dart';
import '../../skills/application/skill_providers.dart';
import '../../skills/domain/skill_type.dart';
import '../../vocabulary/presentation/widgets/speak_button.dart';
import '../application/speech_matcher.dart';
import 'widgets/voice_compare_card.dart';

/// Luyện nói (kỹ năng "Nói"): hiện một câu mẫu tiếng Anh + nghĩa tiếng Việt,
/// người dùng bấm micro đọc câu đó; `speech_to_text` nhận diện on-device rồi
/// so khớp văn bản đơn giản với câu mẫu ([isSpeechCorrect]). Nếu thiết bị/
/// trình duyệt không hỗ trợ hoặc chưa cấp quyền micro thì cho **nhập tay** câu
/// đã nói để vẫn luyện được. Mỗi câu gửi `submitAnswer(mode: SPOKEN, skill: SPEAKING)` để backend
/// chấm, cuối lượt ghi một `Attempt` SPEAKING vào lịch sử. Dùng chung khung giao diện với engine làm bài
/// (`ExerciseTopBar`, `CheckBar`, `PracticeResultView`) nhưng giữ luồng micro riêng.
class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  ConsumerState<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends ConsumerState<SpeakingPracticeScreen> {
  static const _questionCount = 8;

  final _speech = stt.SpeechToText();
  final _manual = TextEditingController();
  late final Future<List<WrongItem>> _future;

  bool _speechReady = false;
  bool _listening = false;
  String? _speechError;
  bool _manualMode = false;

  int _index = 0;
  int _total = 0;
  late final AttemptSession _session = AttemptSession(ref.read(answerRepositoryProvider));
  int _correctCount = 0;
  String _heard = '';
  DateTime? _listenStart;
  Duration? _spoken;
  bool _checked = false;
  bool _correct = false;
  double _similarity = 0;
  int _streak = 0;
  int _bestStreak = 0;
  final DateTime _startedAt = DateTime.now();
  final Map<String, PracticeMistake> _mistakes = {};

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(attemptRepositoryProvider)
        .fetchAssessmentItems(
          category: ReviewCategory.sentence,
          minDifficulty: 1,
          maxDifficulty: 3,
          limit: _questionCount,
        )
        .then((items) {
      _total = items.length;
      return items;
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.cancel();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _speechError = e.errorMsg;
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _speechReady = ok;
        if (!ok) _manualMode = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _manualMode = true;
      });
    }
  }

  Future<void> _toggleListen(WrongItem item) async {
    if (_checked) return;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      _evaluate(item, _heard);
      return;
    }
    setState(() {
      _heard = '';
      _speechError = null;
      _listening = true;
      _listenStart = DateTime.now();
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en_US',
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _heard = r.recognizedWords);
        if (r.finalResult && !_checked) _evaluate(item, r.recognizedWords);
      },
    );
  }

  void _evaluate(WrongItem item, String spoken) {
    if (_checked) return;
    if (spoken.trim().isEmpty) {
      setState(() => _speechError = 'Chưa nghe thấy gì — hãy thử nói lại.');
      return;
    }
    final started = _listenStart;
    _spoken = started == null ? null : DateTime.now().difference(started);
    final similarity = speechSimilarity(spoken, item.item.term);
    final correct = similarity >= speechPassRatio;
    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _heard = spoken;
      _similarity = similarity;
      _checked = true;
      _correct = correct;
      _listening = false;
      if (correct) {
        _correctCount += 1;
        _streak += 1;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _mistakes.remove(item.item.id);
      } else {
        _streak = 0;
        _mistakes[item.item.id] =
            PracticeMistake(entry: item, given: spoken, correctAnswer: item.item.term);
      }
    });
    // Backend chấm lại bằng cùng thuật toán so khớp từ (client chỉ phản hồi tức thì).
    _session.submit(
      itemId: item.item.id,
      mode: AnswerMode.spoken,
      answer: spoken,
      skill: SkillType.speaking,
    );
  }

  void _retry() {
    setState(() {
      _checked = false;
      _correct = false;
      _heard = '';
      _spoken = null;
      _manual.clear();
    });
  }

  void _next() {
    setState(() {
      _index += 1;
      _checked = false;
      _correct = false;
      _heard = '';
      _spoken = null;
      _speechError = null;
      _manual.clear();
    });
    if (_index >= _total) {
      final container = ProviderScope.containerOf(context, listen: false);
      _session.settle().then((_) => saveAttempt(
            container,
            type: AttemptType.speaking,
            title: 'Luyện Nói',
            attemptKey: _session.key,
            expectedTotal: _total,
          ));
    }
  }

  void _goBack() {
    _speech.cancel();
    invalidateAttemptData(ref.invalidate);
    ref.invalidate(activityProvider);
    ref.invalidate(masteryOverviewProvider);
    ref.invalidate(wrongItemsProvider);
    ref.invalidate(skillMasteryProvider);
    // Mở thẳng bằng đường dẫn (deep link/thông báo) thì không có gì để pop.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: FutureBuilder<List<WrongItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Không tải được bài luyện Nói.'),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _goBack, child: const Text('Quay lại')),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildBody(context, snapshot.data!);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<WrongItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chưa có câu mẫu để luyện nói.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _goBack, child: const Text('Quay lại')),
          ],
        ),
      );
    }
    if (_index >= items.length) return _buildResult(context);

    final item = items[_index];
    return Column(
      children: [
        ExerciseTopBar(
          progress: (_index + (_checked ? 1 : 0)) / items.length,
          onClose: _close,
          streak: _streak,
          current: _index + 1,
          total: items.length,
          label: 'Luyện Nói',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Đọc to câu sau',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 18),
                // Bong bóng câu mẫu (UI Kit: thẻ xanh nhạt, chữ to căn giữa, nút nghe xanh dương).
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    color: AppColors.quizTile,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(item.item.term,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: item.item.term.length > 40 ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.3)),
                      const SizedBox(height: 6),
                      Text(item.item.meaning,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 14),
                      SpeakButton(
                        text: item.item.term,
                        audioUrl: item.item.audioUrl,
                        size: 48,
                        color: AppColors.quizBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_manualMode) ..._micSection(item) else ..._manualSection(item),
                if (_speechError != null && !_checked) ...[
                  const SizedBox(height: 12),
                  Text(_speechError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                if (_checked) ...[
                  const SizedBox(height: 20),
                  _Feedback(
                    correct: _correct,
                    heard: _heard,
                    percent: (_similarity * 100).round(),
                    target: item.item.term,
                    pace: _spoken == null ? null : speakingPace(_heard, _spoken!),
                  ),
                ],
                const SizedBox(height: 20),
                VoiceCompareCard(
                  key: ValueKey('voice-${item.item.id}'),
                  sample: item.item.term,
                  audioUrl: item.item.audioUrl,
                ),
                if (!_checked && _speechReady) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _manualMode = !_manualMode),
                    child: Text(_manualMode ? 'Dùng micro' : 'Nhập tay thay vì nói'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_checked)
          CheckBar(
            feedback: FeedbackInfo(
              correct: _correct,
              title: _correct ? 'Phát âm tốt!' : 'Chưa khớp',
              note: 'Khớp ${(_similarity * 100).round()}% với câu mẫu',
            ),
            onCheck: null,
            onContinue: _next,
            onRetry: _retry,
          )
        else if (_manualMode)
          CheckBar(
            onCheck: _manual.text.trim().isEmpty ? null : () => _evaluate(item, _manual.text),
            onContinue: _next,
            onSkip: () => _evaluate(item, '-'),
          ),
      ],
    );
  }

  Future<void> _close() async {
    if (_index > 0 || _checked) {
      if (!await confirmExitExercise(context)) return;
      if (!mounted) return;
    }
    _goBack();
  }

  List<Widget> _micSection(WrongItem item) {
    return [
      Center(
        child: Material(
          color: _listening ? AppColors.error : AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _checked ? null : () => _toggleListen(item),
            hoverColor: Colors.white24,
            splashColor: Colors.white38,
            child: SizedBox(
              width: 88,
              height: 88,
              child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white, size: 40),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _listening
            ? 'Đang nghe... bấm để dừng'
            : _checked
                ? ''
                : 'Bấm micro rồi đọc to câu trên',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      if (_listening || _heard.isNotEmpty && !_checked) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_heard.isEmpty ? '...' : _heard,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        ),
      ],
    ];
  }

  List<Widget> _manualSection(WrongItem item) {
    return [
      if (!_speechReady)
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Thiết bị này chưa dùng được micro/nhận diện giọng nói (hoặc chưa cấp quyền). Bạn có thể gõ lại câu mình đọc để luyện.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      TextField(
        controller: _manual,
        enabled: !_checked,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Nhập câu bạn vừa nói...'),
      ),
    ];
  }

  Widget _buildResult(BuildContext context) {
    return PracticeResultView(
      title: 'Luyện Nói',
      outcome: PracticeOutcome(
        correct: _correctCount,
        total: _total,
        bestStreak: _bestStreak,
        elapsed: DateTime.now().difference(_startedAt),
        mistakes: _mistakes.values.toList(),
      ),
      onExit: _goBack,
      exitLabel: 'Quay lại',
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.correct,
    required this.heard,
    required this.percent,
    required this.target,
    this.pace,
  });

  final bool correct;
  final String heard;
  final int percent;
  final String target;
  final int? pace;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
              const SizedBox(width: 8),
              Text(correct ? 'Chính xác! ($percent%)' : 'Chưa khớp ($percent%)',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Bạn nói: $heard',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final w in compareWords(heard, target))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (w.matched ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(w.word,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: w.matched ? AppColors.success : AppColors.error,
                          decoration: w.matched ? null : TextDecoration.lineThrough)),
                ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 6),
            Text('Câu mẫu: $target',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          ],
          if (pace != null) ...[
            const SizedBox(height: 6),
            Text('Độ trôi chảy: ~$pace từ/phút (${paceLabel(pace!)})',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

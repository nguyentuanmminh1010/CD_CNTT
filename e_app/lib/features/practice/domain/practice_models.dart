import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../answers/data/answer_repository.dart';
import '../../review/domain/wrong_item.dart';
import '../../skills/domain/skill_type.dart';

/// Các dạng bài chạy trên engine làm bài chung ([PracticeSessionScreen]). Mọi dạng đều sinh từ dữ liệu
/// mục học có sẵn (term/meaning/example) và gửi câu trả lời để backend chấm.
enum PracticeKind {
  mixed,
  meaning,
  reverse,
  cloze,
  listen,
  spelling,
  matching,
  wordOrder,
  translate,
  dictation,
}

extension PracticeKindInfo on PracticeKind {
  String get label => switch (this) {
        PracticeKind.mixed => 'Luyện tổng hợp',
        PracticeKind.meaning => 'Trắc nghiệm',
        PracticeKind.reverse => 'Trắc nghiệm ngược',
        PracticeKind.cloze => 'Điền chỗ trống',
        PracticeKind.listen => 'Nghe & chọn',
        PracticeKind.spelling => 'Đánh vần',
        PracticeKind.matching => 'Ghép cặp',
        PracticeKind.wordOrder => 'Sắp xếp câu',
        PracticeKind.translate => 'Dịch câu',
        PracticeKind.dictation => 'Nghe chép',
      };

  String get subtitle => switch (this) {
        PracticeKind.mixed => 'Trộn nhiều dạng bài trong một lượt',
        PracticeKind.meaning => 'Chọn nghĩa đúng',
        PracticeKind.reverse => 'Xem nghĩa, chọn tiếng Anh',
        PracticeKind.cloze => 'Hoàn thành câu còn thiếu',
        PracticeKind.listen => 'Nghe rồi chọn nghĩa',
        PracticeKind.spelling => 'Ghép chữ cái thành từ',
        PracticeKind.matching => 'Nối từ với nghĩa',
        PracticeKind.wordOrder => 'Ghép từ thành câu',
        PracticeKind.translate => 'Gõ câu tiếng Anh',
        PracticeKind.dictation => 'Nghe và gõ lại',
      };

  IconData get icon => switch (this) {
        PracticeKind.mixed => Icons.auto_awesome_rounded,
        PracticeKind.meaning => Icons.quiz_rounded,
        PracticeKind.reverse => Icons.swap_vert_rounded,
        PracticeKind.cloze => Icons.edit_note_rounded,
        PracticeKind.listen => Icons.headphones_rounded,
        PracticeKind.spelling => Icons.abc_rounded,
        PracticeKind.matching => Icons.join_inner_rounded,
        PracticeKind.wordOrder => Icons.swap_horiz_rounded,
        PracticeKind.translate => Icons.translate_rounded,
        PracticeKind.dictation => Icons.hearing_rounded,
      };

  Color get color => switch (this) {
        PracticeKind.mixed => AppColors.primary,
        PracticeKind.meaning => AppColors.accentBlue,
        PracticeKind.reverse => AppColors.accentBlue,
        PracticeKind.cloze => AppColors.accentYellow,
        PracticeKind.listen => AppColors.accentPurple,
        PracticeKind.spelling => AppColors.accentYellow,
        PracticeKind.matching => AppColors.primary,
        PracticeKind.wordOrder => AppColors.accentPurple,
        PracticeKind.translate => AppColors.accentBlue,
        PracticeKind.dictation => AppColors.accentPurple,
      };

  /// Tên dùng trong URL `/<mảng>/<topicId>/practice/<slug>`.
  String get slug => name;
}

PracticeKind practiceKindFromSlug(String? slug) =>
    PracticeKind.values.firstWhere((k) => k.slug == slug, orElse: () => PracticeKind.mixed);

/// Một câu trong lượt làm bài. [entries] là các mục được chấm bởi câu này (thường 1, Ghép cặp thì nhiều).
sealed class PracticeQuestion {
  const PracticeQuestion({required this.kind, required this.instruction, this.skill});

  final PracticeKind kind;

  /// Lời dẫn ngắn ở đầu câu (vd "Chọn nghĩa đúng").
  final String instruction;

  /// Kỹ năng được cộng khi chấm (Nghe/Viết...) — null = không tính kỹ năng riêng.
  final SkillType? skill;

  List<WrongItem> get entries;
}

/// Chọn 1 trong nhiều đáp án. [answers] song song [options]: chuỗi thực sự gửi lên backend (vd ở Điền chỗ
/// trống của Mẫu câu, đáp án hiển thị là một từ nhưng gửi đi là cả câu đã điền).
class ChoiceQuestion extends PracticeQuestion {
  const ChoiceQuestion({
    required super.kind,
    required super.instruction,
    required this.entry,
    required this.prompt,
    required this.options,
    required this.answers,
    required this.correctIndex,
    required this.mode,
    this.detail,
    this.speakText,
    this.autoplay = false,
    this.hidePrompt = false,
    this.promptIsSentence = false,
    super.skill,
  });

  final WrongItem entry;
  final String prompt;
  final String? detail;
  final List<String> options;
  final List<String> answers;
  final int correctIndex;
  final AnswerMode mode;

  /// Văn bản có thể nghe (nút loa); [autoplay] = tự đọc khi mở câu.
  final String? speakText;
  final bool autoplay;

  /// Ẩn [prompt] cho tới khi đã kiểm tra (Nghe & chọn).
  final bool hidePrompt;

  /// [prompt] là cả một câu có chỗ trống `____` — hiển thị kiểu câu, không phải từ to.
  final bool promptIsSentence;

  @override
  List<WrongItem> get entries => [entry];
}

/// Gõ câu trả lời (Dịch câu, Nghe chép).
class TypingQuestion extends PracticeQuestion {
  const TypingQuestion({
    required super.kind,
    required super.instruction,
    required this.entry,
    required this.prompt,
    this.speakText,
    this.autoplay = false,
    this.hint,
    super.skill,
  });

  final WrongItem entry;

  /// Nội dung đề (nghĩa tiếng Việt); rỗng khi chỉ nghe.
  final String prompt;
  final String? speakText;
  final bool autoplay;

  /// Gợi ý bật/tắt được (vd nghĩa tiếng Việt ở Nghe chép).
  final String? hint;

  String get expected => entry.item.term;

  @override
  List<WrongItem> get entries => [entry];
}

/// Ghép các chữ cái đã xáo trộn thành từ (Đánh vần). Khoảng trắng của từ được giữ cố định.
class SpellingQuestion extends PracticeQuestion {
  const SpellingQuestion({
    required super.kind,
    required super.instruction,
    required this.entry,
    required this.letters,
  });

  final WrongItem entry;

  /// Các chữ cái (không gồm khoảng trắng) đã xáo trộn.
  final List<String> letters;

  String get target => entry.item.term;

  /// Số ô chữ cái của từng cụm từ (vd "ice cream" → [3, 5]).
  List<int> get groups => target.trim().split(RegExp(r'\s+')).map((w) => w.length).toList();

  /// Ghép các chữ đã chọn thành chuỗi có khoảng trắng đúng vị trí.
  String assemble(List<String> picked) {
    final buffer = StringBuffer();
    var i = 0;
    for (var g = 0; g < groups.length; g++) {
      if (g > 0) buffer.write(' ');
      for (var k = 0; k < groups[g] && i < picked.length; k++) {
        buffer.write(picked[i++]);
      }
    }
    return buffer.toString();
  }

  @override
  List<WrongItem> get entries => [entry];
}

/// Ghép từ thành câu (câu ví dụ của mục).
class WordOrderPracticeQuestion extends PracticeQuestion {
  const WordOrderPracticeQuestion({
    required super.kind,
    required super.instruction,
    required this.entry,
    required this.correctWords,
    required this.shuffledWords,
  });

  final WrongItem entry;
  final List<String> correctWords;
  final List<String> shuffledWords;

  @override
  List<WrongItem> get entries => [entry];
}

/// Nối mỗi từ/câu tiếng Anh với nghĩa của nó (3–5 cặp).
class MatchingQuestion extends PracticeQuestion {
  const MatchingQuestion({
    required super.kind,
    required super.instruction,
    required this.pairs,
    required this.rightOrder,
  });

  /// Thứ tự hiện cột trái = thứ tự [pairs].
  final List<WrongItem> pairs;

  /// Chỉ số trong [pairs] theo thứ tự hiện ở cột phải (nghĩa).
  final List<int> rightOrder;

  @override
  List<WrongItem> get entries => pairs;
}

/// Một câu đã trả lời sai — hiện ở màn kết quả để ôn lại.
class PracticeMistake {
  const PracticeMistake({required this.entry, required this.given, required this.correctAnswer});

  final WrongItem entry;
  final String given;
  final String correctAnswer;
}

/// Kết quả một lượt (cho màn kết quả và các phần mở rộng của từng màn gọi engine).
class PracticeOutcome {
  const PracticeOutcome({
    required this.correct,
    required this.total,
    required this.bestStreak,
    required this.elapsed,
    required this.mistakes,
  });

  final int correct;
  final int total;
  final int bestStreak;
  final Duration elapsed;
  final List<PracticeMistake> mistakes;

  int get percent => total == 0 ? 0 : (correct / total * 100).round();
}

/// Chuẩn hoá câu gõ giống backend (`SpeechMatcher.normalizeTyped`): bỏ hoa-thường, khoảng trắng thừa và
/// dấu câu ở cuối.
String normalizeTyped(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r"[.,!?;:'“”]+$"), '');

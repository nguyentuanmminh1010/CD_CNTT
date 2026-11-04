import 'dart:math';

import '../../answers/data/answer_repository.dart';
import '../../review/domain/wrong_item.dart';
import '../../skills/domain/skill_type.dart';
import '../domain/practice_models.dart';

const _blank = '_____';
const _maxOptions = 4;

/// Sinh một lượt làm bài dạng [kind] từ [entries] (có thể trộn nhiều mảng). Đáp án nhiễu chỉ lấy trong
/// cùng mảng. Mục không làm được dạng đã chọn (vd không có câu ví dụ) thì rơi về dạng gần nhất làm được,
/// để lượt bài không bị thiếu câu. [keepOrder] giữ thứ tự [entries] (đề đã sắp độ khó ở backend).
List<PracticeQuestion> buildPractice(
  List<WrongItem> entries,
  PracticeKind kind, {
  int? limit,
  bool keepOrder = false,
  Random? random,
}) {
  final rng = random ?? Random();
  final pool = _PoolIndex(entries);
  var order = keepOrder ? List.of(entries) : (List.of(entries)..shuffle(rng));
  if (limit != null && order.length > limit) order = order.take(limit).toList();

  if (kind == PracticeKind.matching) return _matchingOnly(order, pool, rng);
  if (kind == PracticeKind.mixed) return _mixed(order, pool, rng);

  return [
    for (final e in order) ?_build(e, kind, pool, rng),
  ];
}

PracticeQuestion? _build(WrongItem e, PracticeKind kind, _PoolIndex pool, Random rng) {
  switch (kind) {
    case PracticeKind.meaning:
      return _meaning(e, pool, rng);
    case PracticeKind.reverse:
      return _reverse(e, pool, rng) ?? _meaning(e, pool, rng);
    case PracticeKind.cloze:
      return _cloze(e, pool, rng) ?? _reverse(e, pool, rng) ?? _meaning(e, pool, rng);
    case PracticeKind.listen:
      return _listen(e, pool, rng);
    case PracticeKind.spelling:
      return _spelling(e, rng) ?? _reverse(e, pool, rng) ?? _meaning(e, pool, rng);
    case PracticeKind.wordOrder:
      return _wordOrder(e, rng);
    case PracticeKind.translate:
      return TypingQuestion(
        kind: kind,
        instruction: 'Dịch sang tiếng Anh',
        entry: e,
        prompt: e.item.meaning,
        skill: SkillType.writing,
      );
    case PracticeKind.dictation:
      return TypingQuestion(
        kind: kind,
        instruction: 'Nghe và gõ lại câu bạn nghe được',
        entry: e,
        prompt: '',
        speakText: e.item.term,
        autoplay: true,
        hint: e.item.meaning,
        skill: SkillType.listening,
      );
    case PracticeKind.matching:
    case PracticeKind.mixed:
      return _meaning(e, pool, rng);
  }
}

/// Trộn dạng bài: mở đầu bằng một câu Ghép cặp (nếu đủ mục cùng mảng), sau đó xoay vòng các dạng còn lại,
/// mỗi mục chỉ xuất hiện một lần để backend chấm mỗi mục đúng một lần trong lượt.
List<PracticeQuestion> _mixed(List<WrongItem> order, _PoolIndex pool, Random rng) {
  final questions = <PracticeQuestion>[];
  final remaining = List.of(order);
  if (remaining.length >= 8) {
    final group = _takeMatchingGroup(remaining, 4);
    if (group != null) questions.add(_matching(group, rng));
  }
  const rotation = [
    PracticeKind.meaning,
    PracticeKind.cloze,
    PracticeKind.listen,
    PracticeKind.reverse,
    PracticeKind.spelling,
    PracticeKind.wordOrder,
  ];
  var r = 0;
  for (final e in remaining) {
    PracticeQuestion? q;
    for (var tries = 0; tries < rotation.length && q == null; tries++) {
      final kind = rotation[(r + tries) % rotation.length];
      q = switch (kind) {
        PracticeKind.cloze => _cloze(e, pool, rng),
        PracticeKind.spelling => _spelling(e, rng),
        PracticeKind.wordOrder => _wordOrder(e, rng),
        PracticeKind.reverse => _reverse(e, pool, rng),
        PracticeKind.listen => _listen(e, pool, rng),
        _ => _meaning(e, pool, rng),
      };
    }
    r++;
    if (q != null) questions.add(q);
  }
  return questions;
}

List<PracticeQuestion> _matchingOnly(List<WrongItem> order, _PoolIndex pool, Random rng) {
  final remaining = List.of(order);
  final questions = <PracticeQuestion>[];
  while (true) {
    final group = _takeMatchingGroup(remaining, 5);
    if (group == null) break;
    questions.add(_matching(group, rng));
  }
  // Phần lẻ (không đủ 3 mục cùng mảng) vẫn được luyện bằng trắc nghiệm.
  for (final e in remaining) {
    if (_meaning(e, pool, rng) case final q?) questions.add(q);
  }
  return questions;
}

/// Lấy (và gỡ khỏi [remaining]) tối đa [size] mục cùng mảng, nghĩa không trùng nhau; null nếu < 3.
List<WrongItem>? _takeMatchingGroup(List<WrongItem> remaining, int size) {
  final byCategory = <ReviewCategory, List<WrongItem>>{};
  for (final e in remaining) {
    byCategory.putIfAbsent(e.category, () => []).add(e);
  }
  for (final list in byCategory.values) {
    final seenTerms = <String>{};
    final seenMeanings = <String>{};
    final group = <WrongItem>[];
    for (final e in list) {
      final t = e.item.term.trim().toLowerCase();
      final m = e.item.meaning.trim().toLowerCase();
      if (seenTerms.contains(t) || seenMeanings.contains(m)) continue;
      seenTerms.add(t);
      seenMeanings.add(m);
      group.add(e);
      if (group.length == size) break;
    }
    if (group.length >= 3) {
      remaining.removeWhere(group.contains);
      return group;
    }
  }
  return null;
}

MatchingQuestion _matching(List<WrongItem> group, Random rng) {
  final right = List.generate(group.length, (i) => i)..shuffle(rng);
  return MatchingQuestion(
    kind: PracticeKind.matching,
    instruction: 'Nối từng mục với nghĩa đúng',
    pairs: group,
    rightOrder: right,
  );
}

ChoiceQuestion? _meaning(WrongItem e, _PoolIndex pool, Random rng) {
  final options = _options(e.item.meaning, pool.meanings(e), rng);
  if (options.length < 2) return null;
  return ChoiceQuestion(
    kind: PracticeKind.meaning,
    instruction: switch (e.category) {
      ReviewCategory.grammar => 'Cấu trúc này dùng để làm gì?',
      ReviewCategory.sentence => 'Câu này có nghĩa là gì?',
      ReviewCategory.vocabulary => 'Từ này có nghĩa là gì?',
    },
    entry: e,
    prompt: e.item.term,
    detail: e.item.phonetic,
    speakText: e.category == ReviewCategory.grammar ? null : e.item.term,
    options: options,
    answers: options,
    correctIndex: options.indexOf(e.item.meaning),
    mode: AnswerMode.meaning,
  );
}

ChoiceQuestion? _reverse(WrongItem e, _PoolIndex pool, Random rng) {
  final options = _options(e.item.term, pool.terms(e), rng);
  if (options.length < 2) return null;
  return ChoiceQuestion(
    kind: PracticeKind.reverse,
    instruction: switch (e.category) {
      ReviewCategory.grammar => 'Chọn cấu trúc ngữ pháp phù hợp',
      ReviewCategory.sentence => 'Chọn câu tiếng Anh đúng',
      ReviewCategory.vocabulary => 'Chọn từ tiếng Anh đúng',
    },
    entry: e,
    prompt: e.item.meaning,
    options: options,
    answers: options,
    correctIndex: options.indexOf(e.item.term),
    mode: AnswerMode.term,
  );
}

ChoiceQuestion? _listen(WrongItem e, _PoolIndex pool, Random rng) {
  if (e.category == ReviewCategory.grammar) return null; // tên cấu trúc ngữ pháp nghe không có nghĩa
  final options = _options(e.item.meaning, pool.meanings(e), rng);
  if (options.length < 2) return null;
  return ChoiceQuestion(
    kind: PracticeKind.listen,
    instruction: 'Nghe và chọn nghĩa đúng',
    entry: e,
    prompt: e.item.term,
    detail: e.item.phonetic,
    speakText: e.item.term,
    autoplay: true,
    hidePrompt: true,
    options: options,
    answers: options,
    correctIndex: options.indexOf(e.item.meaning),
    mode: AnswerMode.meaning,
    skill: SkillType.listening,
  );
}

ChoiceQuestion? _cloze(WrongItem e, _PoolIndex pool, Random rng) {
  switch (e.category) {
    case ReviewCategory.vocabulary:
      final example = e.item.example?.trim();
      if (example == null || example.isEmpty) return null;
      final pattern = RegExp(r'\b' + RegExp.escape(e.item.term.trim()) + r'\b', caseSensitive: false);
      if (!pattern.hasMatch(example)) return null;
      final options = _options(e.item.term, pool.terms(e), rng);
      if (options.length < 2) return null;
      return ChoiceQuestion(
        kind: PracticeKind.cloze,
        instruction: 'Chọn từ còn thiếu trong câu',
        entry: e,
        prompt: example.replaceFirst(pattern, _blank),
        detail: e.item.meaning,
        promptIsSentence: true,
        options: options,
        answers: options,
        correctIndex: options.indexOf(e.item.term),
        mode: AnswerMode.term,
      );
    case ReviewCategory.grammar:
      final example = e.item.example?.trim();
      if (example == null || example.isEmpty) return null;
      final options = _options(e.item.term, pool.terms(e), rng);
      if (options.length < 2) return null;
      return ChoiceQuestion(
        kind: PracticeKind.cloze,
        instruction: 'Câu này dùng cấu trúc ngữ pháp nào?',
        entry: e,
        prompt: example,
        promptIsSentence: true,
        options: options,
        answers: options,
        correctIndex: options.indexOf(e.item.term),
        mode: AnswerMode.term,
      );
    case ReviewCategory.sentence:
      return _sentenceGap(e, pool, rng);
  }
}

/// Mẫu câu: che một từ (dài nhất) của câu, chọn từ còn thiếu. Gửi lên backend là CẢ câu đã điền (chấm theo
/// `term`), nên không cần cách chấm riêng.
ChoiceQuestion? _sentenceGap(WrongItem e, _PoolIndex pool, Random rng) {
  final tokens = e.item.term.trim().split(RegExp(r'\s+'));
  final core = RegExp(r"[A-Za-z']+");
  var best = -1;
  var bestLen = 0;
  for (var i = 0; i < tokens.length; i++) {
    final m = core.firstMatch(tokens[i]);
    final len = m?.group(0)?.length ?? 0;
    if (len >= 3 && len > bestLen) {
      best = i;
      bestLen = len;
    }
  }
  if (best < 0) return null;
  final word = core.firstMatch(tokens[best])!.group(0)!;
  // Không lấy từ đã có sẵn trong câu làm đáp án nhiễu, và viết hoa giống đáp án đúng để chữ hoa không
  // làm lộ đáp án (vd từ đầu câu).
  final inSentence = {
    for (final m in core.allMatches(e.item.term)) m.group(0)!.toLowerCase(),
  };
  final capitalized = word[0] == word[0].toUpperCase();
  String matchCase(String w) => capitalized
      ? w[0].toUpperCase() + w.substring(1)
      : (w == w.toUpperCase() ? w : w[0].toLowerCase() + w.substring(1));
  final distractors = pool
      .sentenceWords(e)
      .where((w) => !inSentence.contains(w.toLowerCase()))
      .map(matchCase)
      .toSet()
      .toList();
  final options = _options(word, distractors, rng);
  if (options.length < 2) return null;
  String fill(String w) {
    final copy = List.of(tokens);
    copy[best] = tokens[best].replaceFirst(word, w);
    return copy.join(' ');
  }

  final shown = List.of(tokens);
  shown[best] = tokens[best].replaceFirst(word, _blank);
  return ChoiceQuestion(
    kind: PracticeKind.cloze,
    instruction: 'Chọn từ còn thiếu trong câu',
    entry: e,
    prompt: shown.join(' '),
    detail: e.item.meaning,
    promptIsSentence: true,
    options: options,
    answers: [for (final o in options) fill(o)],
    correctIndex: options.indexOf(word),
    mode: AnswerMode.term,
  );
}

SpellingQuestion? _spelling(WrongItem e, Random rng) {
  if (e.category == ReviewCategory.sentence) return null;
  final term = e.item.term.trim();
  final words = term.split(RegExp(r'\s+'));
  final letters = words.join().split('');
  if (words.length > 2 || letters.length < 3 || letters.length > 14) return null;
  if (!RegExp(r"^[A-Za-z' -]+$").hasMatch(term)) return null;
  final shuffled = List.of(letters)..shuffle(rng);
  for (var i = 0; i < 5 && shuffled.join() == letters.join(); i++) {
    shuffled.shuffle(rng);
  }
  return SpellingQuestion(
    kind: PracticeKind.spelling,
    instruction: 'Ghép các chữ cái thành từ đúng',
    entry: e,
    letters: shuffled,
  );
}

WordOrderPracticeQuestion? _wordOrder(WrongItem e, Random rng) {
  final example = e.item.example?.trim();
  final sentence = (example != null && example.isNotEmpty) ? example : e.item.term.trim();
  final words = sentence.split(RegExp(r'\s+'));
  if (words.length < 3 || words.length > 14) return null;
  final shuffled = List.of(words)..shuffle(rng);
  for (var i = 0; i < 5 && shuffled.join(' ') == words.join(' '); i++) {
    shuffled.shuffle(rng);
  }
  return WordOrderPracticeQuestion(
    kind: PracticeKind.wordOrder,
    instruction: 'Sắp xếp thành câu đúng',
    entry: e,
    correctWords: words,
    shuffledWords: shuffled,
  );
}

/// Đáp án đúng + tối đa 3 đáp án nhiễu khác nhau (không trùng đáp án đúng), đã xáo trộn.
List<String> _options(String correct, Iterable<String> candidates, Random rng) {
  final c = correct.trim();
  final seen = {c.toLowerCase()};
  final distractors = <String>[];
  for (final d in candidates.toList()..shuffle(rng)) {
    final t = d.trim();
    if (t.isEmpty || seen.contains(t.toLowerCase())) continue;
    seen.add(t.toLowerCase());
    distractors.add(t);
    if (distractors.length == _maxOptions - 1) break;
  }
  return [correct, ...distractors]..shuffle(rng);
}

/// Kho đáp án nhiễu theo mảng, dựng một lần cho cả lượt.
class _PoolIndex {
  _PoolIndex(List<WrongItem> entries) {
    for (final e in entries) {
      _byCategory.putIfAbsent(e.category, () => []).add(e);
    }
  }

  final _byCategory = <ReviewCategory, List<WrongItem>>{};
  final _wordsCache = <ReviewCategory, List<String>>{};

  Iterable<WrongItem> _others(WrongItem e) =>
      (_byCategory[e.category] ?? const []).where((o) => o.item.id != e.item.id);

  Iterable<String> meanings(WrongItem e) => _others(e).map((o) => o.item.meaning);

  Iterable<String> terms(WrongItem e) => _others(e).map((o) => o.item.term);

  Iterable<String> sentenceWords(WrongItem e) {
    final words = _wordsCache.putIfAbsent(e.category, () {
      final core = RegExp(r"[A-Za-z']{3,}");
      return [
        for (final o in _byCategory[e.category] ?? const <WrongItem>[])
          for (final m in core.allMatches(o.item.term)) m.group(0)!,
      ];
    });
    return words;
  }
}

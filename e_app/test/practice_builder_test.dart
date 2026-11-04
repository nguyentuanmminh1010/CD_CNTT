import 'dart:math';

import 'package:e_app/features/answers/data/answer_repository.dart';
import 'package:e_app/features/practice/application/practice_builder.dart';
import 'package:e_app/features/practice/domain/practice_models.dart';
import 'package:e_app/features/review/domain/wrong_item.dart';
import 'package:e_app/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

WrongItem _e(String id, String term, String meaning,
    {String? example, ReviewCategory category = ReviewCategory.vocabulary}) {
  return WrongItem(
    item: VocabularyItem(
      id: id,
      term: term,
      phonetic: null,
      meaning: meaning,
      example: example,
      mastered: false,
    ),
    category: category,
    topicId: 't',
    topicName: 'Topic',
  );
}

final _vocab = [
  _e('1', 'trip', 'chuyến đi', example: "We're planning a trip to Da Nang."),
  _e('2', 'ticket', 'vé', example: 'I bought a ticket online.'),
  _e('3', 'passport', 'hộ chiếu', example: 'Show your passport at the gate.'),
  _e('4', 'luggage', 'hành lý'),
  _e('5', 'ice cream', 'kem', example: 'I love ice cream in summer.'),
];

final _sentences = [
  _e('s1', 'Nice to meet you.', 'Rất vui được gặp bạn.', category: ReviewCategory.sentence),
  _e('s2', 'See you later.', 'Hẹn gặp lại sau.', category: ReviewCategory.sentence),
  _e('s3', 'How are you today?', 'Hôm nay bạn khoẻ không?', category: ReviewCategory.sentence),
];

void main() {
  final rng = Random(7);

  test('Trắc nghiệm: đáp án đúng là nghĩa, tối đa 4 lựa chọn không trùng', () {
    final qs = buildPractice(_vocab, PracticeKind.meaning, random: rng).cast<ChoiceQuestion>();
    expect(qs, hasLength(_vocab.length));
    for (final q in qs) {
      expect(q.mode, AnswerMode.meaning);
      expect(q.answers[q.correctIndex], q.entry.item.meaning);
      expect(q.options.length, lessThanOrEqualTo(4));
      expect(q.options.toSet().length, q.options.length);
    }
  });

  test('Trắc nghiệm ngược: gửi term (mode TERM)', () {
    final qs = buildPractice(_vocab, PracticeKind.reverse, random: rng).cast<ChoiceQuestion>();
    for (final q in qs) {
      expect(q.mode, AnswerMode.term);
      expect(q.prompt, q.entry.item.meaning);
      expect(q.answers[q.correctIndex], q.entry.item.term);
    }
  });

  test('Điền chỗ trống (từ vựng): che đúng từ trong câu, mục thiếu ví dụ rơi về dạng khác', () {
    final qs = buildPractice(_vocab, PracticeKind.cloze, random: rng);
    for (final q in qs) {
      final c = q as ChoiceQuestion;
      if (c.kind == PracticeKind.cloze) {
        expect(c.prompt, contains('_____'));
        expect(c.prompt.toLowerCase(), isNot(contains(c.entry.item.term.toLowerCase())));
        expect(c.answers[c.correctIndex], c.entry.item.term);
      } else {
        expect(c.entry.item.id, '4'); // "luggage" không có câu ví dụ
      }
    }
  });

  test('Điền chỗ trống (mẫu câu): đáp án gửi đi là CẢ câu, khớp đúng term', () {
    final qs = buildPractice(_sentences, PracticeKind.cloze, random: rng).cast<ChoiceQuestion>();
    expect(qs, isNotEmpty);
    for (final q in qs) {
      expect(normalizeTyped(q.answers[q.correctIndex]), normalizeTyped(q.entry.item.term));
      for (var i = 0; i < q.answers.length; i++) {
        if (i != q.correctIndex) {
          expect(normalizeTyped(q.answers[i]), isNot(normalizeTyped(q.entry.item.term)));
        }
      }
    }
  });

  test('Đánh vần: đủ chữ cái, ghép lại giữ khoảng trắng', () {
    final qs = buildPractice(_vocab, PracticeKind.spelling, random: rng);
    final ice = qs.whereType<SpellingQuestion>().firstWhere((q) => q.entry.item.id == '5');
    expect(ice.groups, [3, 5]);
    expect((List.of(ice.letters)..sort()).join(), ('icecream'.split('')..sort()).join());
    expect(ice.assemble('icecream'.split('')), 'ice cream');
  });

  test('Ghép cặp: nhóm 3-5 mục cùng mảng, cột phải là hoán vị', () {
    final qs = buildPractice([..._vocab, ..._sentences], PracticeKind.matching, random: rng);
    final groups = qs.whereType<MatchingQuestion>().toList();
    expect(groups, isNotEmpty);
    for (final g in groups) {
      expect(g.pairs.length, inInclusiveRange(3, 5));
      expect(g.pairs.map((p) => p.category).toSet(), hasLength(1));
      expect((List.of(g.rightOrder)..sort()), List.generate(g.pairs.length, (i) => i));
    }
  });

  test('Tổng hợp: mỗi mục chỉ xuất hiện một lần', () {
    final items = [
      ..._vocab,
      for (var i = 0; i < 6; i++) _e('x$i', 'word$i', 'nghĩa $i', example: 'This is word$i here.'),
    ];
    final qs = buildPractice(items, PracticeKind.mixed, random: rng);
    final ids = [for (final q in qs) for (final e in q.entries) e.item.id];
    expect(ids.toSet().length, ids.length);
    expect(qs.first, isA<MatchingQuestion>());
  });

  test('Sắp xếp câu: dùng câu ví dụ, bỏ qua câu quá ngắn', () {
    final qs = buildPractice(_vocab, PracticeKind.wordOrder, random: rng)
        .cast<WordOrderPracticeQuestion>();
    for (final q in qs) {
      expect(q.correctWords.join(' '), q.entry.item.example);
      expect((List.of(q.shuffledWords)..sort()), (List.of(q.correctWords)..sort()));
    }
  });
}

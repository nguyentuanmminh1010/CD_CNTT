import 'package:e_app/features/answers/application/answer_providers.dart';
import 'package:e_app/features/answers/data/answer_repository.dart';
import 'package:e_app/features/practice/domain/practice_models.dart';
import 'package:e_app/features/practice/presentation/practice_session_screen.dart';
import 'package:e_app/features/practice/presentation/widgets/question_views.dart';
import 'package:e_app/features/review/domain/wrong_item.dart';
import 'package:e_app/features/skills/domain/skill_type.dart';
import 'package:e_app/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';

/// Ghi lại câu trả lời thay vì gọi mạng.
class _FakeAnswers extends AnswerRepository {
  _FakeAnswers() : super(GraphQLClient(link: HttpLink('http://localhost/x'), cache: GraphQLCache()));

  final submitted = <(String, AnswerMode, String)>[];

  @override
  Future<AnswerResult> submit({
    required String itemId,
    required AnswerMode mode,
    required String answer,
    String? attemptKey,
    SkillType? skill,
  }) async {
    submitted.add((itemId, mode, answer));
    return const AnswerResult(correct: true, correctAnswer: '', similarity: 0);
  }
}

WrongItem _e(String id, String term, String meaning) => WrongItem(
      item: VocabularyItem(
        id: id,
        term: term,
        phonetic: null,
        meaning: meaning,
        example: null,
        mastered: false,
      ),
      category: ReviewCategory.vocabulary,
      topicId: 't',
      topicName: 'Topic',
    );

final _items = [_e('1', 'apple', 'quả táo'), _e('2', 'banana', 'quả chuối'), _e('3', 'orange', 'quả cam')];

Future<_FakeAnswers> _pump(WidgetTester tester, PracticeKind kind) async {
  final fake = _FakeAnswers();
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [answerRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      home: PracticeSessionScreen(
        config: PracticeConfig(title: 'Test', kind: kind, load: (_) async => _items),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('Trắc nghiệm: chọn → Kiểm tra → phản hồi → Tiếp tục → màn kết quả', (tester) async {
    final fake = await _pump(tester, PracticeKind.meaning);
    for (var i = 0; i < _items.length; i++) {
      // Câu hiện tại: tìm từ đang hỏi và chọn đúng nghĩa của nó.
      final asked = _items.firstWhere((e) => find.text(e.item.term).evaluate().isNotEmpty);
      await tester.tap(find.text(asked.item.meaning));
      await tester.pump();
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hoàn thành Test'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(fake.submitted, hasLength(3));
    expect(fake.submitted.every((s) => s.$2 == AnswerMode.meaning), isTrue);
  });

  testWidgets('Bỏ qua: tính sai và hiện đáp án đúng', (tester) async {
    final fake = await _pump(tester, PracticeKind.reverse);
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.text('Đã bỏ qua'), findsOneWidget);
    expect(find.textContaining('Đáp án đúng', findRichText: true), findsOneWidget);
    expect(fake.submitted.single.$3, '');
  });

  testWidgets('Ghép cặp: ghép đúng hết thì hiện phản hồi và gửi nghĩa từng mục', (tester) async {
    final fake = await _pump(tester, PracticeKind.matching);
    for (final e in _items) {
      await tester.tap(find.text(e.item.term));
      await tester.pump();
      await tester.tap(find.text(e.item.meaning));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Ghép đúng tất cả!'), findsOneWidget);
    expect(fake.submitted.map((s) => s.$3).toSet(), _items.map((e) => e.item.meaning).toSet());
  });

  testWidgets('Đánh vần: chọn đủ chữ cái thì bật Kiểm tra, gửi từ đã ghép', (tester) async {
    PendingAnswer? answer;
    const q = SpellingQuestion(
      kind: PracticeKind.spelling,
      instruction: 'Ghép',
      entry: WrongItem(
        item: VocabularyItem(
            id: '9', term: 'cat', phonetic: null, meaning: 'con mèo', example: null, mastered: false),
        category: ReviewCategory.vocabulary,
        topicId: 't',
        topicName: 'T',
      ),
      letters: ['t', 'c', 'a'],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpellingQuestionView(
          question: q,
          revealed: false,
          correct: null,
          onAnswer: (a) => answer = a,
        ),
      ),
    ));
    for (final l in ['C', 'A', 'T']) {
      await tester.tap(find.text(l).last);
      await tester.pump();
    }
    expect(answer?.submit, 'cat');
    expect(answer?.correct, isTrue);
  });
}

import 'package:e_app/features/answers/application/answer_providers.dart';
import 'package:e_app/features/attempts/domain/attempt.dart';
import 'package:e_app/features/profile/presentation/widgets/mastery_pie_chart.dart';
import 'package:e_app/features/profile/presentation/widgets/weekly_activity_bar_chart.dart';
import 'package:e_app/features/progress/domain/activity_models.dart';
import 'package:e_app/features/ranking/domain/ranking_models.dart';
import 'package:e_app/features/recommendation/recommendation.dart';
import 'package:e_app/features/vocabulary/domain/vocabulary_models.dart';
import 'package:e_app/features/vocabulary/presentation/widgets/word_chip.dart';
import 'package:e_app/features/vocabulary/presentation/widgets/word_drag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LeaderboardPeriod maps to backend enum values', () {
    expect(LeaderboardPeriod.values.map((p) => p.apiValue), ['ALL', 'WEEK', 'FRIENDS']);
    final e = LeaderboardEntry.fromJson({
      'rank': 1, 'userId': '3', 'displayName': 'A', 'score': 7, 'me': true,
      'avatar': 'data:image/png;base64,AAAA',
    });
    expect(e.avatar, startsWith('data:image/'));
  });

  test('RecommendedTopic.fromJson derives labels and base path from category', () {
    final r = RecommendedTopic.fromJson({
      'score': 0.3,
      'suggestedDifficulty': 1,
      'totalItems': 20,
      'masteredItems': 2,
      'topic': {
        'id': '9', 'name': 'Giới từ', 'description': null, 'icon': null,
        'category': 'GRAMMAR', 'wordCount': 5,
      },
    });
    expect(r.categoryLabel, 'Ngữ pháp');
    expect(r.basePath, '/grammar');
    expect(r.difficultyLabel, 'Cơ bản');
  });

  test('AttemptAnswerView and VocabularyTopic parse new fields', () {
    final a = AttemptAnswerView.fromJson({
      'itemId': '5', 'term': 'x', 'meaning': 'y', 'mode': 'MEANING',
      'answer': null, 'correct': false, 'correctAnswer': 'y',
    });
    expect(a.answer, isNull);
    expect(a.correct, isFalse);

    final t = VocabularyTopic.fromJson({
      'id': '1', 'name': 'n', 'wordCount': 3, 'category': 'VOCABULARY',
      'mine': true, 'editable': true,
    });
    expect(t.mine, isTrue);
    expect(t.editable, isTrue);
    // Backend cũ/thiếu field -> mặc định an toàn
    final legacy = VocabularyTopic.fromJson({'id': '2', 'name': 'm'});
    expect(legacy.mine, isFalse);
    expect(legacy.category, 'VOCABULARY');
  });

  test('newAttemptKey is unique per call', () {
    final keys = {for (var i = 0; i < 200; i++) newAttemptKey()};
    expect(keys.length, 200);
  });

  testWidgets('WeeklyActivityBarChart renders 7 days incl. empty data', (tester) async {
    final today = DateTime(2026, 10, 4);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WeeklyActivityBarChart(
          today: today,
          days: [
            ActivityDay(date: today, itemsCompleted: 9),
            ActivityDay(date: today.subtract(const Duration(days: 2)), itemsCompleted: 4),
          ],
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('CN'), findsOneWidget); // 04/10/2026 là Chủ nhật

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WeeklyActivityBarChart(today: today, days: const [])),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('MasteryPieChart shows legend and empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MasteryPieChart(categories: const [
          CategoryMastery(category: 'VOCABULARY', totalItems: 10, masteredItems: 5),
          CategoryMastery(category: 'GRAMMAR', totalItems: 8, masteredItems: 3),
          CategoryMastery(category: 'SENTENCE', totalItems: 6, masteredItems: 0),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.text('Từ vựng'), findsOneWidget);
    expect(find.text('5/10'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MasteryPieChart(categories: const [
          CategoryMastery(category: 'VOCABULARY', totalItems: 10, masteredItems: 0),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.textContaining('Chưa có mục nào'), findsOneWidget);
  });

  /// Dựng một chip kéo được + một vùng thả, kéo chip sang vùng thả; trả về dữ liệu nhận được.
  Future<({WordDrag? dropped, bool hovered})> dragChip(WidgetTester tester, {required int holdMs}) async {
    WordDrag? dropped;
    var hovered = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            DraggableWordChip(
              label: 'hello',
              state: WordChipState.pool,
              onTap: () {},
              drag: const WordDrag(fromPool: true, index: 2, label: 'hello'),
            ),
            const SizedBox(height: 200),
            WordDropTarget(
              onDrop: (d) => dropped = d,
              builder: (hovering) {
                hovered = hovering;
                return const SizedBox(key: Key('zone'), width: 200, height: 80);
              },
            ),
          ],
        ),
      ),
    ));
    final from = tester.getCenter(find.text('hello'));
    final to = tester.getCenter(find.byKey(const Key('zone')));
    final gesture = await tester.startGesture(from);
    if (holdMs > 0) await tester.pump(Duration(milliseconds: holdMs)); // cảm ứng: nhấn giữ trước khi kéo
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30)); // vượt ngưỡng để bắt đầu kéo
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    final hoveredWhileOver = hovered;
    await gesture.up();
    await tester.pump();
    return (dropped: dropped, hovered: hoveredWhileOver);
  }

  testWidgets('desktop: dragging a chip onto a drop target reports the drag data', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      final r = await dragChip(tester, holdMs: 0);
      expect(r.hovered, isTrue); // vùng thả sáng lên khi chip kéo ngang qua
      expect(r.dropped, isNotNull);
      expect(r.dropped!.fromPool, isTrue);
      expect(r.dropped!.index, 2);
      expect(r.dropped!.label, 'hello');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('touch: chip needs a press-and-hold before it can be dragged', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final held = await dragChip(tester, holdMs: 300);
      expect(held.dropped?.index, 2);
      // Không nhấn giữ -> cử chỉ kéo bị coi là cuộn trang, không thả được vào vùng thả.
      final quick = await dragChip(tester, holdMs: 0);
      expect(quick.dropped, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a disabled DraggableWordChip is not draggable', (tester) async {
    WordDrag? dropped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            DraggableWordChip(
              label: 'locked',
              state: WordChipState.pool,
              onTap: null,
              enabled: false,
              drag: const WordDrag(fromPool: true, index: 0, label: 'locked'),
            ),
            const SizedBox(height: 200),
            WordDropTarget(
              onDrop: (d) => dropped = d,
              builder: (_) => const SizedBox(key: Key('zone'), width: 200, height: 80),
            ),
          ],
        ),
      ),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.text('locked')));
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('zone'))));
    await gesture.up();
    await tester.pump();
    expect(dropped, isNull);
  });
}

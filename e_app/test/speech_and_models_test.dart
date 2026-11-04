import 'package:e_app/features/auth/domain/auth_user.dart';
import 'package:e_app/features/courses/domain/course.dart';
import 'package:e_app/features/courses/domain/level_test_args.dart';
import 'package:e_app/features/reviews/domain/topic_review.dart';
import 'package:e_app/features/speaking/application/speech_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _unit(String id, int level, {bool completed = false, bool locked = false}) => {
      'id': id,
      'level': level,
      'position': int.parse(id),
      'totalItems': 5,
      'masteredItems': completed ? 5 : 0,
      'completed': completed,
      'locked': locked,
      'topic': {
        'id': id,
        'name': 'T$id',
        'description': null,
        'icon': null,
        'category': 'VOCABULARY',
        'wordCount': 5,
      },
    };

void main() {
  group('speech matcher', () {
    test('normalises case, punctuation and apostrophes', () {
      expect(speechWords("Don't  worry, BE happy!"), ['don\'t', 'worry', 'be', 'happy']);
      expect(speechWords('   '), isEmpty);
    });

    test('identical sentences score 1 and pass', () {
      expect(speechSimilarity('How are you?', 'how are you'), 1);
      expect(isSpeechCorrect('how are you', 'How are you?'), isTrue);
    });

    test('missing or extra words lower the score; unrelated fails', () {
      expect(speechSimilarity('how you', 'how are you'), closeTo(2 / 3, 1e-9));
      expect(isSpeechCorrect('how you', 'how are you'), isFalse); // 0.67 < 0.7
      expect(isSpeechCorrect('i would like a table for two', 'i would like a table for two please'), isTrue);
      expect(isSpeechCorrect('banana', 'where is the station'), isFalse);
      expect(speechSimilarity('', 'hello'), 0);
    });

    test('word order matters', () {
      expect(isSpeechCorrect('you are how', 'how are you'), isFalse);
    });
  });

  group('course models', () {
    Course build(List<Map<String, dynamic>> units, List<Map<String, dynamic>> results) => Course.fromJson({
          'id': '1', 'title': 'c', 'description': null, 'icon': null,
          'enrolled': true, 'unitCount': units.length, 'completedUnits': 0,
          'totalItems': 10, 'masteredItems': 0, 'completed': false,
          'units': units, 'levelResults': results,
        });

    test('nextUnit skips completed and locked units', () {
      final c = build([
        _unit('1', 1, completed: true),
        _unit('2', 2, locked: true),
      ], []);
      expect(c.nextUnit, isNull);
      expect(build([_unit('1', 1), _unit('2', 2, locked: true)], []).nextUnit?.id, '1');
    });

    test('levelResults parse and resultFor finds by level', () {
      final c = build([_unit('1', 1)], [
        {'level': 1, 'bestPercent': 80, 'attempted': true, 'passed': true},
        {'level': 2, 'bestPercent': 0, 'attempted': false, 'passed': false},
      ]);
      expect(c.resultFor(1)?.passed, isTrue);
      expect(c.resultFor(2)?.attempted, isFalse);
      expect(c.resultFor(3), isNull);
    });

    test('LevelTestArgs refKey matches backend format and clamps question count', () {
      final c = build([_unit('1', 1), _unit('2', 1), _unit('3', 1)], []);
      final args = LevelTestArgs(courseId: '7', courseTitle: 'X', level: 2, units: c.units);
      expect(args.refKey, 'level:7:2');
      expect(args.questionCount, 12); // 3 * 5 = 15 -> clamp 12
      expect(args.title, 'X · Level 2');
      expect(levelTestPassPercent, 70);
    });
  });

  test('TopicReviews.fromJson handles missing myReview', () {
    final r = TopicReviews.fromJson({
      'average': 4.5,
      'count': 2,
      'myReview': null,
      'reviews': [
        {
          'id': '1', 'displayName': 'A', 'rating': 5, 'comment': 'ok',
          'updatedAt': '2026-10-04T05:54:58Z', 'mine': false,
        },
      ],
    });
    expect(r.myReview, isNull);
    expect(r.reviews.single.rating, 5);
    expect(r.average, 4.5);
  });

  test('AuthUser parses avatar and isAdmin with safe defaults', () {
    final a = AuthUser.fromJson({
      'id': '1', 'email': 'a@b.c', 'displayName': 'A', 'authProvider': 'LOCAL',
      'avatar': 'data:image/png;base64,AAAA', 'isAdmin': true,
    });
    expect(a.isAdmin, isTrue);
    expect(a.avatar, startsWith('data:image/'));
    final b = AuthUser.fromJson({
      'id': '2', 'email': null, 'displayName': 'B', 'authProvider': 'GOOGLE',
    });
    expect(b.isAdmin, isFalse);
    expect(b.avatar, isNull);
  });
}

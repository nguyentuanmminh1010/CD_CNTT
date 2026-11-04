import 'package:e_app/features/assessments/domain/assessment_test.dart';
import 'package:e_app/features/attempts/domain/attempt.dart';
import 'package:e_app/features/courses/domain/course.dart';
import 'package:e_app/features/ranking/domain/ranking_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _unit(String id, int level, {required bool completed}) => {
      'id': id,
      'level': level,
      'position': int.parse(id),
      'totalItems': 10,
      'masteredItems': completed ? 10 : 3,
      'completed': completed,
      'topic': {
        'id': id,
        'name': 'Topic $id',
        'description': null,
        'icon': null,
        'category': 'GRAMMAR',
        'wordCount': 10,
      },
    };

void main() {
  test('Attempt.fromJson maps type, score and date label', () {
    final a = Attempt.fromJson({
      'id': '1',
      'type': 'TOEIC',
      'title': 'Luyện thi TOEIC',
      'totalQuestions': 10,
      'correctCount': 7,
      'scorePercent': 70,
      'createdAt': '2026-10-04T05:54:58.304608400Z',
    });
    expect(a.type, AttemptType.toeic);
    expect(a.type.apiValue, 'TOEIC');
    expect(a.scorePercent, 70);
    expect(a.dateLabel, matches(RegExp(r'^\d{2}/\d{2}/2026 \d{2}:\d{2}$')));
  });

  test('Achievement.progress is clamped and maxed is derived from tier', () {
    const a = Achievement(
      code: 'STREAK', title: 't', description: 'd',
      tier: 1, maxTier: 4, current: 2, nextTarget: 7,
    );
    expect(a.unlocked, isTrue);
    expect(a.maxed, isFalse);
    expect(a.progress, closeTo(2 / 7, 1e-9));

    const maxed = Achievement(
      code: 'STREAK', title: 't', description: 'd',
      tier: 4, maxTier: 4, current: 50, nextTarget: 30,
    );
    expect(maxed.maxed, isTrue);
    expect(maxed.progress, 1);
  });

  test('Course.nextUnit is the first incomplete unit, null when all done', () {
    Course build(List<Map<String, dynamic>> units) => Course.fromJson({
          'id': '1', 'title': 'c', 'description': null, 'icon': null,
          'enrolled': true, 'unitCount': units.length, 'completedUnits': 0,
          'totalItems': 20, 'masteredItems': 5, 'completed': false,
          'units': units,
        });

    final partial = build([
      _unit('1', 1, completed: true),
      _unit('2', 1, completed: false),
      _unit('3', 2, completed: false),
    ]);
    expect(partial.nextUnit?.id, '2');
    expect(partial.units.first.categoryLabel, 'Ngữ pháp');

    expect(build([_unit('1', 1, completed: true)]).nextUnit, isNull);
    // Danh sách khoá học không có `units` -> rỗng, không crash.
    expect(Course.fromJson({
      'id': '1', 'title': 'c', 'description': null, 'icon': null,
      'enrolled': false, 'unitCount': 0, 'completedUnits': 0,
      'totalItems': 0, 'masteredItems': 0, 'completed': false,
    }).units, isEmpty);
  });

  test('Course: chứng chỉ lưu vĩnh viễn tách khỏi completed (khoá có thêm nội dung)', () {
    final c = Course.fromJson({
      'id': '1', 'title': 'c', 'description': null, 'icon': null,
      'enrolled': true, 'unitCount': 2, 'completedUnits': 1,
      'totalItems': 20, 'masteredItems': 15, 'completed': false,
      'certified': true, 'certifiedAt': '2026-11-01T03:00:00Z',
    });
    expect(c.completed, isFalse);
    expect(c.certified, isTrue);
    expect(c.certifiedAt?.toUtc(), DateTime.utc(2026, 11, 1, 3));
    // Backend cũ không trả trường mới -> chưa có chứng chỉ, không crash.
    final old = Course.fromJson({
      'id': '1', 'title': 'c', 'description': null, 'icon': null,
      'enrolled': false, 'unitCount': 0, 'completedUnits': 0,
      'totalItems': 0, 'masteredItems': 0, 'completed': false,
    });
    expect(old.certified, isFalse);
    expect(old.certifiedAt, isNull);
  });

  test('assessment tests have unique ids and valid difficulty ranges', () {
    final ids = assessmentTests.map((t) => t.id).toSet();
    expect(ids.length, assessmentTests.length);
    for (final t in assessmentTests) {
      expect(t.minDifficulty, inInclusiveRange(1, 3));
      expect(t.maxDifficulty, inInclusiveRange(t.minDifficulty, 3));
      expect(t.questionCount, greaterThan(0));
    }
  });
}

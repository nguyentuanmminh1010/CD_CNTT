import '../../vocabulary/domain/vocabulary_models.dart';

/// Một Unit trong lộ trình khoá học — trỏ tới một chủ đề học có sẵn.
class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.level,
    required this.position,
    required this.topic,
    required this.category,
    required this.totalItems,
    required this.masteredItems,
    required this.completed,
    required this.locked,
  });

  final String id;
  final int level;
  final int position;
  final VocabularyTopic topic;

  /// 'VOCABULARY' | 'GRAMMAR' | 'SENTENCE'.
  final String category;
  final int totalItems;
  final int masteredItems;
  final bool completed;

  /// Level trước chưa vượt Level Test nên Unit này đang bị khoá.
  final bool locked;

  double get progress => totalItems == 0 ? 0 : masteredItems / totalItems;

  String get categoryLabel => switch (category) {
        'GRAMMAR' => 'Ngữ pháp',
        'SENTENCE' => 'Mẫu câu',
        _ => 'Từ vựng',
      };

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    final topic = json['topic'] as Map<String, dynamic>;
    return CourseUnit(
      id: json['id'] as String,
      level: json['level'] as int,
      position: json['position'] as int,
      topic: VocabularyTopic.fromJson(topic),
      category: topic['category'] as String,
      totalItems: json['totalItems'] as int,
      masteredItems: json['masteredItems'] as int,
      completed: json['completed'] as bool,
      locked: json['locked'] as bool? ?? false,
    );
  }
}

/// Kết quả Level Test của một Level: điểm cao nhất và đã vượt ngưỡng chưa.
class LevelResult {
  const LevelResult({
    required this.level,
    required this.bestPercent,
    required this.attempted,
    required this.passed,
  });

  final int level;
  final int bestPercent;
  final bool attempted;
  final bool passed;

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
        level: json['level'] as int,
        bestPercent: json['bestPercent'] as int,
        attempted: json['attempted'] as bool,
        passed: json['passed'] as bool,
      );
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.enrolled,
    required this.unitCount,
    required this.completedUnits,
    required this.totalItems,
    required this.masteredItems,
    required this.completed,
    required this.units,
    this.levelResults = const [],
    this.certified = false,
    this.certifiedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? icon;
  final bool enrolled;
  final int unitCount;
  final int completedUnits;
  final int totalItems;
  final int masteredItems;
  final bool completed;

  /// Đã nhận giấy chứng nhận (lưu vĩnh viễn từ lần hoàn thành đầu) — vẫn true khi khoá có thêm nội dung, lúc đó
  /// [completed] có thể false vì còn mục mới chưa học.
  final bool certified;
  final DateTime? certifiedAt;

  /// Chỉ có ở chi tiết một khoá học; rỗng ở danh sách.
  final List<CourseUnit> units;

  /// Kết quả Level Test theo từng Level (chỉ có ở chi tiết).
  final List<LevelResult> levelResults;

  LevelResult? resultFor(int level) {
    for (final r in levelResults) {
      if (r.level == level) return r;
    }
    return null;
  }

  double get progress => totalItems == 0 ? 0 : masteredItems / totalItems;

  /// Unit đầu tiên chưa hoàn thành (để nút "Tiếp tục học" nhảy tới).
  CourseUnit? get nextUnit {
    for (final u in units) {
      if (!u.completed && !u.locked) return u;
    }
    return null;
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List<dynamic>? ?? const [])
        .map((e) => CourseUnit.fromJson(e as Map<String, dynamic>))
        .toList();
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      enrolled: json['enrolled'] as bool,
      unitCount: json['unitCount'] as int,
      completedUnits: json['completedUnits'] as int,
      totalItems: json['totalItems'] as int,
      masteredItems: json['masteredItems'] as int,
      completed: json['completed'] as bool,
      certified: json['certified'] as bool? ?? false,
      certifiedAt: DateTime.tryParse(json['certifiedAt'] as String? ?? '')?.toLocal(),
      units: units,
      levelResults: (json['levelResults'] as List<dynamic>? ?? const [])
          .map((e) => LevelResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

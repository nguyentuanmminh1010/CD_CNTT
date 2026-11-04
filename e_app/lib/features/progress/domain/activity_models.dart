class ActivityDay {
  const ActivityDay({required this.date, required this.itemsCompleted});

  final DateTime date;
  final int itemsCompleted;

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      date: DateTime.parse(json['activityDate'] as String),
      itemsCompleted: json['itemsCompleted'] as int,
    );
  }
}

class ActivitySummary {
  const ActivitySummary({
    required this.currentStreak,
    required this.totalActiveDays,
    required this.totalItemsCompleted,
    required this.recentDays,
  });

  final int currentStreak;
  final int totalActiveDays;
  final int totalItemsCompleted;
  final List<ActivityDay> recentDays;

  /// Đơn giản hoá "trình độ" từ tổng số câu đã làm — cứ 30 câu lên 1 cấp,
  /// bắt đầu từ Cấp 1. Không phải điểm số CEFR/TOEIC thật, chỉ là chỉ số
  /// động viên hiển thị ở Home thay cho số tĩnh trước đây.
  int get level => (totalItemsCompleted / 30).floor() + 1;

  factory ActivitySummary.empty() => const ActivitySummary(
        currentStreak: 0,
        totalActiveDays: 0,
        totalItemsCompleted: 0,
        recentDays: [],
      );

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    final days = json['recentDays'] as List<dynamic>;
    return ActivitySummary(
      currentStreak: json['currentStreak'] as int,
      totalActiveDays: json['totalActiveDays'] as int,
      totalItemsCompleted: json['totalItemsCompleted'] as int,
      recentDays: days
          .map((e) => ActivityDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MasteryOverview {
  const MasteryOverview({required this.totalItems, required this.masteredItems});

  final int totalItems;
  final int masteredItems;

  double get ratio => totalItems == 0 ? 0 : masteredItems / totalItems;

  factory MasteryOverview.fromJson(Map<String, dynamic> json) {
    return MasteryOverview(
      totalItems: json['totalItems'] as int,
      masteredItems: json['masteredItems'] as int,
    );
  }
}

/// Tổng số mục và số mục đã thuộc của MỘT mảng nội dung (Vocabulary/Grammar/
/// Sentence) — dùng vẽ radar chart theo mảng ở Hồ sơ (`masteryByCategory`).
class CategoryMastery {
  const CategoryMastery({
    required this.category,
    required this.totalItems,
    required this.masteredItems,
  });

  final String category;
  final int totalItems;
  final int masteredItems;

  double get ratio => totalItems == 0 ? 0 : masteredItems / totalItems;

  String get label => switch (category) {
        'GRAMMAR' => 'Ngữ pháp',
        'SENTENCE' => 'Câu mẫu',
        _ => 'Từ vựng',
      };

  factory CategoryMastery.fromJson(Map<String, dynamic> json) {
    return CategoryMastery(
      category: json['category'] as String,
      totalItems: json['totalItems'] as int,
      masteredItems: json['masteredItems'] as int,
    );
  }
}

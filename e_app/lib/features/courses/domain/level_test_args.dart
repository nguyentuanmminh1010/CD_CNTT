import 'course.dart';

/// Ngưỡng % tối thiểu để vượt một Level Test (khớp `CourseService.PASS_PERCENT` ở backend).
const levelTestPassPercent = 70;

/// Tham số một bài "Level Test": ôn lại toàn bộ các Unit của một Level trong
/// một khoá học. Đề rút ngẫu nhiên từ mục của chính các chủ đề trong Level.
class LevelTestArgs {
  const LevelTestArgs({
    required this.courseId,
    required this.courseTitle,
    required this.level,
    required this.units,
  });

  final String courseId;
  final String courseTitle;
  final int level;
  final List<CourseUnit> units;

  String get title => '$courseTitle · Level $level';

  /// Khoá tham chiếu ghi vào `Attempt.refKey` để backend biết Level nào đã vượt.
  String get refKey => 'level:$courseId:$level';

  int get questionCount => units.fold(0, (a, u) => a + u.totalItems).clamp(0, 12);
}

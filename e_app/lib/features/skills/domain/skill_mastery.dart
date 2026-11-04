import 'skill_type.dart';

/// Tổng số lượt luyện tập + số lượt đúng của MỘT kỹ năng — `totalAttempts ==
/// 0` khi người dùng chưa luyện kỹ năng đó (vd Nghe/Nói khi chưa có bài tập).
class SkillMastery {
  const SkillMastery({
    required this.skill,
    required this.totalAttempts,
    required this.correctAttempts,
  });

  final SkillType skill;
  final int totalAttempts;
  final int correctAttempts;

  double get ratio => totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      skill: skillTypeFromString(json['skill'] as String),
      totalAttempts: json['totalAttempts'] as int,
      correctAttempts: json['correctAttempts'] as int,
    );
  }
}

/// Phạm vi bảng xếp hạng: mọi người, 7 ngày gần nhất, hoặc chỉ bạn bè (người bạn theo dõi + mình).
enum LeaderboardPeriod {
  all('ALL', 'Tất cả'),
  week('WEEK', 'Tuần này'),
  friends('FRIENDS', 'Bạn bè');

  const LeaderboardPeriod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
    required this.me,
    this.avatar,
  });

  /// Ảnh đại diện dạng data URL, null nếu chưa đặt.
  final String? avatar;

  final int rank;
  final String userId;
  final String displayName;

  /// Số mục nội dung đã thuộc — điểm xếp hạng.
  final int score;
  final bool me;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      score: json['score'] as int,
      me: json['me'] as bool,
      avatar: json['avatar'] as String?,
    );
  }
}

/// Một thành tựu có nhiều bậc (vd "Chuỗi ngày học" bậc 2/4) — tính ở backend.
class Achievement {
  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.tier,
    required this.maxTier,
    required this.current,
    required this.nextTarget,
  });

  final String code;
  final String title;
  final String description;
  final int tier;
  final int maxTier;
  final int current;
  final int nextTarget;

  bool get unlocked => tier > 0;
  bool get maxed => tier >= maxTier;

  /// Tiến độ tới mốc kế tiếp, 0..1.
  double get progress => nextTarget == 0 ? 0 : (current / nextTarget).clamp(0, 1).toDouble();

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tier: json['tier'] as int,
      maxTier: json['maxTier'] as int,
      current: json['current'] as int,
      nextTarget: json['nextTarget'] as int,
    );
  }
}

class TopicReview {
  const TopicReview({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.updatedAt,
    required this.mine,
  });

  final String id;
  final String displayName;

  /// Ảnh đại diện dạng data URL, null nếu chưa đặt.
  final String? avatar;
  final int rating;
  final String? comment;
  final DateTime updatedAt;
  final bool mine;

  factory TopicReview.fromJson(Map<String, dynamic> json) {
    return TopicReview(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mine: json['mine'] as bool,
    );
  }
}

/// Tổng hợp đánh giá của một bài học: điểm trung bình, số lượt, đánh giá của
/// chính người dùng (nếu có) và các đánh giá mới nhất.
class TopicReviews {
  const TopicReviews({
    required this.average,
    required this.count,
    required this.myReview,
    required this.reviews,
  });

  final double average;
  final int count;
  final TopicReview? myReview;
  final List<TopicReview> reviews;

  factory TopicReviews.fromJson(Map<String, dynamic> json) {
    final my = json['myReview'] as Map<String, dynamic>?;
    return TopicReviews(
      average: (json['average'] as num).toDouble(),
      count: json['count'] as int,
      myReview: my == null ? null : TopicReview.fromJson(my),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => TopicReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

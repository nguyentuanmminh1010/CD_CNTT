import '../../review/domain/wrong_item.dart';
import '../../vocabulary/domain/vocabulary_models.dart';

/// Một kết quả tìm kiếm (Vocabulary/Grammar/Sentence lẫn lộn) — cùng hình dạng
/// dữ liệu với `WrongItem` (item + topic) nhưng ngữ nghĩa khác (không phải mục
/// "chưa thuộc"), nên tách class riêng cho rõ ràng thay vì tái dùng `WrongItem`.
class SearchResult {
  const SearchResult({
    required this.item,
    required this.category,
    required this.topicId,
    required this.topicName,
  });

  final VocabularyItem item;
  final ReviewCategory category;
  final String topicId;
  final String topicName;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final topic = json['topic'] as Map<String, dynamic>;
    return SearchResult(
      item: VocabularyItem.fromJson(json),
      category: reviewCategoryFromString(topic['category'] as String),
      topicId: topic['id'] as String,
      topicName: topic['name'] as String,
    );
  }
}

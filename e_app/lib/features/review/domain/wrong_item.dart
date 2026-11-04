import '../../vocabulary/domain/vocabulary_models.dart';

/// Mảng nội dung mà một [WrongItem] thuộc về — dùng để biết gọi mutation nào
/// (`markVocabularyItemMastered`/`markGrammarItemMastered`/`markSentenceItemMastered`)
/// và hiển thị nhãn/màu phù hợp.
enum ReviewCategory { vocabulary, grammar, sentence }

ReviewCategory reviewCategoryFromString(String value) {
  switch (value) {
    case 'GRAMMAR':
      return ReviewCategory.grammar;
    case 'SENTENCE':
      return ReviewCategory.sentence;
    default:
      return ReviewCategory.vocabulary;
  }
}

extension ReviewCategoryLabel on ReviewCategory {
  String get label => switch (this) {
        ReviewCategory.vocabulary => 'Vocabulary',
        ReviewCategory.grammar => 'Grammar',
        ReviewCategory.sentence => 'Sentences',
      };
}

/// Một mục (Vocabulary/Grammar/Sentence) mà người dùng đang đăng nhập từng
/// đánh dấu "chưa thuộc"/trả lời sai gần nhất — dữ liệu cho tab Ôn tập, lấy từ
/// query `wrongItems` (dùng chung `UserLearningItemProgress.mastered == false`,
/// không cần bảng WrongAnswer riêng — xem CLAUDE.md > Kiến trúc Backend).
class WrongItem {
  const WrongItem({
    required this.item,
    required this.category,
    required this.topicId,
    required this.topicName,
  });

  final VocabularyItem item;
  final ReviewCategory category;
  final String topicId;
  final String topicName;

  factory WrongItem.fromJson(Map<String, dynamic> json) {
    final topic = json['topic'] as Map<String, dynamic>;
    return WrongItem(
      item: VocabularyItem.fromJson(json),
      category: reviewCategoryFromString(topic['category'] as String),
      topicId: topic['id'] as String,
      topicName: topic['name'] as String,
    );
  }
}

import '../../attempts/data/attempt_repository.dart';
import '../../courses/domain/level_test_args.dart';
import '../../grammar/data/grammar_repository.dart';
import '../domain/assessment_test.dart';
import '../../review/domain/wrong_item.dart';
import '../../sentences/data/sentence_repository.dart';
import '../../vocabulary/data/vocabulary_repository.dart';
import '../../vocabulary/domain/vocabulary_models.dart';

/// Đề "Bài đánh giá" theo category — ghép từ dữ liệu Vocabulary/Grammar/
/// Sentences đã có sẵn (composition, không lặp lại logic gọi GraphQL) thay vì
/// thêm query mới ở backend. Lấy vài chủ đề đầu của mảng tương ứng làm đề mẫu
/// — đủ để có một lượt đánh giá có ý nghĩa mà không cần thêm API "random N
/// items across topics" riêng.
class AssessmentRepository {
  AssessmentRepository({
    required this.vocabularyRepository,
    required this.grammarRepository,
    required this.sentenceRepository,
    required this.attemptRepository,
  });

  final VocabularyRepository vocabularyRepository;
  final GrammarRepository grammarRepository;
  final SentenceRepository sentenceRepository;
  final AttemptRepository attemptRepository;

  /// Đề Level Test: gom mục của mọi chủ đề trong Level (đúng repository theo
  /// category của từng Unit), xáo trộn rồi giữ tối đa [limit] câu.
  Future<List<WrongItem>> fetchLevelTestItems(LevelTestArgs args, {int limit = 12}) async {
    final parts = await Future.wait([
      for (final unit in args.units)
        () async {
          final category = switch (unit.category) {
            'GRAMMAR' => ReviewCategory.grammar,
            'SENTENCE' => ReviewCategory.sentence,
            _ => ReviewCategory.vocabulary,
          };
          final items = await switch (category) {
            ReviewCategory.vocabulary => vocabularyRepository.fetchItems(unit.topic.id),
            ReviewCategory.grammar => grammarRepository.fetchItems(unit.topic.id),
            ReviewCategory.sentence => sentenceRepository.fetchItems(unit.topic.id),
          };
          return [
            for (final item in items)
              WrongItem(
                item: item,
                category: category,
                topicId: unit.topic.id,
                topicName: unit.topic.name,
              ),
          ];
        }(),
    ]);
    final all = [for (final p in parts) ...p]..shuffle();
    return all.take(limit).toList();
  }

  /// Đề cho một bài test cụ thể ở tab Đánh giá (query `assessmentItems`,
  /// ngẫu nhiên theo category + độ khó). Bài trộn 3 mảng chia đều số câu cho
  /// từng mảng — để mỗi mảng đủ câu làm đáp án nhiễu cho nhau.
  Future<List<WrongItem>> fetchTestItems(AssessmentTest test) async {
    if (test.category != null) {
      return attemptRepository.fetchAssessmentItems(
        category: test.category,
        minDifficulty: test.minDifficulty,
        maxDifficulty: test.maxDifficulty,
        limit: test.questionCount,
      );
    }
    final perCategory = (test.questionCount / ReviewCategory.values.length).ceil();
    final parts = await Future.wait([
      for (final c in ReviewCategory.values)
        attemptRepository.fetchAssessmentItems(
          category: c,
          minDifficulty: test.minDifficulty,
          maxDifficulty: test.maxDifficulty,
          limit: perCategory,
        ),
    ]);
    final all = [for (final p in parts) ...p]..shuffle();
    return all.take(test.questionCount).toList();
  }

  /// [questionLimit] khi khác null sẽ xáo trộn rồi chỉ giữ lại đúng từng đó
  /// câu — dùng cho bài kiểm tra xếp lớp (10-15 câu, gọn hơn "Bài đánh giá"
  /// thường vốn không giới hạn số câu).
  Future<List<WrongItem>> fetchAssessmentItems(
    ReviewCategory? category, {
    int? questionLimit,
  }) async {
    final items = await switch (category) {
      null => () async {
          final vocab = await _sample(vocabularyRepository.fetchTopics,
              vocabularyRepository.fetchItems, ReviewCategory.vocabulary, topicLimit: 1);
          final grammar = await _sample(grammarRepository.fetchTopics,
              grammarRepository.fetchItems, ReviewCategory.grammar, topicLimit: 1);
          final sentence = await _sample(sentenceRepository.fetchTopics,
              sentenceRepository.fetchItems, ReviewCategory.sentence, topicLimit: 1);
          return [...vocab, ...grammar, ...sentence];
        }(),
      ReviewCategory.vocabulary => _sample(vocabularyRepository.fetchTopics,
          vocabularyRepository.fetchItems, ReviewCategory.vocabulary, topicLimit: 2),
      ReviewCategory.grammar => _sample(grammarRepository.fetchTopics,
          grammarRepository.fetchItems, ReviewCategory.grammar, topicLimit: 2),
      ReviewCategory.sentence => _sample(sentenceRepository.fetchTopics,
          sentenceRepository.fetchItems, ReviewCategory.sentence, topicLimit: 2),
    };
    if (questionLimit == null || items.length <= questionLimit) return items;
    final shuffled = [...items]..shuffle();
    return shuffled.take(questionLimit).toList();
  }

  Future<List<WrongItem>> _sample(
    Future<List<VocabularyTopic>> Function() fetchTopics,
    Future<List<VocabularyItem>> Function(String topicId) fetchItems,
    ReviewCategory category, {
    required int topicLimit,
  }) async {
    final topics = await fetchTopics();
    final result = <WrongItem>[];
    for (final topic in topics.take(topicLimit)) {
      final items = await fetchItems(topic.id);
      result.addAll(items.map((item) => WrongItem(
            item: item,
            category: category,
            topicId: topic.id,
            topicName: topic.name,
          )));
    }
    return result;
  }
}

import '../../grammar/application/grammar_providers.dart';
import '../../review/domain/wrong_item.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../domain/practice_models.dart';
import '../presentation/practice_session_screen.dart';

/// Lượt luyện một chủ đề (hoặc bộ thẻ riêng) theo dạng [kind] — mục lấy đúng repository của [category].
PracticeConfig topicPracticeConfig({
  required ReviewCategory category,
  required String topicId,
  required String topicName,
  required PracticeKind kind,
}) {
  return PracticeConfig(
    title: topicName,
    kind: kind,
    limit: kind == PracticeKind.mixed ? 15 : null,
    load: (ref) async {
      final items = await switch (category) {
        ReviewCategory.vocabulary => ref.read(vocabularyRepositoryProvider).fetchItems(topicId),
        ReviewCategory.grammar => ref.read(grammarRepositoryProvider).fetchItems(topicId),
        ReviewCategory.sentence => ref.read(sentenceRepositoryProvider).fetchItems(topicId),
      };
      return [
        for (final item in items)
          WrongItem(item: item, category: category, topicId: topicId, topicName: topicName),
      ];
    },
    emptyMessage: switch (kind) {
      PracticeKind.wordOrder => 'Chủ đề này chưa có câu ví dụ đủ dài để sắp xếp.',
      PracticeKind.matching => 'Cần ít nhất 3 mục để ghép cặp.',
      _ => 'Chủ đề này chưa đủ nội dung để làm dạng bài này (cần ít nhất 2 mục).',
    },
  );
}

/// Đường dẫn route `/vocabulary|/grammar|/sentences` → mảng.
ReviewCategory categoryOfBasePath(String basePath) => switch (basePath) {
      '/grammar' => ReviewCategory.grammar,
      '/sentences' => ReviewCategory.sentence,
      _ => ReviewCategory.vocabulary,
    };

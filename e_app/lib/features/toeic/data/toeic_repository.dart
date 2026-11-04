import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../../review/domain/wrong_item.dart';

/// Đề luyện thi TOEIC lấy từ `toeicPracticeItems` — các mục (mọi category)
/// người dùng chưa "đã thuộc", độ khó thấp trước để phù hợp trình độ hiện tại
/// rồi tăng dần (xem `LearningService.getToeicPracticeItems` ở backend).
/// Tái dùng thẳng [WrongItem]/[ReviewCategory] của feature Ôn tập vì hình
/// dạng dữ liệu (1 mục + category + chủ đề) giống hệt, không phải "câu sai".
class ToeicRepository {
  ToeicRepository(this._client);

  final GraphQLClient _client;

  static const _practiceItemsQuery = r'''
    query ToeicPracticeItems($limit: Int) {
      toeicPracticeItems(limit: $limit) {
        id
        term
        phonetic
        meaning
        example
        mastered
        difficultyLevel
        topic {
          id
          name
          icon
          category
        }
      }
    }
  ''';

  Future<List<WrongItem>> fetchPracticeItems({int limit = 10}) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_practiceItemsQuery),
        variables: {'limit': limit},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['toeicPracticeItems'] as List<dynamic>;
    return list.map((e) => WrongItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Cùng 3 mutation `mark*ItemMastered` đã có, không có mutation riêng cho
  /// luyện thi TOEIC — xem `ReviewRepository.markMastered` cho cùng pattern.
  Future<void> markMastered(ReviewCategory category, String itemId, bool mastered) async {
    final mutationName = switch (category) {
      ReviewCategory.vocabulary => 'markVocabularyItemMastered',
      ReviewCategory.grammar => 'markGrammarItemMastered',
      ReviewCategory.sentence => 'markSentenceItemMastered',
    };
    final result = await _client.mutate(
      MutationOptions(
        document: gql('''
          mutation Mark(\$itemId: ID!, \$mastered: Boolean!) {
            $mutationName(itemId: \$itemId, mastered: \$mastered) {
              id
              mastered
            }
          }
        '''),
        variables: {'itemId': itemId, 'mastered': mastered},
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
  }
}

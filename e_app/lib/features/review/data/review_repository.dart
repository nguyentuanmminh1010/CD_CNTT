import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/wrong_item.dart';

class ReviewRepository {
  ReviewRepository(this._client);

  final GraphQLClient _client;

  static const _wrongItemsQuery = r'''
    query WrongItems {
      wrongItems {
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

  static const _dueItemsQuery = r'''
    query DueItems($limit: Int) {
      dueItems(limit: $limit) {
        id term phonetic meaning example mastered difficultyLevel
        topic { id name icon category }
      }
    }
  ''';

  /// Các mục đến hạn ôn lại theo lịch lặp lại ngắt quãng (Leitner).
  Future<List<WrongItem>> fetchDueItems({int limit = 30}) async {
    final result = await _client.query(QueryOptions(
      document: gql(_dueItemsQuery),
      variables: {'limit': limit},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['dueItems'] as List<dynamic>;
    return list.map((e) => WrongItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> fetchDueCount() async {
    final result = await _client.query(QueryOptions(
      document: gql('{ dueItemCount }'),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return result.data!['dueItemCount'] as int;
  }

  Future<List<WrongItem>> fetchWrongItems() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_wrongItemsQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['wrongItems'] as List<dynamic>;
    return list.map((e) => WrongItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Gọi đúng mutation `mark*ItemMastered` theo [category] — cùng 3 mutation đã
  /// có sẵn cho Flashcard/Trắc nghiệm, không cần API riêng cho Ôn tập.
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

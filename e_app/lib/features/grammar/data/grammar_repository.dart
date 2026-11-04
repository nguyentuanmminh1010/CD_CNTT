import 'package:graphql/client.dart';

import '../../vocabulary/domain/vocabulary_models.dart';

/// Cùng hình dạng dữ liệu với Vocabulary (xem CLAUDE.md > Kiến trúc Backend:
/// LearningTopic/LearningItem dùng chung cho cả 3 mảng) nên tái dùng thẳng
/// [VocabularyTopic]/[VocabularyItem] — chỉ khác tên field GraphQL.
class GrammarRepository {
  GrammarRepository(this._client);

  final GraphQLClient _client;

  static const _topicsQuery = r'''
    query GrammarTopics {
      grammarTopics {
        id
        name
        description
        icon
        wordCount
        category
        mine
        editable
        guide
        shareCode
      }
    }
  ''';

  static const _itemsQuery = r'''
    query GrammarItems($topicId: ID!) {
      grammarItems(topicId: $topicId) {
        id
        term
        phonetic
        meaning
        example
        mastered
        difficultyLevel
        explanation
        imageUrl
        audioUrl
      }
    }
  ''';

  static const _markMasteredMutation = r'''
    mutation MarkGrammarMastered($itemId: ID!, $mastered: Boolean!) {
      markGrammarItemMastered(itemId: $itemId, mastered: $mastered) {
        id
        mastered
      }
    }
  ''';

  Future<List<VocabularyTopic>> fetchTopics() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_topicsQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final list = result.data!['grammarTopics'] as List<dynamic>;
    return list
        .map((e) => VocabularyTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VocabularyItem>> fetchItems(String topicId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_itemsQuery),
        variables: {'topicId': topicId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final list = result.data!['grammarItems'] as List<dynamic>;
    return list
        .map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markMastered(String itemId, bool mastered) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_markMasteredMutation),
        variables: {'itemId': itemId, 'mastered': mastered},
      ),
    );
    if (result.hasException) throw result.exception!;
  }
}

import 'package:graphql/client.dart';

import '../domain/vocabulary_models.dart';

class VocabularyRepository {
  VocabularyRepository(this._client);

  final GraphQLClient _client;

  static const _topicsQuery = r'''
    query VocabularyTopics {
      vocabularyTopics {
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
    query VocabularyItems($topicId: ID!) {
      vocabularyItems(topicId: $topicId) {
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
    mutation MarkMastered($itemId: ID!, $mastered: Boolean!) {
      markVocabularyItemMastered(itemId: $itemId, mastered: $mastered) {
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
    final list = result.data!['vocabularyTopics'] as List<dynamic>;
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
    final list = result.data!['vocabularyItems'] as List<dynamic>;
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

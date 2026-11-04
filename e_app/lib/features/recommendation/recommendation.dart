import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

import '../../core/network/graphql_client.dart';
import '../../core/network/graphql_failure.dart';
import '../vocabulary/domain/vocabulary_models.dart';

/// Chủ đề nên luyện tiếp, kèm điểm thành thạo (mastery 0..1) của người dùng ở chủ đề đó
/// và độ khó nên luyện — backend tính từ điểm mastery cập nhật sau mỗi câu trả lời.
class RecommendedTopic {
  const RecommendedTopic({
    required this.topic,
    required this.category,
    required this.score,
    required this.suggestedDifficulty,
    required this.totalItems,
    required this.masteredItems,
  });

  final VocabularyTopic topic;

  /// 'VOCABULARY' | 'GRAMMAR' | 'SENTENCE'.
  final String category;
  final double score;
  final int suggestedDifficulty;
  final int totalItems;
  final int masteredItems;

  String get difficultyLabel => switch (suggestedDifficulty) {
        1 => 'Cơ bản',
        2 => 'Trung bình',
        _ => 'Nâng cao',
      };

  String get categoryLabel => switch (category) {
        'GRAMMAR' => 'Ngữ pháp',
        'SENTENCE' => 'Mẫu câu',
        _ => 'Từ vựng',
      };

  /// Route gốc của mảng nội dung này (khớp `AppRoutes.vocabulary/grammar/sentences`).
  String get basePath => switch (category) {
        'GRAMMAR' => '/grammar',
        'SENTENCE' => '/sentences',
        _ => '/vocabulary',
      };

  factory RecommendedTopic.fromJson(Map<String, dynamic> json) {
    final topic = json['topic'] as Map<String, dynamic>;
    return RecommendedTopic(
      topic: VocabularyTopic.fromJson(topic),
      category: topic['category'] as String,
      score: (json['score'] as num).toDouble(),
      suggestedDifficulty: json['suggestedDifficulty'] as int,
      totalItems: json['totalItems'] as int,
      masteredItems: json['masteredItems'] as int,
    );
  }
}

class RecommendationRepository {
  RecommendationRepository(this._client);

  final GraphQLClient _client;

  static const _query = r'''
    query Recommended($limit: Int) {
      recommendedTopics(limit: $limit) {
        score suggestedDifficulty totalItems masteredItems
        topic { id name description icon category wordCount }
      }
    }
  ''';

  Future<List<RecommendedTopic>> fetch({int limit = 3}) async {
    final result = await _client.query(QueryOptions(
      document: gql(_query),
      variables: {'limit': limit},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return (result.data!['recommendedTopics'] as List<dynamic>)
        .map((e) => RecommendedTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(ref.watch(graphQLClientProvider));
});

final recommendedTopicsProvider = FutureProvider.autoDispose<List<RecommendedTopic>>((ref) {
  return ref.watch(recommendationRepositoryProvider).fetch();
});

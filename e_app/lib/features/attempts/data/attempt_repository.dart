import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../../review/domain/wrong_item.dart';
import '../domain/attempt.dart';

class AttemptRepository {
  AttemptRepository(this._client);

  final GraphQLClient _client;

  static const _attemptsQuery = r'''
    query MyAttempts($limit: Int) {
      myAttempts(limit: $limit) {
        id type title totalQuestions correctCount scorePercent createdAt
      }
    }
  ''';

  static const _finishMutation = r'''
    mutation FinishAttempt($key: String!, $type: AttemptType!, $title: String!, $refKey: String, $expected: Int) {
      finishAttempt(attemptKey: $key, type: $type, title: $title, refKey: $refKey, expectedTotal: $expected) {
        id type title totalQuestions correctCount scorePercent createdAt
      }
    }
  ''';

  static const _answersQuery = r'''
    query AttemptAnswers($id: ID!) {
      attemptAnswers(attemptId: $id) { itemId term meaning mode answer correct correctAnswer explanation imageUrl }
    }
  ''';

  static const _assessmentItemsQuery = r'''
    query AssessmentItems($category: LearningCategory, $min: Int, $max: Int, $limit: Int) {
      assessmentItems(category: $category, minDifficulty: $min, maxDifficulty: $max, limit: $limit) {
        id term phonetic meaning example mastered difficultyLevel
        topic { id name icon category }
      }
    }
  ''';

  Future<List<Attempt>> fetchAttempts({int limit = 20}) async {
    final result = await _client.query(QueryOptions(
      document: gql(_attemptsQuery),
      variables: {'limit': limit},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['myAttempts'] as List<dynamic>;
    return list.map((e) => Attempt.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Kết thúc một lượt: backend gom các câu đã chấm có cùng [attemptKey] và TỰ TÍNH điểm.
  /// [expectedTotal] = số câu của đề (để không thể thổi điểm bằng cách bỏ câu sai).
  Future<Attempt> finishAttempt({
    required String attemptKey,
    required AttemptType type,
    required String title,
    required int expectedTotal,
    String? refKey,
  }) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_finishMutation),
      variables: {
        'key': attemptKey,
        'type': type.apiValue,
        'title': title,
        'refKey': refKey,
        'expected': expectedTotal,
      },
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return Attempt.fromJson(result.data!['finishAttempt'] as Map<String, dynamic>);
  }

  /// Từng câu của một lượt (đáp án đã chọn vs đáp án đúng) — màn "xem lại đáp án".
  Future<List<AttemptAnswerView>> fetchAnswers(String attemptId) async {
    final result = await _client.query(QueryOptions(
      document: gql(_answersQuery),
      variables: {'id': attemptId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return (result.data!['attemptAnswers'] as List<dynamic>)
        .map((e) => AttemptAnswerView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đề ngẫu nhiên cho một bài test — [category] null = mọi category.
  Future<List<WrongItem>> fetchAssessmentItems({
    ReviewCategory? category,
    required int minDifficulty,
    required int maxDifficulty,
    required int limit,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(_assessmentItemsQuery),
      variables: {
        'category': category == null ? null : _apiCategory(category),
        'min': minDifficulty,
        'max': maxDifficulty,
        'limit': limit,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['assessmentItems'] as List<dynamic>;
    return list.map((e) => WrongItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _apiCategory(ReviewCategory c) => switch (c) {
        ReviewCategory.vocabulary => 'VOCABULARY',
        ReviewCategory.grammar => 'GRAMMAR',
        ReviewCategory.sentence => 'SENTENCE',
      };
}

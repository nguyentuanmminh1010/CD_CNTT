import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/topic_review.dart';

class TopicReviewRepository {
  TopicReviewRepository(this._client);

  final GraphQLClient _client;

  static const _fields = '''
    average count
    myReview { id displayName avatar rating comment updatedAt mine }
    reviews { id displayName avatar rating comment updatedAt mine }
  ''';

  Future<TopicReviews> fetch(String topicId) async {
    final result = await _client.query(QueryOptions(
      document: gql('query R(\$id: ID!) { topicReviews(topicId: \$id) { $_fields } }'),
      variables: {'id': topicId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return TopicReviews.fromJson(result.data!['topicReviews'] as Map<String, dynamic>);
  }

  Future<TopicReviews> submit(String topicId, int rating, String? comment) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(
        'mutation S(\$id: ID!, \$r: Int!, \$c: String) { submitTopicReview(topicId: \$id, rating: \$r, comment: \$c) { $_fields } }',
      ),
      variables: {'id': topicId, 'r': rating, 'c': comment},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return TopicReviews.fromJson(result.data!['submitTopicReview'] as Map<String, dynamic>);
  }
}

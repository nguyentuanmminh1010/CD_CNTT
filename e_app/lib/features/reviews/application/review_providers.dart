import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/review_repository.dart';
import '../domain/topic_review.dart';

final topicReviewRepositoryProvider = Provider<TopicReviewRepository>((ref) {
  return TopicReviewRepository(ref.watch(graphQLClientProvider));
});

final topicReviewsProvider =
    FutureProvider.autoDispose.family<TopicReviews, String>((ref, topicId) {
  return ref.watch(topicReviewRepositoryProvider).fetch(topicId);
});

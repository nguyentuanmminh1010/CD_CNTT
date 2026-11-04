import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/activity_models.dart';

class ProgressRepository {
  ProgressRepository(this._client);

  final GraphQLClient _client;

  static const _activityQuery = r'''
    query MyActivity {
      myActivity {
        currentStreak
        totalActiveDays
        totalItemsCompleted
        recentDays { activityDate itemsCompleted }
      }
    }
  ''';

  static const _masteryQuery = r'''
    query MasteryOverview {
      masteryOverview { totalItems masteredItems }
    }
  ''';

  static const _masteryByCategoryQuery = r'''
    query MasteryByCategory {
      masteryByCategory { category totalItems masteredItems }
    }
  ''';

  Future<ActivitySummary> fetchActivity() async {
    final result = await _client.query(
      QueryOptions(document: gql(_activityQuery), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return ActivitySummary.fromJson(result.data!['myActivity'] as Map<String, dynamic>);
  }

  Future<MasteryOverview> fetchMasteryOverview() async {
    final result = await _client.query(
      QueryOptions(document: gql(_masteryQuery), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return MasteryOverview.fromJson(result.data!['masteryOverview'] as Map<String, dynamic>);
  }

  Future<List<CategoryMastery>> fetchMasteryByCategory() async {
    final result = await _client.query(
      QueryOptions(document: gql(_masteryByCategoryQuery), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['masteryByCategory'] as List<dynamic>;
    return list.map((e) => CategoryMastery.fromJson(e as Map<String, dynamic>)).toList();
  }
}

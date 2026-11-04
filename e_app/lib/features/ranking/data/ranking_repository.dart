import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/ranking_models.dart';

class RankingRepository {
  RankingRepository(this._client);

  final GraphQLClient _client;

  static const _leaderboardQuery = r'''
    query Leaderboard($limit: Int, $period: LeaderboardPeriod) {
      leaderboard(limit: $limit, period: $period) { rank userId displayName score me avatar }
    }
  ''';

  static const _myRankQuery = r'''
    query MyRank($period: LeaderboardPeriod) { myRank(period: $period) { rank userId displayName score me avatar } }
  ''';

  static const _achievementsQuery = r'''
    query Achievements {
      achievements { code title description tier maxTier current nextTarget }
    }
  ''';

  Future<Map<String, dynamic>> _run(String doc, [Map<String, dynamic>? vars]) async {
    final result = await _client.query(QueryOptions(
      document: gql(doc),
      variables: vars ?? const {},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return result.data!;
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 20,
    LeaderboardPeriod period = LeaderboardPeriod.all,
  }) async {
    final data = await _run(_leaderboardQuery, {'limit': limit, 'period': period.apiValue});
    return (data['leaderboard'] as List<dynamic>)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LeaderboardEntry> fetchMyRank({LeaderboardPeriod period = LeaderboardPeriod.all}) async {
    final data = await _run(_myRankQuery, {'period': period.apiValue});
    return LeaderboardEntry.fromJson(data['myRank'] as Map<String, dynamic>);
  }

  Future<List<Achievement>> fetchAchievements() async {
    final data = await _run(_achievementsQuery);
    return (data['achievements'] as List<dynamic>)
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

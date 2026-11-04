import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_models.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository(ref.watch(graphQLClientProvider));
});

/// Tham số: phạm vi xếp hạng (tất cả / tuần này / bạn bè).
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, LeaderboardPeriod>((ref, period) {
  return ref.watch(rankingRepositoryProvider).fetchLeaderboard(period: period);
});

final myRankProvider =
    FutureProvider.autoDispose.family<LeaderboardEntry, LeaderboardPeriod>((ref, period) {
  return ref.watch(rankingRepositoryProvider).fetchMyRank(period: period);
});

final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) {
  return ref.watch(rankingRepositoryProvider).fetchAchievements();
});

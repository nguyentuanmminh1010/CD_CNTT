import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/progress_repository.dart';
import '../domain/activity_models.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(graphQLClientProvider));
});

/// Hoạt động học thật của người dùng (chuỗi ngày, tổng số câu đã làm) — dùng
/// cả ở tab Tiến độ lẫn các chip thống kê ở Home, nên đặt chung 1 provider để
/// 2 nơi luôn đồng bộ dữ liệu.
final activityProvider = FutureProvider.autoDispose<ActivitySummary>((ref) {
  return ref.watch(progressRepositoryProvider).fetchActivity();
});

/// Tổng số mục nội dung và số mục đã thuộc (mọi category) — tiến độ "Ôn thi
/// TOEIC" ở Home, cập nhật thật sau mỗi lượt luyện tập.
final masteryOverviewProvider = FutureProvider.autoDispose<MasteryOverview>((ref) {
  return ref.watch(progressRepositoryProvider).fetchMasteryOverview();
});

/// Tổng số mục/đã thuộc CỦA TỪNG mảng (Vocabulary/Grammar/Sentence) — dùng vẽ
/// radar chart ở tab Hồ sơ.
final masteryByCategoryProvider = FutureProvider.autoDispose<List<CategoryMastery>>((ref) {
  return ref.watch(progressRepositoryProvider).fetchMasteryByCategory();
});

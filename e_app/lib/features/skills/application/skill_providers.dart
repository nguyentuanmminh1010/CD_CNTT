import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/skill_repository.dart';
import '../domain/skill_mastery.dart';

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return SkillRepository(ref.watch(graphQLClientProvider));
});

/// Tổng số lượt luyện tập + số lượt đúng CỦA TỪNG kỹ năng (Đọc/Viết/Nghe/Nói)
/// — dùng vẽ radar chart 4 kỹ năng ở Hồ sơ.
final skillMasteryProvider = FutureProvider.autoDispose<List<SkillMastery>>((ref) {
  return ref.watch(skillRepositoryProvider).fetchSkillMastery();
});

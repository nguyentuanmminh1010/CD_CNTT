import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/review_repository.dart';
import '../domain/wrong_item.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(graphQLClientProvider));
});

class WrongItemsController extends AutoDisposeAsyncNotifier<List<WrongItem>> {
  @override
  Future<List<WrongItem>> build() {
    return ref.watch(reviewRepositoryProvider).fetchWrongItems();
  }

  /// Gỡ một mục khỏi danh sách lỗi sai ngay trên UI (backend đã ghi nhận câu đúng qua `submitAnswer`).
  void removeLocal(String itemId) {
    state = AsyncData([
      for (final w in state.value ?? const <WrongItem>[])
        if (w.item.id != itemId) w,
    ]);
  }

  /// Đánh dấu lại một mục. Khi [mastered] = true, mục coi như đã ôn xong nên
  /// được gỡ khỏi danh sách (optimistic); khi false (trả lời sai lúc ôn tập
  /// bằng trắc nghiệm), mục vẫn còn "sai" nên chỉ ghi tiến độ, không đổi state.
  Future<void> markMastered(ReviewCategory category, String itemId, bool mastered) async {
    final repo = ref.read(reviewRepositoryProvider);
    if (!mastered) {
      await repo.markMastered(category, itemId, false);
      return;
    }

    final previous = state.value ?? [];
    state = AsyncData([
      for (final w in previous)
        if (w.item.id != itemId) w,
    ]);
    try {
      await repo.markMastered(category, itemId, true);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

/// Các mục đến hạn ôn lại (lặp lại ngắt quãng) — hàng đợi "Ôn đến hạn".
final dueItemsProvider = FutureProvider.autoDispose<List<WrongItem>>((ref) {
  return ref.watch(reviewRepositoryProvider).fetchDueItems();
});

final dueItemCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(reviewRepositoryProvider).fetchDueCount();
});

final wrongItemsProvider =
    AsyncNotifierProvider.autoDispose<WrongItemsController, List<WrongItem>>(
  WrongItemsController.new,
);

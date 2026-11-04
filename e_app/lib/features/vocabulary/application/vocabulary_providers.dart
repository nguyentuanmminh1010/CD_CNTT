import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/vocabulary_repository.dart';
import '../domain/vocabulary_models.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository(ref.watch(graphQLClientProvider));
});

final vocabularyTopicsProvider =
    FutureProvider.autoDispose<List<VocabularyTopic>>((ref) {
  return ref.watch(vocabularyRepositoryProvider).fetchTopics();
});

class VocabularyItemsController
    extends AutoDisposeFamilyAsyncNotifier<List<VocabularyItem>, String> {
  @override
  Future<List<VocabularyItem>> build(String topicId) {
    return ref.watch(vocabularyRepositoryProvider).fetchItems(topicId);
  }

  Future<void> markMastered(String itemId, bool mastered) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    final previous = state.value ?? [];

    state = AsyncData([
      for (final item in previous)
        if (item.id == itemId) item.copyWith(mastered: mastered) else item,
    ]);

    try {
      await repo.markMastered(itemId, mastered);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final vocabularyItemsProvider = AsyncNotifierProvider.autoDispose
    .family<VocabularyItemsController, List<VocabularyItem>, String>(
  VocabularyItemsController.new,
);

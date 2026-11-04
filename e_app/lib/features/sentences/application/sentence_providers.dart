import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../data/sentence_repository.dart';

final sentenceRepositoryProvider = Provider<SentenceRepository>((ref) {
  return SentenceRepository(ref.watch(graphQLClientProvider));
});

final sentenceTopicsProvider =
    FutureProvider.autoDispose<List<VocabularyTopic>>((ref) {
  return ref.watch(sentenceRepositoryProvider).fetchTopics();
});

class SentenceItemsController
    extends AutoDisposeFamilyAsyncNotifier<List<VocabularyItem>, String> {
  @override
  Future<List<VocabularyItem>> build(String topicId) {
    return ref.watch(sentenceRepositoryProvider).fetchItems(topicId);
  }

  Future<void> markMastered(String itemId, bool mastered) async {
    final repo = ref.read(sentenceRepositoryProvider);
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

final sentenceItemsProvider = AsyncNotifierProvider.autoDispose
    .family<SentenceItemsController, List<VocabularyItem>, String>(
  SentenceItemsController.new,
);

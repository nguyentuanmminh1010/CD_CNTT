import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../data/grammar_repository.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return GrammarRepository(ref.watch(graphQLClientProvider));
});

final grammarTopicsProvider =
    FutureProvider.autoDispose<List<VocabularyTopic>>((ref) {
  return ref.watch(grammarRepositoryProvider).fetchTopics();
});

class GrammarItemsController
    extends AutoDisposeFamilyAsyncNotifier<List<VocabularyItem>, String> {
  @override
  Future<List<VocabularyItem>> build(String topicId) {
    return ref.watch(grammarRepositoryProvider).fetchItems(topicId);
  }

  Future<void> markMastered(String itemId, bool mastered) async {
    final repo = ref.read(grammarRepositoryProvider);
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

final grammarItemsProvider = AsyncNotifierProvider.autoDispose
    .family<GrammarItemsController, List<VocabularyItem>, String>(
  GrammarItemsController.new,
);

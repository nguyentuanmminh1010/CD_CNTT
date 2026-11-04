import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../data/deck_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(graphQLClientProvider));
});

/// Các bộ thẻ riêng do người dùng tạo.
final myDecksProvider = FutureProvider.autoDispose<List<VocabularyTopic>>((
  ref,
) {
  return ref.watch(deckRepositoryProvider).fetchMyDecks();
});

/// Bộ thẻ bạn bè gửi riêng, đang chờ bạn nhận (hiện ở "Bộ thẻ của tôi" và thông báo).
final deckGiftsProvider = FutureProvider.autoDispose<List<DeckGift>>((ref) {
  return ref.watch(deckRepositoryProvider).fetchDeckGifts();
});

/// Admin: toàn bộ chủ đề hệ thống để quản lý nội dung.
final systemTopicsProvider = FutureProvider.autoDispose<List<VocabularyTopic>>((
  ref,
) {
  return ref.watch(deckRepositoryProvider).fetchSystemTopics();
});

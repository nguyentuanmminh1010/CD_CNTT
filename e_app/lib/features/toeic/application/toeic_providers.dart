import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/toeic_repository.dart';

final toeicRepositoryProvider = Provider<ToeicRepository>((ref) {
  return ToeicRepository(ref.watch(graphQLClientProvider));
});

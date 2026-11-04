import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attempts/application/attempt_providers.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../data/assessment_repository.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(
    vocabularyRepository: ref.watch(vocabularyRepositoryProvider),
    grammarRepository: ref.watch(grammarRepositoryProvider),
    sentenceRepository: ref.watch(sentenceRepositoryProvider),
    attemptRepository: ref.watch(attemptRepositoryProvider),
  );
});

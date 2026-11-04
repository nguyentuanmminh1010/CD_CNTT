import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../skills/domain/skill_type.dart';
import '../../progress/application/progress_providers.dart';
import '../../recommendation/recommendation.dart';
import '../../review/application/review_providers.dart';
import '../data/answer_repository.dart';

final answerRepositoryProvider = Provider<AnswerRepository>((ref) {
  return AnswerRepository(ref.watch(graphQLClientProvider));
});

/// Khoá gom các câu trả lời của MỘT lượt làm bài — backend dùng nó để tự tính điểm lượt.
/// Đủ ngẫu nhiên để không trùng giữa các lượt/người dùng.
String newAttemptKey() {
  final rnd = Random.secure();
  final suffix = List.generate(8, (_) => rnd.nextInt(36).toRadixString(36)).join();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$suffix';
}

/// Làm mới các số liệu phụ thuộc câu trả lời (chuỗi ngày, tiến độ, lỗi sai, hàng đợi ôn lặp lại).
void invalidateAfterAnswers(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(activityProvider);
  invalidate(masteryOverviewProvider);
  invalidate(wrongItemsProvider);
  invalidate(dueItemsProvider);
  invalidate(dueItemCountProvider);
  invalidate(recommendedTopicsProvider);
}

/// Một lượt làm bài: sinh [key], gửi từng câu trả lời kèm key, và [settle] chờ mọi request đã gửi
/// hoàn tất — để `finishAttempt` luôn thấy đủ câu (kể cả câu cuối vừa bấm xong).
class AttemptSession {
  AttemptSession(this._repository) : key = newAttemptKey();

  final AnswerRepository _repository;
  final String key;
  final List<Future<AnswerResult?>> _pending = [];

  Future<AnswerResult?> submit({
    required String itemId,
    required AnswerMode mode,
    required String answer,
    SkillType? skill,
  }) {
    final f = _repository.submitQuietly(
        itemId: itemId, mode: mode, answer: answer, attemptKey: key, skill: skill);
    _pending.add(f);
    return f;
  }

  Future<void> settle() async {
    await Future.wait(_pending);
  }
}

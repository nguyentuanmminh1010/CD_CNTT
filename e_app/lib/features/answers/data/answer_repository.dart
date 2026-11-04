import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../../skills/domain/skill_type.dart';

/// Cách backend chấm một câu trả lời — khớp enum `AnswerMode` ở backend.
enum AnswerMode {
  /// Chọn nghĩa đúng (đáp án = `meaning`).
  meaning,

  /// Gõ lại thuật ngữ/câu tiếng Anh (đáp án = `term`).
  term,

  /// Ghép từ thành câu (đáp án = các từ của `example`, đúng thứ tự).
  sentence,

  /// Câu đã nói (so khớp từ với `term`, đạt từ 70%).
  spoken,
}

/// Kết quả chấm của backend cho một câu trả lời.
class AnswerResult {
  const AnswerResult({
    required this.correct,
    required this.correctAnswer,
    required this.similarity,
  });

  final bool correct;
  final String correctAnswer;
  final double similarity;

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        correct: json['correct'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        similarity: (json['similarity'] as num).toDouble(),
      );
}

/// Gửi câu trả lời để BACKEND chấm (client không gửi "đúng/sai"). UI vẫn chấm tức thì
/// ở client để phản hồi ngay, nhưng mọi tiến độ/điểm số đều dựa trên kết quả chấm này.
class AnswerRepository {
  // Gửi câu trả lời, nuốt lỗi mạng (null nếu lỗi) — UI đã phản hồi tức thì ở client nên không chặn người dùng.

  AnswerRepository(this._client);

  final GraphQLClient _client;

  static const _submitMutation = r'''
    mutation SubmitAnswer($itemId: ID!, $mode: AnswerMode!, $answer: String!, $attemptKey: String, $skill: Skill) {
      submitAnswer(itemId: $itemId, mode: $mode, answer: $answer, attemptKey: $attemptKey, skill: $skill) {
        correct correctAnswer similarity
      }
    }
  ''';

  Future<AnswerResult> submit({
    required String itemId,
    required AnswerMode mode,
    required String answer,
    String? attemptKey,
    SkillType? skill,
  }) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_submitMutation),
      variables: {
        'itemId': itemId,
        'mode': mode.name.toUpperCase(),
        'answer': answer,
        'attemptKey': attemptKey,
        'skill': skill?.apiValue,
      },
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return AnswerResult.fromJson(result.data!['submitAnswer'] as Map<String, dynamic>);
  }

  Future<AnswerResult?> submitQuietly({
    required String itemId,
    required AnswerMode mode,
    required String answer,
    String? attemptKey,
    SkillType? skill,
  }) async {
    try {
      return await submit(
          itemId: itemId, mode: mode, answer: answer, attemptKey: attemptKey, skill: skill);
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../../ranking/application/ranking_providers.dart';
import '../data/attempt_repository.dart';
import '../domain/attempt.dart';

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository(ref.watch(graphQLClientProvider));
});

/// Lịch sử các lượt làm bài — dùng ở tab Đánh giá, Hồ sơ và màn "Lịch sử".
final myAttemptsProvider = FutureProvider.autoDispose<List<Attempt>>((ref) {
  return ref.watch(attemptRepositoryProvider).fetchAttempts(limit: 50);
});

/// Làm mới mọi dữ liệu phụ thuộc kết quả bài làm (lịch sử, xếp hạng, thành
/// tựu) để tab đang hiện bên dưới màn làm bài không bị cũ. Nhận hàm
/// `invalidate` (của `WidgetRef` hoặc `ProviderContainer`) để gọi được cả khi
/// widget gọi đã bị huỷ.
void invalidateAttemptData(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(myAttemptsProvider);
  invalidate(leaderboardProvider);
  invalidate(myRankProvider);
  invalidate(achievementsProvider);
}

/// Kết thúc một lượt làm bài: backend tự tính điểm từ các câu đã gửi bằng `submitAnswer` với cùng
/// [attemptKey], rồi làm mới dữ liệu liên quan. Dùng [ProviderContainer] (lấy qua
/// `ProviderScope.containerOf`) thay vì `ref` để hoàn tất đúng cả khi người dùng thoát màn trước khi
/// request xong. Trả về lượt vừa lưu (null nếu lỗi mạng — kết quả từng câu đã được lưu riêng, mất
/// lịch sử một lượt không đáng làm hỏng màn kết quả).
Future<Attempt?> saveAttempt(
  ProviderContainer container, {
  required AttemptType type,
  required String title,
  required String attemptKey,
  required int expectedTotal,
  String? refKey,
}) async {
  if (expectedTotal <= 0) return null;
  Attempt? saved;
  try {
    saved = await container.read(attemptRepositoryProvider).finishAttempt(
          attemptKey: attemptKey,
          type: type,
          title: title,
          expectedTotal: expectedTotal,
          refKey: refKey,
        );
  } catch (_) {
    // Bỏ qua — xem ghi chú ở trên.
  }
  invalidateAttemptData(container.invalidate);
  return saved;
}

/// Từng câu của một lượt — màn "xem lại đáp án".
final attemptAnswersProvider =
    FutureProvider.autoDispose.family<List<AttemptAnswerView>, String>((ref, attemptId) {
  return ref.watch(attemptRepositoryProvider).fetchAnswers(attemptId);
});

import 'package:flutter/material.dart';

import '../../attempts/domain/attempt.dart';
import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/practice_session_screen.dart';
import '../application/toeic_providers.dart';

/// Luyện thi TOEIC thích ứng: các mục (mọi mảng) người dùng CHƯA thuộc, độ khó khớp mức thành thạo
/// (`toeicPracticeItems`, đã sắp ở backend). Dạng "Điền chỗ trống" giống Part 5 của đề thi; mục không có
/// câu ví dụ thì rơi về trắc nghiệm. Kết quả lượt lưu vào lịch sử (`AttemptType.toeic`).
class ToeicPracticeScreen extends StatelessWidget {
  const ToeicPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PracticeSessionScreen(
      config: PracticeConfig(
        title: 'Luyện thi TOEIC',
        kind: PracticeKind.cloze,
        keepOrder: true,
        attemptType: AttemptType.toeic,
        allowRetry: false,
        exitLabel: 'Quay lại',
        emptyMessage: 'Bạn đã thuộc hết nội dung hiện có — tuyệt vời!',
        load: (ref) => ref.read(toeicRepositoryProvider).fetchPracticeItems(limit: 10),
      ),
    );
  }
}

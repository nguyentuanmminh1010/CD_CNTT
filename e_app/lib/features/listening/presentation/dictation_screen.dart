import 'package:flutter/material.dart';

import '../../attempts/application/attempt_providers.dart';
import '../../attempts/domain/attempt.dart';
import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/practice_session_screen.dart';
import '../../review/domain/wrong_item.dart';

/// Kỹ năng **Nghe** — "Nghe chép": app đọc câu mẫu (file audio nếu có, không thì giọng máy; có nút đọc
/// chậm), người dùng gõ lại. Backend chấm bằng `TERM` + kỹ năng LISTENING; lượt lưu `AttemptType.listening`.
class DictationScreen extends StatelessWidget {
  const DictationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PracticeSessionScreen(
      config: PracticeConfig(
        title: 'Luyện Nghe',
        kind: PracticeKind.dictation,
        attemptType: AttemptType.listening,
        allowRetry: false,
        exitLabel: 'Quay lại',
        load: (ref) => ref.read(attemptRepositoryProvider).fetchAssessmentItems(
              category: ReviewCategory.sentence,
              minDifficulty: 1,
              maxDifficulty: 3,
              limit: 8,
            ),
      ),
    );
  }
}

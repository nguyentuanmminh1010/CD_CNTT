import 'package:flutter/material.dart';

import '../../assessments/application/assessment_providers.dart';
import '../../attempts/domain/attempt.dart';
import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/practice_session_screen.dart';

/// Kỹ năng **Viết** — "Dịch câu": xem nghĩa tiếng Việt, gõ lại tiếng Anh (backend chấm bằng `TERM`, bỏ
/// qua hoa-thường/dấu câu cuối). Đề trộn 3 mảng; kết quả lượt lưu `AttemptType.writing`.
class TranslateQuizScreen extends StatelessWidget {
  const TranslateQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PracticeSessionScreen(
      config: PracticeConfig(
        title: 'Luyện Viết',
        kind: PracticeKind.translate,
        attemptType: AttemptType.writing,
        allowRetry: false,
        exitLabel: 'Quay lại',
        load: (ref) =>
            ref.read(assessmentRepositoryProvider).fetchAssessmentItems(null, questionLimit: 12),
      ),
    );
  }
}

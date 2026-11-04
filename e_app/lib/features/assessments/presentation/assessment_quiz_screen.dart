import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../attempts/domain/attempt.dart';
import '../../courses/domain/level_test_args.dart';
import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/practice_session_screen.dart';
import '../../practice/presentation/widgets/practice_result_view.dart';
import '../../review/domain/wrong_item.dart';
import '../../skills/domain/skill_type.dart';
import '../application/assessment_providers.dart';
import '../domain/assessment_test.dart';

const _categoryTitles = {
  ReviewCategory.vocabulary: 'Vocabulary',
  ReviewCategory.grammar: 'Grammar',
  ReviewCategory.sentence: 'Sentences',
};

/// Cấp độ ước tính từ % câu đúng ở bài kiểm tra xếp lớp — cùng 3 mức với `difficultyLabel`.
String _estimatedLevel(int percent) {
  if (percent >= 75) return 'Nâng cao';
  if (percent >= 40) return 'Trung bình';
  return 'Cơ bản';
}

/// Bài trắc nghiệm có kết quả lưu vào lịch sử: "Bài đánh giá" theo mảng hoặc theo một [test] ở tab Đánh
/// giá, bài kiểm tra xếp lớp (có [onExit]), Luyện Đọc ([skill]) và Level Test ([levelTest]). Chạy trên
/// engine làm bài chung; backend chấm từng câu và tự tính điểm lượt.
class AssessmentQuizScreen extends StatelessWidget {
  const AssessmentQuizScreen({
    super.key,
    required this.category,
    this.screenTitle = 'Bài đánh giá',
    this.onExit,
    this.skill,
    this.questionLimit,
    this.test,
    this.levelTest,
  });

  final ReviewCategory? category;
  final LevelTestArgs? levelTest;
  final AssessmentTest? test;
  final String screenTitle;

  /// Hành vi khi rời màn — mặc định `context.pop()`; bài kiểm tra xếp lớp truyền `go(home)`.
  final VoidCallback? onExit;
  final SkillType? skill;
  final int? questionLimit;

  AttemptType get _attemptType {
    if (skill == SkillType.reading) return AttemptType.reading;
    if (onExit != null) return AttemptType.placement;
    return AttemptType.assessment;
  }

  String get _title {
    if (levelTest != null) return 'Level Test · ${levelTest!.title}';
    if (test != null) return test!.title;
    if (skill != null || onExit != null) return screenTitle;
    final cat = category == null ? 'Tất cả' : _categoryTitles[category]!;
    return '$screenTitle · $cat';
  }

  @override
  Widget build(BuildContext context) {
    return PracticeSessionScreen(
      config: PracticeConfig(
        title: _title,
        kind: PracticeKind.meaning,
        keepOrder: true,
        skill: skill,
        attemptType: _attemptType,
        refKey: levelTest?.refKey,
        onExit: onExit,
        exitLabel: onExit != null ? 'Vào Trang chủ' : 'Quay lại',
        allowRetry: false,
        emptyMessage: 'Chưa có đủ dữ liệu để làm bài này.',
        load: (ref) {
          final repository = ref.read(assessmentRepositoryProvider);
          if (levelTest != null) return repository.fetchLevelTestItems(levelTest!);
          if (test != null) return repository.fetchTestItems(test!);
          return repository.fetchAssessmentItems(
            category,
            questionLimit: questionLimit ?? (onExit != null || skill != null ? 12 : null),
          );
        },
        resultExtras: (context, outcome, attemptId) => [
          if (onExit != null)
            ResultPill(
              text: 'Cấp độ ước tính: ${_estimatedLevel(outcome.percent)}',
              color: AppColors.accentYellow,
            ),
          if (onExit != null)
            Text(
              'Những câu đã đúng sẽ được bỏ qua ở các bài luyện tập sau, giúp bạn học đúng trình độ hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          if (levelTest != null)
            outcome.percent >= levelTestPassPercent
                ? const ResultPill(
                    text: 'Đạt! Level tiếp theo đã được mở khoá', color: AppColors.success)
                : const ResultPill(
                    text: 'Chưa đạt — cần từ $levelTestPassPercent% để qua Level',
                    color: AppColors.error),
          if (attemptId != null)
            OutlinedButton.icon(
              onPressed: () => context.push('/attempt/$attemptId'),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Xem lại đáp án'),
            ),
        ],
      ),
    );
  }
}

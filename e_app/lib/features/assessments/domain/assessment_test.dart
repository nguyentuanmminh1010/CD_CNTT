import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../review/domain/wrong_item.dart';

/// Một bài test ở tab Đánh giá — đề được rút ngẫu nhiên từ kho nội dung theo
/// category + khoảng độ khó (query `assessmentItems`), nên không có "đề cứng"
/// cần soạn riêng. [category] null = trộn cả 3 mảng.
class AssessmentTest {
  const AssessmentTest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.minDifficulty,
    required this.maxDifficulty,
    required this.questionCount,
    required this.minutes,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ReviewCategory? category;
  final int minDifficulty;
  final int maxDifficulty;
  final int questionCount;
  final int minutes;

  String get levelLabel {
    if (minDifficulty == maxDifficulty) {
      return const {1: 'Cơ bản', 2: 'Trung bình', 3: 'Nâng cao'}[minDifficulty] ?? 'Cơ bản';
    }
    if (minDifficulty == 1 && maxDifficulty == 3) return 'Mọi cấp độ';
    return 'Trung bình – Nâng cao';
  }
}

const assessmentTests = <AssessmentTest>[
  AssessmentTest(
    id: 'general',
    title: 'Đánh giá năng lực tổng hợp',
    description:
        'Bài kiểm tra trộn từ vựng, ngữ pháp và mẫu câu ở mọi cấp độ — giúp bạn nhìn tổng quan năng lực tiếng Anh hiện tại.',
    icon: Icons.grid_view_rounded,
    color: AppColors.primary,
    category: null,
    minDifficulty: 1,
    maxDifficulty: 3,
    questionCount: 18,
    minutes: 10,
  ),
  AssessmentTest(
    id: 'toeic-mini',
    title: 'TOEIC mini test',
    description:
        'Bài thi rút gọn với các câu ở mức trung bình đến nâng cao, mô phỏng áp lực của một bài thi TOEIC.',
    icon: Icons.workspace_premium_rounded,
    color: AppColors.accentYellow,
    category: null,
    minDifficulty: 2,
    maxDifficulty: 3,
    questionCount: 15,
    minutes: 8,
  ),
  AssessmentTest(
    id: 'vocab-basic',
    title: 'Từ vựng cơ bản',
    description: 'Kiểm tra nhanh vốn từ vựng nền tảng thường gặp trong đời sống hằng ngày.',
    icon: Icons.style_rounded,
    color: AppColors.primary,
    category: ReviewCategory.vocabulary,
    minDifficulty: 1,
    maxDifficulty: 1,
    questionCount: 10,
    minutes: 5,
  ),
  AssessmentTest(
    id: 'vocab-advanced',
    title: 'Từ vựng nâng cao',
    description: 'Thử thách với những từ vựng khó hơn ở mức trung bình và nâng cao.',
    icon: Icons.auto_stories_rounded,
    color: AppColors.accentBlue,
    category: ReviewCategory.vocabulary,
    minDifficulty: 2,
    maxDifficulty: 3,
    questionCount: 10,
    minutes: 5,
  ),
  AssessmentTest(
    id: 'grammar',
    title: 'Ngữ pháp trọng tâm',
    description: 'Ôn lại các điểm ngữ pháp quan trọng: thì, câu điều kiện, câu bị động, so sánh...',
    icon: Icons.rule_rounded,
    color: AppColors.accentBlue,
    category: ReviewCategory.grammar,
    minDifficulty: 1,
    maxDifficulty: 3,
    questionCount: 10,
    minutes: 6,
  ),
  AssessmentTest(
    id: 'sentences',
    title: 'Mẫu câu giao tiếp',
    description: 'Kiểm tra khả năng hiểu các mẫu câu thông dụng trong giao tiếp hằng ngày.',
    icon: Icons.short_text_rounded,
    color: AppColors.accentPurple,
    category: ReviewCategory.sentence,
    minDifficulty: 1,
    maxDifficulty: 3,
    questionCount: 10,
    minutes: 5,
  ),
];

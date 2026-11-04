import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/assessment_test.dart';

/// Màn giới thiệu một bài test ("Trước khi bạn bắt đầu" ở `Assessments.png`) —
/// mô tả, số câu/thời gian/cấp độ và vài lưu ý trước khi bấm "Làm bài tập".
class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key, required this.test});

  final AssessmentTest test;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Bài đánh giá'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: test.color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(test.icon, color: test.color, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text('Bài đánh giá',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Meta(Icons.timer_outlined, '${test.minutes} phút'),
                          const SizedBox(width: 18),
                          _Meta(Icons.quiz_outlined, '${test.questionCount} câu hỏi'),
                          const SizedBox(width: 18),
                          _Meta(Icons.signal_cellular_alt_rounded, test.levelLabel),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mô tả bài test',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(test.description,
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13.5, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trước khi bạn bắt đầu',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                            SizedBox(height: 10),
                            _Note('Mỗi câu chỉ chọn được một đáp án, không thể đổi sau khi chọn.'),
                            _Note('Kết quả được lưu vào lịch sử và tính vào chuỗi ngày học.'),
                            _Note('Những câu bạn trả lời sai sẽ xuất hiện trong mục Ôn tập lỗi sai.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.pushReplacement(AppRoutes.assessmentQuiz, extra: test),
                      child: const Text('Làm bài tập'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

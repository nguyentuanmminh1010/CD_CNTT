import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum WordChipState { pool, placed, correct, wrong }

/// Một chip từ trong dạng bài "Sắp xếp câu" — bấm để chuyển giữa khu từ còn
/// lại (pool) và khu câu trả lời (placed).
class WordChip extends StatelessWidget {
  const WordChip({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final WordChipState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // UI Kit "Learn E": chip nền xanh dương nhạt, không viền; đúng/sai tô nền xanh lá/đỏ nhạt.
    final (Color background, Color textColor) = switch (state) {
      WordChipState.pool => (AppColors.quizTile, AppColors.textPrimary),
      WordChipState.placed => (AppColors.quizTile, AppColors.textPrimary),
      WordChipState.correct => (AppColors.success.withValues(alpha: 0.16), AppColors.success),
      WordChipState.wrong => (AppColors.error.withValues(alpha: 0.13), AppColors.error),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.quizBlue.withValues(alpha: 0.1),
        splashColor: AppColors.quizBlue.withValues(alpha: 0.2),
        // Cao cố định 44 để chip nằm đúng trên các dòng kẻ của khu câu trả lời.
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          // widthFactor: 1 — chip ôm theo chữ (Container có alignment sẽ nở hết chiều ngang).
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/vocabulary_models.dart';

/// Nhãn nhỏ hiện độ khó (`LearningItem.difficultyLevel`) của một mục — dùng ở
/// header Flashcard/Trắc nghiệm để người dùng biết đang ở mức nào.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.difficultyLevel) {
      1 => AppColors.primary,
      2 => AppColors.accentYellow,
      _ => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        item.difficultyLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

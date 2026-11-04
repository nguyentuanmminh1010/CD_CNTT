import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Nút tròn điều hướng thẻ trước/sau (không cần lật/đánh giá) — theo ảnh
/// Inspiration `Flashcards.png`, đặt 2 bên thẻ Flashcard.
class FlashcardNavArrow extends StatelessWidget {
  const FlashcardNavArrow({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.background : AppColors.surface,
      shape: const CircleBorder(),
      elevation: enabled ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        splashColor: AppColors.primary.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.primaryDark : AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

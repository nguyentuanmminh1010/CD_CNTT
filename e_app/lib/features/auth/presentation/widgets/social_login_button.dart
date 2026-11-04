import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        onHover: (_) {},
        hoverColor: color.withValues(alpha: 0.12),
        splashColor: color.withValues(alpha: 0.2),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

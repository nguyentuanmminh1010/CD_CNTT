import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SurveyScaffold extends StatelessWidget {
  const SurveyScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.child,
    required this.buttonLabel,
    required this.onContinue,
  });

  final int step; // 0-based
  final int totalSteps;
  final VoidCallback? onBack;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      Expanded(
                        child: Row(
                          children: List.generate(totalSteps, (i) {
                            final active = i <= step;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: child,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      child: Text(buttonLabel),
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

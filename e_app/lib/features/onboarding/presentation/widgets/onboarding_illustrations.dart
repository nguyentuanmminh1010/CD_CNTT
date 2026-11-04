import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Minh hoạ vẽ bằng widget Flutter (không có asset vector gốc) — mô phỏng
/// bố cục của 3 slide onboarding trong ảnh thiết kế "Onboarding.jpg".
class RoadmapIllustration extends StatelessWidget {
  const RoadmapIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    Widget book(double width, Color color) => Container(
      width: width,
      height: 26,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );

    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 6,
            left: 30,
            child: Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 22),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 16),
          ),
          Positioned(
            bottom: 60,
            left: 10,
            child: Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 18),
          ),
          Positioned(
            top: 0,
            child: Icon(Icons.flag_rounded, color: AppColors.primary, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                book(150, AppColors.primary),
                book(170, AppColors.primaryLight),
                book(140, AppColors.primary.withValues(alpha: 0.85)),
                book(180, AppColors.primaryDark),
                book(150, AppColors.primaryLight),
                book(190, AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnytimeAnywhereIllustration extends StatelessWidget {
  const AnytimeAnywhereIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            top: 10,
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 30,
            child: Text(
              'C',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 40,
            child: Text(
              'B',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          Container(
            width: 130,
            height: 220,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 6, color: AppColors.surface),
                const SizedBox(height: 8),
                Container(height: 6, color: AppColors.surface),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Container(height: 6, color: AppColors.surface)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -6,
            left: 60,
            child: _person(AppColors.primary, 34),
          ),
          Positioned(
            bottom: 4,
            right: 20,
            child: _person(AppColors.accentYellow, 30),
          ),
        ],
      ),
    );
  }

  Widget _person(Color color, double size) {
    return Column(
      children: [
        CircleAvatar(radius: size / 2, backgroundColor: Colors.black87),
        const SizedBox(height: 2),
        Container(
          width: size,
          height: size * 1.1,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class DeepAssessmentIllustration extends StatelessWidget {
  const DeepAssessmentIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 20,
            child: _chip(Icons.pie_chart_rounded, AppColors.accentPurple),
          ),
          Positioned(
            right: 0,
            top: 4,
            child: _chip(Icons.bar_chart_rounded, AppColors.accentBlue),
          ),
          Positioned(
            left: 16,
            bottom: 10,
            child: _chip(Icons.chat_bubble_rounded, AppColors.primaryLight,
                iconColor: AppColors.primary),
          ),
          Container(
            width: 120,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (_) => const Icon(Icons.star_rounded,
                        color: AppColors.accentYellow, size: 16),
                  ),
                ),
                const SizedBox(height: 10),
                Container(height: 6, color: AppColors.surface),
                const SizedBox(height: 6),
                Container(height: 6, width: 60, color: AppColors.surface),
              ],
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(Icons.search_rounded, size: 64, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, Color bg, {Color iconColor = Colors.white}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

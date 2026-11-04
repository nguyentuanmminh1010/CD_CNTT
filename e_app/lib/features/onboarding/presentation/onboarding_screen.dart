import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/onboarding_illustrations.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.titlePlain,
    required this.titleAccent,
    required this.description,
    required this.illustration,
  });

  final String titlePlain;
  final String titleAccent;
  final String description;
  final Widget illustration;
}

final _pages = <_OnboardingPageData>[
  const _OnboardingPageData(
    titlePlain: 'Lộ trình',
    titleAccent: 'linh hoạt',
    description:
        'Cung cấp những nội dung học riêng cho mỗi mục tiêu khác nhau để giúp bạn đạt được thành quả tốt nhất.',
    illustration: RoadmapIllustration(),
  ),
  const _OnboardingPageData(
    titlePlain: 'Học tập',
    titleAccent: 'mọi lúc, mọi nơi',
    description:
        'Không tiện học phát âm ở nơi đông người? Không có thời gian để hoàn thành bài học dài? Chúng tôi luôn có lựa chọn khác cho bạn!',
    illustration: AnytimeAnywhereIllustration(),
  ),
  const _OnboardingPageData(
    titlePlain: 'Đánh giá',
    titleAccent: 'chuyên sâu',
    description:
        'Theo dõi và đánh giá từng kỹ năng bạn dựa trên từng loại bài tập.',
    illustration: DeepAssessmentIllustration(),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      context.go(AppRoutes.login);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(_pages.length, (i) {
                            final active = i == _index;
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
                      if (!_isLast)
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Bỏ qua'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            page.illustration,
                            const SizedBox(height: 32),
                            Text(
                              page.titlePlain,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            Text(
                              page.titleAccent,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isLast
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go(AppRoutes.login),
                                child: const Text('Đăng nhập'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.go(AppRoutes.signup),
                                child: const Text('Đăng ký'),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _next,
                            child: const Text('Tiếp tục'),
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

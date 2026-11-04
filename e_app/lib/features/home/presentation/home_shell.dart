import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../assessments/presentation/assessments_tab.dart';
import '../../attempts/application/attempt_providers.dart';
import '../../collection/presentation/collection_tab.dart';
import '../../notifications/notifications_screen.dart';
import '../../recommendation/recommendation.dart';
import '../../social/social.dart';
import '../../courses/application/course_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../review/application/review_providers.dart';
import '../../skills/application/skill_providers.dart';
import 'tabs/home_dashboard_tab.dart';
import 'tabs/profile_tab.dart';

/// Tab đang chọn ở bottom nav của Home — public để các widget con (vd banner
/// "Ôn tập lỗi sai" ở Dashboard) có thể tự chuyển sang tab khác.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  // Tiến độ (chuỗi ngày, lịch hoạt động) nằm trong phân đoạn "Tiến trình" của Hồ sơ, không còn là tab riêng.
  static const _tabs = [
    HomeDashboardTab(),
    CollectionTab(),
    AssessmentsTab(),
    ProfileTab(),
  ];

  /// Mỗi tab giữ dữ liệu đã fetch nguyên trong bộ nhớ (IndexedStack không
  /// dispose khi ẩn), nên tự invalidate provider của tab sắp mở để luôn thấy
  /// dữ liệu mới nhất (vd vừa làm sai một câu ở Vocabulary rồi bấm sang tab
  /// Thư viện phải thấy ngay số lỗi sai mới, không phải đợi bấm banner ở Home).
  void _selectTab(WidgetRef ref, int index) {
    switch (index) {
      case 0:
        ref.invalidate(activityProvider);
        ref.invalidate(masteryOverviewProvider);
        ref.invalidate(coursesProvider);
        ref.invalidate(recommendedTopicsProvider);
        ref.invalidate(dueItemCountProvider);
        ref.invalidate(dueItemsProvider);
        ref.invalidate(readNotificationKeysProvider);
        ref.invalidate(friendRequestsProvider);
        ref.invalidate(recentFriendsProvider);
        break;
      case 1:
        ref.invalidate(wrongItemsProvider);
        break;
      case 2:
        invalidateAttemptData(ref.invalidate);
        break;
      case 3:
        ref.invalidate(activityProvider);
        ref.invalidate(masteryByCategoryProvider);
        ref.invalidate(masteryOverviewProvider);
        ref.invalidate(skillMasteryProvider);
        ref.invalidate(certificatesProvider);
        invalidateAttemptData(ref.invalidate);
        break;
    }
    ref.read(homeTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primaryLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => _selectTab(ref, i),
          height: 66,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              selectedIcon: Icon(Icons.collections_bookmark_rounded),
              label: 'Thư viện',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Đánh giá',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

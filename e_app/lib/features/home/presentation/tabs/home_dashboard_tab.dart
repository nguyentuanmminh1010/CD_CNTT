import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../courses/application/course_providers.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../courses/presentation/courses_screen.dart';
import '../../../notifications/notifications_screen.dart';
import '../../../onboarding/application/survey_controller.dart';
import '../../../progress/application/progress_providers.dart';
import '../../../progress/domain/activity_models.dart';
import '../widgets/adaptive_cards.dart';
import '../widgets/content_category_card.dart';
import '../widgets/course_progress_card.dart';
import '../widgets/home_stat_chip.dart';
import '../widgets/review_banner.dart';
import '../widgets/skill_card.dart';

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(surveyControllerProvider);
    final name = answers.name.trim().isEmpty ? 'bạn' : answers.name.trim();
    final activityAsync = ref.watch(activityProvider);
    final activity = activityAsync.valueOrNull ?? ActivitySummary.empty();
    final masteryAsync = ref.watch(masteryOverviewProvider);
    final mastery = masteryAsync.valueOrNull;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  UserAvatar(
                    avatar: ref.watch(authControllerProvider).valueOrNull?.avatar,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xin chào,',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.search),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  Badge(
                    isLabelVisible: ref.watch(unreadNotificationCountProvider) > 0,
                    label: Text('${ref.watch(unreadNotificationCountProvider)}'),
                    child: IconButton(
                      tooltip: 'Thông báo',
                      onPressed: () async {
                        await context.push(AppRoutes.notifications);
                        ref.invalidate(readNotificationKeysProvider);
                      },
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  HomeStatChip(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.error,
                    value: '${activity.currentStreak} ngày',
                    label: 'Chuỗi học',
                  ),
                  const SizedBox(width: 10),
                  HomeStatChip(
                    icon: Icons.military_tech_rounded,
                    iconColor: AppColors.accentYellow,
                    value: 'Cấp ${activity.level}',
                    label: 'Trình độ',
                  ),
                  const SizedBox(width: 10),
                  HomeStatChip(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.accentBlue,
                    value: '${answers.dailyMinutes ?? 10} phút',
                    label: 'Mục tiêu/ngày',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CourseProgressCard(
                title: '500+ TOEIC',
                subtitle: 'Luyện tập thích ứng theo trình độ của bạn',
                progress: mastery?.ratio ?? 0,
                onContinue: () => context.push(AppRoutes.toeicPractice),
              ),
              const SizedBox(height: 16),
              const DueReviewBanner(),
              const RecommendationCard(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Khoá học', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.courses),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 224,
                child: ref.watch(coursesProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: TextButton(
                          onPressed: () => ref.invalidate(coursesProvider),
                          child: const Text('Không tải được khoá học. Thử lại'),
                        ),
                      ),
                      data: (courses) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => CourseCard(
                          width: 250,
                          course: courses[i],
                          onTap: () async {
                            await context.push('${AppRoutes.courses}/${courses[i].id}');
                            ref.invalidate(coursesProvider);
                          },
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hành trình', style: Theme.of(context).textTheme.titleLarge),
                  Text('${mastery?.masteredItems ?? 0}/${mastery?.totalItems ?? 0} đã thuộc',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              ContentCategoryCard(
                icon: Icons.style_rounded,
                color: AppColors.primary,
                title: 'Vocabulary',
                subtitle: 'Học & ôn tập bằng flashcard',
                onTap: () => context.push(AppRoutes.vocabulary),
              ),
              ContentCategoryCard(
                icon: Icons.rule_rounded,
                color: AppColors.accentBlue,
                title: 'Grammar',
                subtitle: 'Học & ôn tập bằng flashcard',
                onTap: () => context.push(AppRoutes.grammar),
              ),
              ContentCategoryCard(
                icon: Icons.short_text_rounded,
                color: AppColors.accentPurple,
                title: 'Sentences',
                subtitle: 'Học & ôn tập bằng flashcard',
                onTap: () => context.push(AppRoutes.sentences),
              ),
              const SizedBox(height: 24),
              Text('Luyện theo kỹ năng', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
                children: [
                  SkillCard(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    label: 'Đọc',
                    onTap: () => context.push(AppRoutes.readingPractice),
                  ),
                  SkillCard(
                    icon: Icons.edit_note_rounded,
                    color: AppColors.accentPurple,
                    label: 'Viết',
                    onTap: () => context.push(AppRoutes.writingPractice),
                  ),
                  SkillCard(
                    icon: Icons.headphones_rounded,
                    color: AppColors.accentBlue,
                    label: 'Nghe',
                    onTap: () => context.push(AppRoutes.listeningPractice),
                  ),
                  SkillCard(
                    icon: Icons.mic_rounded,
                    color: AppColors.accentYellow,
                    label: 'Nói',
                    onTap: () => context.push(AppRoutes.speakingPractice),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReviewBanner(onTap: () => context.push(AppRoutes.reviewMistakes)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../attempts/application/attempt_providers.dart';
import '../../../attempts/presentation/widgets/attempt_tile.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../courses/application/course_providers.dart';
import '../../../courses/presentation/widgets/certificate_card.dart';
import '../../../profile/presentation/widgets/mastery_pie_chart.dart';
import '../../../profile/presentation/widgets/skill_mastery_radar_chart.dart';
import '../../../profile/presentation/widgets/weekly_activity_bar_chart.dart';
import '../../../profile/presentation/widgets/skill_radar_chart.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../progress/application/progress_providers.dart';
import '../../../progress/presentation/widgets/activity_overview.dart';
import '../../../ranking/application/ranking_providers.dart';
import '../../../ranking/domain/ranking_models.dart';
import '../../../ranking/presentation/widgets/achievement_tile.dart';
import '../../../skills/application/skill_providers.dart';

/// Hồ sơ — theo `Profile.png`: đầu trang là avatar + tên + vòng "Điểm"/hạng,
/// bên dưới là 2 phân đoạn **Tiến trình** (chuỗi ngày + lịch hoạt động — thay cho tab Tiến độ cũ,
/// thống kê, biểu đồ, lịch sử bài kiểm tra) và **Thành tựu** (giấy chứng nhận + thành tựu nhiều bậc).
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  int _segment = 0;

  /// Chọn ảnh từ thư viện, thu nhỏ còn tối đa 256px (backend giới hạn ~400KB
  /// dạng base64) rồi lưu làm ảnh đại diện.
  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? (file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      await ref
          .read(authControllerProvider.notifier)
          .updateAvatar('data:$mime;base64,${base64Encode(bytes)}');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')));
      }
    } catch (e) {
      debugPrint('Đổi ảnh đại diện thất bại: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đổi được ảnh đại diện. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _share(AuthUser? user, int? score, int? rank) async {
    final streak = ref.read(activityProvider).valueOrNull?.currentStreak ?? 0;
    final text = StringBuffer('${user?.displayName ?? 'Mình'} đang học tiếng Anh cùng Learn E! ')
      ..write('Điểm: ${score ?? 0}')
      ..write(rank == null ? '' : ' · Hạng #$rank')
      ..write(' · Chuỗi học: $streak ngày. Cùng học với mình nhé!');
    try {
      await SharePlus.instance.share(ShareParams(text: text.toString(), subject: 'Learn E'));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép nội dung chia sẻ vào bộ nhớ tạm.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final myRank = ref.watch(myRankProvider(LeaderboardPeriod.all)).valueOrNull;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  user: user,
                  score: myRank?.score,
                  rank: myRank?.rank,
                  onChangeAvatar: _pickAvatar,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: const Text('Đổi ảnh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _share(user, myRank?.score, myRank?.rank),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Chia sẻ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.friends),
                    icon: const Icon(Icons.group_rounded, size: 18),
                    label: const Text('Bạn bè'),
                  ),
                ),
                if (user?.isAdmin == true) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.adminCourses),
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      label: const Text('Quản trị khoá học'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _SegmentSwitch(
                  index: _segment,
                  labels: const ['Tiến trình', 'Thành tựu'],
                  onChanged: (i) => setState(() => _segment = i),
                ),
                const SizedBox(height: 16),
                if (_segment == 0)
                  const _ProgressSection()
                else
                  _AchievementsSection(userName: user?.displayName ?? 'Người dùng'),
                const SizedBox(height: 24),
                const _ThemeSection(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất'),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.score,
    required this.rank,
    required this.onChangeAvatar,
  });

  final VoidCallback onChangeAvatar;
  final AuthUser? user;
  final int? score;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Đổi ảnh đại diện',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChangeAvatar,
                  hoverColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(avatar: user?.avatar, radius: 32),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(user?.displayName ?? 'Người dùng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
              const SizedBox(height: 2),
              Text(user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              Text('Đăng nhập bằng ${_providerLabel(user?.authProvider)}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 5),
              ),
              alignment: Alignment.center,
              child: Text('${score ?? 0}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.primaryDark)),
            ),
            const SizedBox(height: 4),
            const Text('Điểm',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            if (rank != null)
              Text('Hạng #$rank',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
          ],
        ),
      ],
    );
  }

  String _providerLabel(AuthProviderType? provider) {
    switch (provider) {
      case AuthProviderType.google:
        return 'Google';
      case AuthProviderType.facebook:
        return 'Facebook';
      case AuthProviderType.local:
      case null:
        return 'Email';
    }
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.index, required this.labels, required this.onChanged});

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              hoverColor: AppColors.primary.withValues(alpha: 0.06),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == index ? AppColors.primary : AppColors.border,
                      width: i == index ? 2.5 : 1,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: i == index ? AppColors.primary : AppColors.textSecondary,
                    )),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressSection extends ConsumerWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryByCategory = ref.watch(masteryByCategoryProvider);
    final skillMastery = ref.watch(skillMasteryProvider);
    final attempts = ref.watch(myAttemptsProvider).valueOrNull;
    final mastery = ref.watch(masteryOverviewProvider).valueOrNull;
    final activity = ref.watch(activityProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activity == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ActivityOverview(activity: activity),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.rocket_launch_rounded,
                value: '${attempts?.length ?? 0}',
                label: 'Thử thách',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.folder_open_rounded,
                value: '${mastery?.masteredItems ?? 0}',
                label: 'Bài học đã thuộc',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartCard(
          title: 'Tiến độ theo mảng',
          child: masteryByCategory.when(
            data: (categories) => SkillRadarChart(categories: categories),
            loading: _chartLoading,
            error: (e, _) => _chartError(),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Tiến độ theo kỹ năng',
          child: skillMastery.when(
            data: (skills) => SkillMasteryRadarChart(skills: skills),
            loading: _chartLoading,
            error: (e, _) => _chartError(),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Mục đã thuộc theo mảng',
          child: masteryByCategory.when(
            data: (categories) => MasteryPieChart(categories: categories),
            loading: _chartLoading,
            error: (e, _) => _chartError(),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Hoạt động 7 ngày qua',
          child: activity == null
              ? _chartLoading()
              : WeeklyActivityBarChart(days: activity.recentDays),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lịch sử bài kiểm tra', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.push(AppRoutes.attemptHistory),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (attempts == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (attempts.isEmpty)
          Text(
            'Chưa có bài kiểm tra nào — làm một bài ở tab Đánh giá để xem kết quả tại đây.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          for (final a in attempts.take(3)) ...[
            AttemptTile(attempt: a),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  static Widget _chartLoading() => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );

  static Widget _chartError() => SizedBox(
        height: 180,
        child: Center(
          child: Text('Không tải được dữ liệu tiến độ.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
}

class _AchievementsSection extends ConsumerWidget {
  const _AchievementsSection({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificates = ref.watch(certificatesProvider);
    final achievements = ref.watch(achievementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giấy chứng nhận', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        certificates.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Không tải được giấy chứng nhận.',
              style: TextStyle(color: AppColors.textSecondary)),
          data: (courses) => courses.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined,
                          size: 36, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mở khoá chứng chỉ hoàn thành',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Đăng ký và hoàn thành mọi bài học của một khoá học.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => context.push(AppRoutes.courses),
                              child: const Text('Xem các khoá học'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        CertificateCard(
                          courseTitle: courses[i].title,
                          userName: userName,
                          issuedAt: courses[i].certifiedAt,
                        ),
                  ),
                ),
        ),
        const SizedBox(height: 24),
        Text('Thành tích', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        achievements.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Không tải được thành tựu.',
              style: TextStyle(color: AppColors.textSecondary)),
          data: (list) => Column(
            children: [
              for (final a in list) ...[
                AchievementTile(achievement: a),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Chọn giao diện: theo hệ thống / sáng / tối (lưu cục bộ trên thiết bị).
class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Giao diện',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 18),
                  label: Text('Tự động')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                  label: Text('Sáng')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                  label: Text('Tối')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeControllerProvider.notifier).setMode(s.first),
          ),
        ),
      ],
    );
  }
}

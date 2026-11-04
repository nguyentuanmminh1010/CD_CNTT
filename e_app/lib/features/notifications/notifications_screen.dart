import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql/client.dart';

import '../../core/network/graphql_client.dart';
import '../../core/network/graphql_failure.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../courses/application/course_providers.dart';
import '../progress/application/progress_providers.dart';
import '../ranking/application/ranking_providers.dart';
import '../recommendation/recommendation.dart';
import '../review/application/review_providers.dart';
import '../decks/application/deck_providers.dart';
import '../social/social.dart';

/// Một thông báo trong app: nhắc học, đến hạn ôn, gợi ý, lời mời kết bạn... Nội dung được SUY RA từ dữ liệu
/// thật của người dùng mỗi lần mở; riêng trạng thái "đã đọc" được lưu ở backend theo [key] ổn định
/// (vd `due:2026-10-05`) nên đọc rồi thì không còn tính vào số chưa đọc ở chuông.
/// (Chưa có push notification hệ thống khi app đóng — cần FCM/`flutter_local_notifications`.)
class AppNotification {
  const AppNotification({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.route,
    this.read = false,
  });

  /// Khoá ổn định để ghi nhớ đã đọc; thông báo "theo ngày" có ngày trong khoá nên mai sẽ hiện lại.
  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  /// Route mở khi bấm; null = không điều hướng.
  final String? route;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    key: key,
    icon: icon,
    color: color,
    title: title,
    body: body,
    route: route,
    read: read ?? this.read,
  );
}

/// Đọc/ghi các khoá thông báo đã đọc ở backend.
class NotificationRepository {
  NotificationRepository(this._client);

  final GraphQLClient _client;

  Future<Set<String>> fetchReadKeys() async {
    final result = await _client.query(
      QueryOptions(
        document: gql('{ readNotificationKeys }'),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw GraphQLFailure.fromException(result.exception!);
    }
    return (result.data!['readNotificationKeys'] as List<dynamic>)
        .cast<String>()
        .toSet();
  }

  Future<void> markRead(Iterable<String> keys) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(
          'mutation(\$k: [String!]!) { markNotificationsRead(keys: \$k) }',
        ),
        variables: {'k': keys.toList()},
      ),
    );
    if (result.hasException) {
      throw GraphQLFailure.fromException(result.exception!);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(graphQLClientProvider));
});

final readNotificationKeysProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) {
  return ref.watch(notificationRepositoryProvider).fetchReadKeys();
});

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Danh sách thông báo hiện tại (chưa đọc lên trước) — tự cập nhật theo các provider dữ liệu nguồn.
final notificationsProvider = Provider.autoDispose<List<AppNotification>>((
  ref,
) {
  final result = <AppNotification>[];
  final today = _day(DateTime.now());

  for (final u
      in ref.watch(friendRequestsProvider).valueOrNull ??
          const <PublicUser>[]) {
    result.add(
      AppNotification(
        key: 'friend-req:${u.id}',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primary,
        title: '${u.displayName} muốn kết bạn với bạn',
        body: 'Chấp nhận để xem thứ hạng của nhau ở bảng xếp hạng "Bạn bè".',
        route: AppRoutes.friends,
      ),
    );
  }
  for (final u
      in ref.watch(recentFriendsProvider).valueOrNull ?? const <PublicUser>[]) {
    result.add(
      AppNotification(
        key: 'friend-ok:${u.id}',
        icon: Icons.group_rounded,
        color: AppColors.success,
        title: '${u.displayName} đã chấp nhận lời mời kết bạn',
        body: 'Hai bạn giờ đã là bạn bè — thử xem ai đang dẫn đầu nhé!',
        route: AppRoutes.friends,
      ),
    );
  }

  for (final g in ref.watch(deckGiftsProvider).valueOrNull ?? const []) {
    result.add(
      AppNotification(
        key: 'deck-gift:${g.id}',
        icon: Icons.card_giftcard_rounded,
        color: AppColors.accentBlue,
        title: '${g.senderName} gửi bạn bộ thẻ "${g.name}"',
        body: '${g.wordCount} thẻ — mở "Bộ thẻ của tôi" để nhận hoặc từ chối.',
        route: AppRoutes.myDecks,
      ),
    );
  }

  final due = ref.watch(dueItemCountProvider).valueOrNull ?? 0;
  if (due > 0) {
    result.add(
      AppNotification(
        key: 'due:$today',
        icon: Icons.alarm_rounded,
        color: AppColors.accentYellow,
        title: '$due mục đến hạn ôn',
        body: 'Ôn đúng lúc để nhớ lâu hơn — mục trả lời sai cần ôn ngay.',
        route: AppRoutes.reviewMistakes,
      ),
    );
  }

  final activity = ref.watch(activityProvider).valueOrNull;
  if (activity != null) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final studiedToday = activity.recentDays.any(
      (d) =>
          DateTime(d.date.year, d.date.month, d.date.day) == todayDate &&
          d.itemsCompleted > 0,
    );
    if (!studiedToday) {
      result.add(
        AppNotification(
          key: 'streak:$today',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.error,
          title: activity.currentStreak > 0
              ? 'Giữ chuỗi ${activity.currentStreak} ngày học!'
              : 'Bắt đầu chuỗi ngày học hôm nay',
          body:
              'Hôm nay bạn chưa học câu nào. Chỉ cần vài phút là giữ được chuỗi.',
          route: AppRoutes.toeicPractice,
        ),
      );
    }
  }

  final rec = ref.watch(recommendedTopicsProvider).valueOrNull?.firstOrNull;
  if (rec != null) {
    result.add(
      AppNotification(
        key: 'recommend:${rec.topic.id}:$today',
        icon: Icons.lightbulb_rounded,
        color: AppColors.accentBlue,
        title: 'Gợi ý: ${rec.topic.name}',
        body:
            '${rec.categoryLabel} · bạn mới thành thạo ${(rec.score * 100).round()}% — nên luyện mức ${rec.difficultyLabel}.',
      ),
    );
  }

  final courses = ref.watch(coursesProvider).valueOrNull ?? const [];
  for (final c in courses) {
    if (c.enrolled && !c.completed) {
      result.add(
        AppNotification(
          key: 'course:${c.id}:${c.completedUnits}',
          icon: Icons.school_rounded,
          color: AppColors.primary,
          title: 'Tiếp tục khoá "${c.title}"',
          body:
              'Bạn đã hoàn thành ${(c.progress * 100).round()}% — còn ${c.unitCount - c.completedUnits} bài nữa.',
          route: '${AppRoutes.courses}/${c.id}',
        ),
      );
    }
  }

  final achievements = ref.watch(achievementsProvider).valueOrNull ?? const [];
  for (final a in achievements) {
    if (!a.maxed && a.progress >= 0.8) {
      result.add(
        AppNotification(
          key: 'ach:${a.code}:${a.tier}',
          icon: Icons.emoji_events_rounded,
          color: AppColors.accentPurple,
          title: 'Sắp đạt bậc mới: ${a.title}',
          body:
              'Chỉ còn ${a.nextTarget - a.current} nữa là lên bậc ${a.tier + 1}.',
        ),
      );
    }
  }

  final readKeys =
      ref.watch(readNotificationKeysProvider).valueOrNull ?? const <String>{};
  final marked = [
    for (final n in result) n.copyWith(read: readKeys.contains(n.key)),
  ];
  // Chưa đọc lên trước, giữ nguyên thứ tự gốc trong từng nhóm.
  return [...marked.where((n) => !n.read), ...marked.where((n) => n.read)];
});

/// Số thông báo chưa đọc — hiện trên chuông ở Home.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(WidgetRef ref, Iterable<String> keys) async {
    if (keys.isEmpty) return;
    try {
      await ref.read(notificationRepositoryProvider).markRead(keys);
      ref.invalidate(readNotificationKeysProvider);
    } catch (e) {
      debugPrint('Đánh dấu đã đọc thất bại: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final unread = items.where((n) => !n.read).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Thông báo'),
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              onPressed: () => _markRead(ref, unread.map((n) => n.key)),
              child: const Text('Đánh dấu đã đọc'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Không có thông báo mới',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Bạn đã cập nhật hết. Hãy tiếp tục học nhé!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return Opacity(
                        opacity: n.read ? 0.6 : 1,
                        child: Material(
                          color: n.color.withValues(
                            alpha: n.read ? 0.05 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            hoverColor: n.color.withValues(alpha: 0.10),
                            onTap: () {
                              _markRead(ref, [n.key]);
                              if (n.route != null) context.push(n.route!);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: n.color.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      n.icon,
                                      color: n.color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          n.body,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.5,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      margin: const EdgeInsets.only(
                                        top: 6,
                                        left: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: n.color,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  else if (n.route != null)
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

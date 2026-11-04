import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../../social/social.dart';
import '../../application/ranking_providers.dart';
import '../../domain/ranking_models.dart';

/// Bảng xếp hạng theo số mục kho chung đã thuộc, 3 phạm vi: **Tất cả**, **Tuần này** (mục chuyển sang
/// "đã thuộc" trong 7 ngày qua) và **Bạn bè** (bạn đã chấp nhận kết bạn + chính mình). Thẻ "Hạng của bạn"
/// cố định phía trên (kể cả khi chưa lọt top) + danh sách top, có ảnh đại diện từng người.
class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  LeaderboardPeriod _period = LeaderboardPeriod.all;

  Future<void> _findFriends() async {
    await context.push(AppRoutes.friends);
    // Danh sách bạn bè có thể đã đổi → làm mới bảng xếp hạng Bạn bè.
    ref.invalidate(leaderboardProvider(LeaderboardPeriod.friends));
    ref.invalidate(myRankProvider(LeaderboardPeriod.friends));
    ref.invalidate(friendsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(leaderboardProvider(_period));
    final myRank = ref.watch(myRankProvider(_period)).valueOrNull;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              for (final p in LeaderboardPeriod.values) ...[
                _PeriodChip(
                  label: p.label,
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'Bạn bè',
                onPressed: _findFriends,
                icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: boardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: OutlinedButton(
                onPressed: () {
                  ref.invalidate(leaderboardProvider);
                  ref.invalidate(myRankProvider);
                },
                child: const Text('Không tải được bảng xếp hạng. Thử lại'),
              ),
            ),
            data: (entries) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myRankProvider);
                ref.invalidate(leaderboardProvider);
                await ref.read(leaderboardProvider(_period).future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (myRank != null) _MyRankCard(entry: myRank, period: _period),
                  const SizedBox(height: 16),
                  Text(
                    switch (_period) {
                      LeaderboardPeriod.all => 'Top người học',
                      LeaderboardPeriod.week => 'Top tuần này',
                      LeaderboardPeriod.friends => 'Bạn bè của bạn',
                    },
                    style: TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    switch (_period) {
                      LeaderboardPeriod.all => 'Xếp theo số mục nội dung đã thuộc.',
                      LeaderboardPeriod.week => 'Số mục chuyển sang "đã thuộc" trong 7 ngày qua.',
                      LeaderboardPeriod.friends =>
                        'Chỉ gồm bạn bè đã chấp nhận kết bạn và chính bạn — bấm biểu tượng bạn bè để gửi lời mời.',
                    },
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  if (entries.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('Chưa có ai trên bảng xếp hạng.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  for (final e in entries) ...[
                    _RankRow(entry: e),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry, required this.period});
  final LeaderboardEntry entry;
  final LeaderboardPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('#${entry.rank}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (period) {
                    LeaderboardPeriod.all => 'Hạng của bạn',
                    LeaderboardPeriod.week => 'Hạng của bạn tuần này',
                    LeaderboardPeriod.friends => 'Hạng của bạn trong bạn bè',
                  },
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                Text(entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.score}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
              const Text('điểm', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});
  final LeaderboardEntry entry;

  Color? get _medal => switch (entry.rank) {
        1 => AppColors.accentYellow,
        2 => const Color(0xFF9CA3AF),
        3 => const Color(0xFFB45309),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final medal = _medal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.me ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: entry.me ? Border.all(color: AppColors.primary) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: medal != null
                ? Icon(Icons.emoji_events_rounded, color: medal, size: 24)
                : Text('${entry.rank}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 6),
          UserAvatar(avatar: entry.avatar, radius: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.me ? '${entry.displayName} (Bạn)' : entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Text('${entry.score} điểm',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 13)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/attempt_providers.dart';
import 'widgets/attempt_tile.dart';

/// Toàn bộ lịch sử bài kiểm tra của người dùng (mới nhất trước).
class AttemptHistoryScreen extends ConsumerWidget {
  const AttemptHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(myAttemptsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Lịch sử bài kiểm tra'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: attemptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(myAttemptsProvider),
                  child: const Text('Không tải được lịch sử. Thử lại'),
                ),
              ),
              data: (attempts) => attempts.isEmpty
                  ? const AttemptEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async => ref.refresh(myAttemptsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: attempts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => AttemptTile(attempt: attempts[i]),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttemptEmptyState extends StatelessWidget {
  const AttemptEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('Chưa có bài kiểm tra nào',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 6),
            Text(
              'Hoàn thành một bài đánh giá hoặc luyện tập để kết quả hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

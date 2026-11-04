import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';
import '../application/deck_providers.dart';

/// Admin: quản lý nội dung chủ đề HỆ THỐNG (mọi mảng) — bấm một chủ đề để thêm/sửa/xoá thẻ.
/// (Chủ đề hệ thống không xoá được vì khoá học đang trỏ tới.)
class AdminTopicsScreen extends ConsumerWidget {
  const AdminTopicsScreen({super.key});

  static const _labels = {
    'VOCABULARY': 'Từ vựng',
    'GRAMMAR': 'Ngữ pháp',
    'SENTENCE': 'Mẫu câu',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(systemTopicsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Quản lý nội dung'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: topicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(systemTopicsProvider),
                  child: const Text('Không tải được chủ đề. Thử lại'),
                ),
              ),
              data: (topics) {
                final byCategory = <String, List<VocabularyTopic>>{};
                for (final t in topics) {
                  byCategory.putIfAbsent(t.category, () => []).add(t);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    for (final entry in byCategory.entries) ...[
                      Text(
                        _labels[entry.key] ?? entry.key,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final t in entry.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              hoverColor: AppColors.primary.withValues(
                                alpha: 0.06,
                              ),
                              onTap: () async {
                                await context.push(AppRoutes.deck, extra: t);
                                ref.invalidate(systemTopicsProvider);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      topicIconFor(t.icon),
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t.name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${t.wordCount}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

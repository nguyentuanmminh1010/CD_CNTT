import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/vocabulary_models.dart';
import 'widgets/study_mode_sheet.dart';
import 'widgets/topic_icon.dart';

/// Danh sách chủ đề dùng chung cho Vocabulary/Grammar/Sentence — 3 mảng có
/// cùng hình dạng dữ liệu (`LearningTopic` ở backend), chỉ khác provider,
/// route gốc và nhãn đơn vị hiển thị. Xem CLAUDE.md > Kiến trúc Frontend.
///
/// Có ô tìm kiếm theo tên chủ đề và bộ lọc "Của tôi" (bộ thẻ do chính người dùng tạo).
class TopicListScreen extends ConsumerStatefulWidget {
  const TopicListScreen({
    super.key,
    required this.title,
    required this.topicsProvider,
    required this.basePath,
    required this.itemUnitLabel,
  });

  final String title;
  final AutoDisposeFutureProvider<List<VocabularyTopic>> topicsProvider;
  final String basePath;
  final String itemUnitLabel;

  @override
  ConsumerState<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends ConsumerState<TopicListScreen> {
  String _query = '';
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(widget.topicsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      Expanded(
                        child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (widget.basePath == AppRoutes.vocabulary)
                        TextButton.icon(
                          onPressed: () async {
                            await context.push(AppRoutes.myDecks);
                            ref.invalidate(widget.topicsProvider);
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Bộ thẻ của tôi'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Tìm chủ đề...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                if (topicsAsync.valueOrNull?.any((t) => t.mine) ?? false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: !_onlyMine,
                          onSelected: (_) => setState(() => _onlyMine = false),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Của tôi'),
                          selected: _onlyMine,
                          onSelected: (_) => setState(() => _onlyMine = true),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: switch (topicsAsync) {
                    AsyncData(:final value) => _buildList(context, value),
                    AsyncError() => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  size: 40, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'Không kết nối được tới máy chủ.\nKiểm tra backend đang chạy chưa.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => ref.invalidate(widget.topicsProvider),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<VocabularyTopic> all) {
    final q = _query.trim().toLowerCase();
    final topics = [
      for (final t in all)
        if ((!_onlyMine || t.mine) &&
            (q.isEmpty ||
                t.name.toLowerCase().contains(q) ||
                (t.description ?? '').toLowerCase().contains(q)))
          t,
    ];
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(widget.topicsProvider),
      child: topics.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('Không có chủ đề nào phù hợp.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: topics.length,
              itemBuilder: (context, i) => _TopicTile(
                topic: topics[i],
                itemUnitLabel: widget.itemUnitLabel,
                onTap: () => _open(context, topics[i]),
              ),
            ),
    );
  }

  Future<void> _open(BuildContext context, VocabularyTopic topic) async {
    final mode = await showStudyModeSheet(context, topic.name);
    if (mode == null || !context.mounted) return;
    final path = studyModePath(widget.basePath, topic.id, mode);
    context.push(path, extra: topic.name);
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.itemUnitLabel, required this.onTap});

  final VocabularyTopic topic;
  final String itemUnitLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          hoverColor: AppColors.primary.withValues(alpha: 0.06),
          splashColor: AppColors.primary.withValues(alpha: 0.16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(topicIconFor(topic.icon), color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(topic.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                )),
                          ),
                          if (topic.mine) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text('Của bạn',
                                  style: TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${topic.wordCount} $itemUnitLabel',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

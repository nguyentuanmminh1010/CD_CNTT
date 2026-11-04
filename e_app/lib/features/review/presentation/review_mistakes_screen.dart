import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/review_providers.dart';
import '../domain/wrong_item.dart';

const _categoryVietnameseLabels = {
  ReviewCategory.vocabulary: 'Từ vựng',
  ReviewCategory.grammar: 'Ngữ pháp',
  ReviewCategory.sentence: 'Mẫu câu',
};

/// Màn "Ôn tập lỗi sai" — theo ảnh Inspiration `Review mistakes.png`: tìm
/// kiếm + lọc theo mảng nội dung + danh sách các mục sai, và nút cố định
/// "Làm quiz ngẫu nhiên" xáo toàn bộ danh sách (đang lọc) thành 1 lượt ôn tập.
/// Không còn là tab riêng — mở từ banner ở Home hoặc thẻ ở tab Thư viện.
class ReviewMistakesScreen extends ConsumerStatefulWidget {
  const ReviewMistakesScreen({super.key});

  @override
  ConsumerState<ReviewMistakesScreen> createState() => _ReviewMistakesScreenState();
}

class _ReviewMistakesScreenState extends ConsumerState<ReviewMistakesScreen> {
  ReviewCategory? _filter;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wrongItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: switch (itemsAsync) {
              AsyncData(:final value) => _buildBody(context, value),
              AsyncError() => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('Không tải được danh sách Ôn tập.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(wrongItemsProvider),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<WrongItem> allItems) {
    final counts = <ReviewCategory, int>{};
    for (final item in allItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final availableCategories =
        ReviewCategory.values.where((c) => counts.containsKey(c)).toList();
    if (_filter != null && !availableCategories.contains(_filter)) {
      _filter = null;
    }

    var filtered = _filter == null ? allItems : allItems.where((w) => w.category == _filter);
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      filtered = filtered.where((w) =>
          w.item.term.toLowerCase().contains(q) || w.item.meaning.toLowerCase().contains(q));
    }
    final results = filtered.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Text('Ôn tập lỗi sai', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Tất cả (${allItems.length})',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final category in availableCategories)
                _FilterChip(
                  label: '${_categoryVietnameseLabels[category]} (${counts[category]})',
                  selected: _filter == category,
                  onTap: () => setState(() => _filter = category),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.celebration_rounded,
                            size: 40, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(
                          allItems.isEmpty
                              ? 'Không có gì cần ôn tập!'
                              : 'Không tìm thấy kết quả phù hợp.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  itemCount: results.length,
                  itemBuilder: (context, i) => _MistakeCard(wrongItem: results[i]),
                ),
              if (results.length >= 2)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final shuffled = [...results]..shuffle();
                      context.push(AppRoutes.reviewQuiz, extra: shuffled);
                    },
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Làm quiz ngẫu nhiên'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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
        hoverColor: (selected ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.wrongItem});

  final WrongItem wrongItem;

  @override
  Widget build(BuildContext context) {
    final item = wrongItem.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryVietnameseLabels[wrongItem.category]!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.term,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bài học liên quan: ${wrongItem.topicName}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

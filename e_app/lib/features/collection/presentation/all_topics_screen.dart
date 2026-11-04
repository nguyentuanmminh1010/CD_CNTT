import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../grammar/application/grammar_providers.dart';
import '../../sentences/application/sentence_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import 'widgets/topic_card.dart';

enum _CategoryFilter { vocabulary, grammar, sentence }

/// Màn "Xem tất cả" mở từ mục Flashcards ở tab Thư viện — danh sách đầy đủ
/// mọi chủ đề của cả 3 mảng (không chỉ Vocabulary như trước), có chip lọc
/// theo mảng, tái dùng `TopicCard`/`showStudyModeSheet` đã có.
class AllTopicsScreen extends ConsumerStatefulWidget {
  const AllTopicsScreen({super.key});

  @override
  ConsumerState<AllTopicsScreen> createState() => _AllTopicsScreenState();
}

class _AllTopicsScreenState extends ConsumerState<AllTopicsScreen> {
  _CategoryFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final vocabTopics = ref.watch(vocabularyTopicsProvider).valueOrNull ?? [];
    final grammarTopics = ref.watch(grammarTopicsProvider).valueOrNull ?? [];
    final sentenceTopics = ref.watch(sentenceTopicsProvider).valueOrNull ?? [];

    final allEntries = [
      for (final t in vocabTopics)
        (filter: _CategoryFilter.vocabulary, entry: CategoryEntry('Vocabulary', AppRoutes.vocabulary, t)),
      for (final t in grammarTopics)
        (filter: _CategoryFilter.grammar, entry: CategoryEntry('Grammar', AppRoutes.grammar, t)),
      for (final t in sentenceTopics)
        (filter: _CategoryFilter.sentence, entry: CategoryEntry('Sentences', AppRoutes.sentences, t)),
    ];
    final entries = _filter == null
        ? allEntries
        : allEntries.where((e) => e.filter == _filter).toList();

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
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      Text('Tất cả chủ đề', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Tất cả (${allEntries.length})',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      _FilterChip(
                        label: 'Từ vựng (${vocabTopics.length})',
                        selected: _filter == _CategoryFilter.vocabulary,
                        onTap: () => setState(() => _filter = _CategoryFilter.vocabulary),
                      ),
                      _FilterChip(
                        label: 'Ngữ pháp (${grammarTopics.length})',
                        selected: _filter == _CategoryFilter.grammar,
                        onTap: () => setState(() => _filter = _CategoryFilter.grammar),
                      ),
                      _FilterChip(
                        label: 'Mẫu câu (${sentenceTopics.length})',
                        selected: _filter == _CategoryFilter.sentence,
                        onTap: () => setState(() => _filter = _CategoryFilter.sentence),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: entries.length,
                          itemBuilder: (context, i) => TopicCard(entry: entries[i].entry, width: null),
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

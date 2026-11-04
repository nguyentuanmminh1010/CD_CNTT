import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
import '../../vocabulary/presentation/widgets/topic_icon.dart';
import '../application/deck_providers.dart';
import '../data/deck_repository.dart';

/// "Bộ thẻ của tôi": người dùng tự tạo thư mục/chủ đề flashcard riêng, thêm/sửa/xoá thẻ trong đó
/// rồi học bằng chính các dạng bài sẵn có (Flashcard, Trắc nghiệm, Sắp xếp câu).
/// Bộ thẻ riêng không tính vào xếp hạng/đề thi chung.
class MyDecksScreen extends ConsumerWidget {
  const MyDecksScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo bộ thẻ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tên bộ thẻ (vd: Từ vựng IELTS)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(
                hintText: 'Mô tả (không bắt buộc)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final deck = await ref
          .read(deckRepositoryProvider)
          .createDeck(name.text.trim(), description.text.trim());
      ref.invalidate(myDecksProvider);
      ref.invalidate(vocabularyTopicsProvider);
      if (context.mounted) context.push(AppRoutes.deck, extra: deck);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tạo được bộ thẻ. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }

  /// Nhập mã chia sẻ của bạn bè → xem trước bộ thẻ → sao chép về thành bộ thẻ riêng của mình.
  Future<void> _importByCode(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập bằng mã chia sẻ'),
        content: TextField(
          controller: code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Mã 8 ký tự (vd: K7QM2XPD)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, code.text.trim()),
            child: const Text('Xem trước'),
          ),
        ],
      ),
    );
    if (entered == null || entered.isEmpty || !context.mounted) return;
    final repo = ref.read(deckRepositoryProvider);
    try {
      final preview = await repo.fetchSharedDeck(entered);
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(preview.name),
          content: Text(
            '${preview.wordCount} thẻ · do ${preview.ownerName} chia sẻ.\n'
            'Bộ thẻ sẽ được sao chép về thành bộ thẻ riêng của bạn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sao chép'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final deck = await repo.importSharedDeck(entered);
      ref.invalidate(myDecksProvider);
      ref.invalidate(vocabularyTopicsProvider);
      if (context.mounted) context.push(AppRoutes.deck, extra: deck);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    DeckGift gift,
    bool accept,
  ) async {
    try {
      final deck = await ref
          .read(deckRepositoryProvider)
          .respondDeckGift(gift.id, accept: accept);
      ref.invalidate(deckGiftsProvider);
      ref.invalidate(myDecksProvider);
      ref.invalidate(vocabularyTopicsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? 'Đã nhận bộ thẻ "${gift.name}".' : 'Đã từ chối bộ thẻ.',
          ),
        ),
      );
      if (accept && deck != null) context.push(AppRoutes.deck, extra: deck);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bộ thẻ?'),
        content: Text(
          'Bộ "$name" cùng toàn bộ thẻ và tiến độ học sẽ bị xoá. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(deckRepositoryProvider).deleteTopic(id);
      ref.invalidate(myDecksProvider);
      ref.invalidate(vocabularyTopicsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không xoá được bộ thẻ.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(myDecksProvider);
    final gifts =
        ref.watch(deckGiftsProvider).valueOrNull ?? const <DeckGift>[];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Bộ thẻ của tôi'),
        actions: [
          IconButton(
            tooltip: 'Nhập bằng mã chia sẻ',
            onPressed: () => _importByCode(context, ref),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo bộ thẻ'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                for (final g in gifts)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.10),
                      border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${g.senderName} gửi bạn bộ thẻ "${g.name}"',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${g.wordCount} thẻ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: () =>
                                    _respond(context, ref, g, false),
                                child: const Text('Từ chối'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: () =>
                                    _respond(context, ref, g, true),
                                child: const Text('Nhận'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: decksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: OutlinedButton(
                        onPressed: () => ref.invalidate(myDecksProvider),
                        child: const Text('Không tải được bộ thẻ. Thử lại'),
                      ),
                    ),
                    data: (decks) => decks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.style_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Chưa có bộ thẻ nào',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tự tạo bộ thẻ của riêng bạn, thêm từ vựng rồi học bằng Flashcard, Trắc nghiệm và Sắp xếp câu.',
                                    textAlign: TextAlign.center,
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
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                            itemCount: decks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final d = decks[i];
                              return Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  hoverColor: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  onTap: () async {
                                    await context.push(
                                      AppRoutes.deck,
                                      extra: d,
                                    );
                                    ref.invalidate(myDecksProvider);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            topicIconFor(d.icon),
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                d.name,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '${d.wordCount} thẻ',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Xoá bộ thẻ',
                                          onPressed: () => _delete(
                                            context,
                                            ref,
                                            d.id,
                                            d.name,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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

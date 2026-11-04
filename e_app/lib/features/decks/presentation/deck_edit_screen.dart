import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pick_image.dart';
import '../../courses/presentation/lesson_detail_screen.dart'
    show lessonItemsProvider;
import '../../vocabulary/application/vocabulary_providers.dart';
import '../../vocabulary/domain/vocabulary_models.dart';
import '../../vocabulary/presentation/widgets/difficulty_badge.dart';
import '../../vocabulary/presentation/widgets/item_image.dart';
import '../../vocabulary/presentation/widgets/speak_button.dart';
import '../../vocabulary/presentation/widgets/study_mode_sheet.dart';
import '../../social/social.dart';
import '../application/deck_csv.dart';
import '../application/deck_providers.dart';

/// Sửa nội dung một chủ đề: thêm/sửa/xoá thẻ, đổi tên/mô tả. Dùng cho bộ thẻ riêng của người dùng
/// và (với admin) cho chủ đề hệ thống — [VocabularyTopic.editable] quyết định có hiện nút sửa không.
class DeckEditScreen extends ConsumerStatefulWidget {
  const DeckEditScreen({super.key, required this.topic});

  final VocabularyTopic topic;

  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen> {
  late String _name = widget.topic.name;
  late String? _description = widget.topic.description;
  late String? _guide = widget.topic.guide;
  late String? _shareCode = widget.topic.shareCode;

  ({String category, String topicId}) get _key =>
      (category: widget.topic.category, topicId: widget.topic.id);

  String get _basePath => switch (widget.topic.category) {
    'GRAMMAR' => AppRoutes.grammar,
    'SENTENCE' => AppRoutes.sentences,
    _ => AppRoutes.vocabulary,
  };

  void _refresh() {
    ref.invalidate(lessonItemsProvider(_key));
    ref.invalidate(myDecksProvider);
    ref.invalidate(vocabularyTopicsProvider);
  }

  void _error(Object e) {
    if (!mounted) return;
    final msg = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _rename() async {
    final name = TextEditingController(text: _name);
    final description = TextEditingController(text: _description ?? '');
    final guide = TextEditingController(text: _guide ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa thông tin bộ thẻ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(hintText: 'Tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                decoration: const InputDecoration(hintText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: guide,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'Hướng dẫn học (tab "Hướng dẫn" của bài) — mỗi dòng là một bước',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final updated = await ref
          .read(deckRepositoryProvider)
          .updateTopic(
            widget.topic.id,
            name: name.text.trim(),
            description: description.text.trim(),
            guide: guide.text.trim(),
          );
      setState(() {
        _name = updated.name;
        _description = updated.description;
        _guide = updated.guide;
      });
      _refresh();
    } catch (e) {
      _error(e);
    }
  }

  /// Hộp thoại thêm/sửa một thẻ; [item] null = thêm mới.
  Future<void> _editItem([VocabularyItem? item]) async {
    final term = TextEditingController(text: item?.term ?? '');
    final phonetic = TextEditingController(text: item?.phonetic ?? '');
    final meaning = TextEditingController(text: item?.meaning ?? '');
    final example = TextEditingController(text: item?.example ?? '');
    final explanation = TextEditingController(text: item?.explanation ?? '');
    final audioUrl = TextEditingController(text: item?.audioUrl ?? '');
    String? image = item?.imageUrl;
    var level = item?.difficultyLevel ?? 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item == null ? 'Thêm thẻ' : 'Sửa thẻ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: term,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Từ / cụm từ (tiếng Anh) *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phonetic,
                  decoration: const InputDecoration(
                    hintText: 'Phiên âm (không bắt buộc)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: meaning,
                  decoration: const InputDecoration(
                    hintText: 'Nghĩa tiếng Việt *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: example,
                  decoration: const InputDecoration(
                    hintText: 'Câu ví dụ (dùng cho bài Sắp xếp câu)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: explanation,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Giải thích (hiện ở màn xem lại đáp án, không bắt buộc)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: audioUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText:
                        'Link file audio https://... (trống = đọc bằng giọng máy)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (image != null) ...[
                      ItemImage(url: image!, height: 56, radius: 10),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            onPressed: () async {
                              try {
                                final picked = await pickImageDataUrl();
                                if (picked != null) {
                                  setLocal(() => image = picked);
                                }
                              } catch (e) {
                                _error(e);
                              }
                            },
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(image == null ? 'Thêm ảnh' : 'Đổi ảnh'),
                          ),
                          if (image != null)
                            TextButton(
                              onPressed: () => setLocal(() => image = null),
                              child: const Text('Bỏ ảnh'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Độ khó',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const {
                      1: 'Cơ bản',
                      2: 'Trung bình',
                      3: 'Nâng cao',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: level == entry.key,
                        onSelected: (_) => setLocal(() => level = entry.key),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (term.text.trim().isEmpty || meaning.text.trim().isEmpty) {
      _error('Cần nhập đủ từ và nghĩa.');
      return;
    }
    try {
      final repo = ref.read(deckRepositoryProvider);
      if (item == null) {
        await repo.addItem(
          widget.topic.id,
          term: term.text,
          phonetic: phonetic.text,
          meaning: meaning.text,
          example: example.text,
          difficulty: level,
          explanation: explanation.text,
          imageUrl: image,
          audioUrl: audioUrl.text,
        );
      } else {
        await repo.updateItem(
          item.id,
          term: term.text,
          phonetic: phonetic.text,
          meaning: meaning.text,
          example: example.text,
          difficulty: level,
          explanation: explanation.text,
          imageUrl: image,
          audioUrl: audioUrl.text,
        );
      }
      _refresh();
    } catch (e) {
      _error(e);
    }
  }

  /// Dán nhiều dòng "từ | nghĩa | ví dụ | phiên âm" để thêm hàng loạt thẻ.
  Future<void> _bulkImport() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập hàng loạt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mỗi dòng một thẻ: từ | nghĩa | ví dụ | phiên âm (ví dụ, phiên âm có thể bỏ trống). '
                'Phân tách bằng Tab (dán từ Excel/Google Sheets), dấu ; hoặc |. '
                'Hoặc chọn file CSV (Excel: Lưu dưới dạng → CSV UTF-8) — file do chức năng "Xuất" tạo ra nhập lại được.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () async {
                  try {
                    final picked = await FilePicker.pickFile(
                      type: FileType.custom,
                      allowedExtensions: const ['csv', 'txt', 'tsv'],
                    );
                    if (picked == null) return;
                    if ((await picked.length() ?? 0) > 1024 * 1024) {
                      _error('File quá lớn (tối đa 1MB).');
                      return;
                    }
                    text.text = decodeImportedFile(await picked.readAsBytes());
                  } catch (e) {
                    _error(e);
                  }
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Chọn file CSV / TXT'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: text,
                autofocus: true,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText:
                      'apple | quả táo | I eat an apple\nbanana | quả chuối',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nhập'),
          ),
        ],
      ),
    );
    if (ok != true || text.text.trim().isEmpty) return;
    try {
      final result = await ref
          .read(deckRepositoryProvider)
          .importItems(widget.topic.id, text.text);
      _refresh();
      if (!mounted) return;
      final extra = [
        if (result.skipped > 0) '${result.skipped} thẻ trùng bị bỏ qua',
        if (result.errors.isNotEmpty) '${result.errors.length} dòng lỗi',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${result.added} thẻ${extra.isEmpty ? '.' : ' (${extra.join(', ')}).'}',
          ),
        ),
      );
      if (result.errors.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Một số dòng không nhập được'),
            content: Text(result.errors.take(8).join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _share() async {
    try {
      final code = await ref
          .read(deckRepositoryProvider)
          .shareDeck(widget.topic.id);
      if (!mounted) return;
      setState(() => _shareCode = code);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chia sẻ bộ thẻ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gửi mã này cho bạn bè. Họ vào "Bộ thẻ của tôi" → "Nhập bằng mã" để sao chép bộ thẻ về.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ref
                    .read(deckRepositoryProvider)
                    .unshareDeck(widget.topic.id);
                if (mounted) setState(() => _shareCode = null);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Ngừng chia sẻ',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã.')),
                  );
                }
              },
              child: const Text('Sao chép'),
            ),
            ElevatedButton(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'Mình chia sẻ bộ thẻ "$_name" trên Learn E. Nhập mã $code ở "Bộ thẻ của tôi" để học cùng nhé!',
                ),
              ),
              child: const Text('Gửi'),
            ),
          ],
        ),
      );
    } catch (e) {
      _error(e);
    }
  }

  /// Xuất toàn bộ thẻ thành CSV: xem/sao chép ngay, hoặc gửi thành file qua hộp thoại chia sẻ của thiết bị.
  Future<void> _export() async {
    final items =
        ref.read(lessonItemsProvider(_key)).valueOrNull ??
        const <VocabularyItem>[];
    if (items.isEmpty) {
      _error('Bộ thẻ chưa có thẻ nào để xuất.');
      return;
    }
    final csv = buildDeckCsv(items);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xuất ${items.length} thẻ (CSV)'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép CSV.')),
                );
              }
            },
            child: const Text('Sao chép'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
                final result = await SharePlus.instance.share(
                  ShareParams(
                    files: [
                      XFile.fromData(
                        data,
                        mimeType: 'text/csv',
                        name: '$_name.csv',
                      ),
                    ],
                    fileNameOverrides: ['$_name.csv'],
                    subject: _name,
                  ),
                );
                if (result.status == ShareResultStatus.unavailable &&
                    ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Thiết bị không hỗ trợ gửi file — hãy dùng "Sao chép".',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Không gửi được file — hãy dùng "Sao chép".',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Gửi file'),
          ),
        ],
      ),
    );
  }

  /// Gửi bộ thẻ riêng cho một người bạn — họ nhận được thông báo và chọn nhận hoặc từ chối.
  Future<void> _sendToFriend() async {
    List<PublicUser> friends;
    try {
      friends = await ref.read(friendsProvider.future);
    } catch (e) {
      _error(e);
      return;
    }
    if (!mounted) return;
    if (friends.isEmpty) {
      _error('Bạn chưa có bạn bè nào — hãy kết bạn ở màn "Bạn bè" trước.');
      return;
    }
    final friend = await showModalBottomSheet<PublicUser>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Gửi "$_name" cho...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            for (final f in friends)
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(f.displayName),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (friend == null) return;
    try {
      await ref
          .read(deckRepositoryProvider)
          .sendDeckToFriend(widget.topic.id, friend.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi bộ thẻ cho ${friend.displayName}.')),
      );
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _deleteItem(VocabularyItem item) async {
    try {
      await ref.read(deckRepositoryProvider).deleteItem(item.id);
      _refresh();
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _study(int count) async {
    final mode = await showStudyModeSheet(context, _name);
    if (mode == null || !mounted) return;
    final path = studyModePath(_basePath, widget.topic.id, mode);
    context.push(path, extra: _name);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(lessonItemsProvider(_key));
    final editable = widget.topic.editable;
    final count = itemsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_name, overflow: TextOverflow.ellipsis),
        actions: [
          if (editable)
            PopupMenuButton<String>(
              tooltip: 'Tuỳ chọn',
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    _rename();
                  case 'import':
                    _bulkImport();
                  case 'share':
                    _share();
                  case 'send':
                    _sendToFriend();
                  case 'export':
                    _export();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Sửa tên, mô tả, hướng dẫn'),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Text('Nhập hàng loạt'),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Text('Xuất bộ thẻ (CSV)'),
                ),
                if (widget.topic.mine) ...[
                  PopupMenuItem(
                    value: 'share',
                    child: Text(
                      _shareCode == null
                          ? 'Chia sẻ bằng mã'
                          : 'Mã chia sẻ: $_shareCode',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'send',
                    child: Text('Gửi cho bạn bè'),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Expanded(
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(lessonItemsProvider(_key)),
                        child: const Text('Không tải được thẻ. Thử lại'),
                      ),
                    ),
                    data: (items) => items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Bộ thẻ này chưa có thẻ nào. Bấm "Thêm thẻ" để bắt đầu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _ItemRow(
                              item: items[i],
                              editable: editable,
                              onEdit: () => _editItem(items[i]),
                              onDelete: () => _deleteItem(items[i]),
                            ),
                          ),
                  ),
                ),
                if (editable || count > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        if (editable)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editItem(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Thêm thẻ'),
                            ),
                          ),
                        if (editable && count > 0) const SizedBox(width: 12),
                        if (count > 0)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _study(count),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text('Học ngay ($count)'),
                            ),
                          ),
                      ],
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.editable,
    required this.onEdit,
    required this.onDelete,
  });

  final VocabularyItem item;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (item.imageUrl != null) ...[
            ItemImage(url: item.imageUrl!, height: 48, radius: 10),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.term,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DifficultyBadge(item: item),
                  ],
                ),
                if (item.phonetic != null)
                  Text(
                    item.phonetic!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  item.meaning,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                if (item.example != null && item.example != item.term)
                  Text(
                    'Ví dụ: ${item.example}',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          SpeakButton(text: item.term, audioUrl: item.audioUrl, size: 34),
          if (editable) ...[
            IconButton(
              tooltip: 'Sửa thẻ',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Xoá thẻ',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../practice/domain/practice_models.dart';
import '../../practice/presentation/practice_session_screen.dart';
import '../application/review_providers.dart';
import '../domain/wrong_item.dart';

/// Ôn lại đúng các mục đã sai/đến hạn — trộn nhiều dạng bài (Ghép cặp, Điền chỗ trống, Nghe...) trên
/// engine làm bài chung. [items] có thể trộn nhiều mảng; đáp án nhiễu chỉ lấy trong cùng mảng.
class ReviewQuizScreen extends StatelessWidget {
  const ReviewQuizScreen({super.key, required this.items});

  final List<WrongItem> items;

  @override
  Widget build(BuildContext context) {
    final categories = items.map((w) => w.category).toSet();
    return PracticeSessionScreen(
      config: PracticeConfig(
        title: 'Ôn tập · ${categories.length == 1 ? categories.first.label : 'Tất cả'}',
        kind: PracticeKind.mixed,
        load: (_) async => items,
        exitLabel: 'Xong',
        emptyMessage: 'Không có mục nào cần ôn tập.',
        onAnswered: (ref, entry, correct) {
          if (correct) ref.read(wrongItemsProvider.notifier).removeLocal(entry.item.id);
        },
      ),
    );
  }
}

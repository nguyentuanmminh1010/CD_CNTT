import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'word_chip.dart';

/// Dữ liệu kéo của một chip: đang ở khu "pool" (từ còn lại) hay khu câu trả lời, ở vị trí [index].
class WordDrag {
  const WordDrag({required this.fromPool, required this.index, required this.label});

  final bool fromPool;
  final int index;
  final String label;
}

bool get _isTouchPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.fuchsia;

/// Chip từ vừa bấm được ([onTap]) vừa kéo-thả được. Trên máy cảm ứng phải nhấn giữ một chút mới
/// kéo (để không tranh với thao tác cuộn trang); trên máy tính/web desktop kéo ngay khi nhấn chuột.
class DraggableWordChip extends StatelessWidget {
  const DraggableWordChip({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    required this.drag,
    this.enabled = true,
  });

  final String label;
  final WordChipState state;
  final VoidCallback? onTap;
  final WordDrag drag;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = WordChip(label: label, state: state, onTap: onTap);
    if (!enabled) return chip;

    final feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.92,
        child: WordChip(label: label, state: WordChipState.placed, onTap: null),
      ),
    );
    final ghost = Opacity(opacity: 0.3, child: chip);

    if (_isTouchPlatform) {
      return LongPressDraggable<WordDrag>(
        data: drag,
        delay: const Duration(milliseconds: 180),
        feedback: feedback,
        childWhenDragging: ghost,
        child: chip,
      );
    }
    return Draggable<WordDrag>(
      data: drag,
      feedback: feedback,
      childWhenDragging: ghost,
      child: chip,
    );
  }
}

/// Vùng nhận chip được kéo thả vào; [builder] nhận `hovering` = đang có chip kéo ngang qua vùng này.
class WordDropTarget extends StatelessWidget {
  const WordDropTarget({
    super.key,
    required this.onDrop,
    required this.builder,
    this.enabled = true,
  });

  final void Function(WordDrag drag) onDrop;
  final Widget Function(bool hovering) builder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DragTarget<WordDrag>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => builder(candidates.isNotEmpty),
    );
  }
}

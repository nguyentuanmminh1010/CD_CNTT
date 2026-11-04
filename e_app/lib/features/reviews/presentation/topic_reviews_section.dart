import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../application/review_providers.dart';
import '../domain/topic_review.dart';

/// Mục "Đánh giá" của một bài học: điểm trung bình + số lượt, form gửi/sửa đánh
/// giá của chính mình (1–5 sao + nhận xét), và các đánh giá mới nhất.
class TopicReviewsSection extends ConsumerStatefulWidget {
  const TopicReviewsSection({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicReviewsSection> createState() => _TopicReviewsSectionState();
}

class _TopicReviewsSectionState extends ConsumerState<TopicReviewsSection> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  bool _seeded = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(topicReviewRepositoryProvider)
          .submit(widget.topicId, _rating, _comment.text);
      ref.invalidate(topicReviewsProvider(widget.topicId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá của bạn.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không gửi được đánh giá. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(topicReviewsProvider(widget.topicId));
    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(topicReviewsProvider(widget.topicId)),
          child: const Text('Không tải được đánh giá. Thử lại'),
        ),
      ),
      data: (data) {
        if (!_seeded) {
          _seeded = true;
          _rating = data.myReview?.rating ?? 0;
          _comment.text = data.myReview?.comment ?? '';
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            _Summary(data: data),
            const SizedBox(height: 20),
            Text(data.myReview == null ? 'Đánh giá bài học này' : 'Đánh giá của bạn',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i sao',
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accentYellow,
                      size: 34,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'Chia sẻ cảm nhận của bạn (không bắt buộc)'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating == 0 || _saving ? null : _submit,
                child: Text(_saving
                    ? 'Đang gửi...'
                    : data.myReview == null
                        ? 'Gửi đánh giá'
                        : 'Cập nhật đánh giá'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Đánh giá từ người học',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            if (data.reviews.isEmpty)
              Text('Chưa có đánh giá nào — hãy là người đầu tiên!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            for (final r in data.reviews) ...[
              _ReviewTile(review: r),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});
  final TopicReviews data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(data.count == 0 ? '–' : data.average.toStringAsFixed(1),
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stars(value: data.average),
                const SizedBox(height: 4),
                Text(data.count == 0 ? 'Chưa có đánh giá' : '${data.count} lượt đánh giá',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 20});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i - 0.25
                ? Icons.star_rounded
                : value >= i - 0.75
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: AppColors.accentYellow,
            size: size,
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final TopicReview review;

  @override
  Widget build(BuildContext context) {
    final d = review.updatedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: review.mine ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(avatar: review.avatar, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.mine ? '${review.displayName} (Bạn)' : review.displayName,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5)),
                    Text('${two(d.day)}/${two(d.month)}/${d.year}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              _Stars(value: review.rating.toDouble(), size: 16),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.domain.TopicReview;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import com.nguyentuanminh.e_app.repository.TopicReviewRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Đánh giá bài học (chủ đề) bằng sao + nhận xét — mục "Đánh giá" ở màn chi tiết bài học. */
@Service
@RequiredArgsConstructor
public class TopicReviewService {

    public record ReviewView(Long id, String displayName, String avatar, int rating, String comment,
                             String updatedAt, boolean mine) {
    }

    public record ReviewsView(double average, int count, ReviewView myReview, List<ReviewView> reviews) {
    }

    private final TopicReviewRepository reviewRepository;
    private final LearningTopicRepository topicRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public ReviewsView getReviews(Long userId, Long topicId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem đánh giá.");
        }
        return build(userId, topicId);
    }

    @Transactional
    public ReviewsView submit(Long userId, Long topicId, int rating, String comment) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để đánh giá.");
        }
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Số sao phải từ 1 đến 5.");
        }
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        TopicReview review = reviewRepository.findByUserIdAndTopicId(userId, topicId).orElseGet(() -> {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
            TopicReview created = new TopicReview();
            created.setUser(user);
            created.setTopic(topic);
            return created;
        });
        review.setRating(rating);
        String text = comment == null ? "" : comment.trim();
        review.setComment(text.isEmpty() ? null : text.substring(0, Math.min(text.length(), 1000)));
        review.setUpdatedAt(Instant.now());
        reviewRepository.save(review);
        return build(userId, topicId);
    }

    private ReviewsView build(Long userId, Long topicId) {
        List<TopicReview> all = reviewRepository.findByTopicId(topicId);
        double average = all.stream().mapToInt(TopicReview::getRating).average().orElse(0);
        ReviewView mine = all.stream()
                .filter(r -> r.getUser().getId().equals(userId))
                .findFirst()
                .map(r -> view(r, userId))
                .orElse(null);
        List<ReviewView> latest = reviewRepository
                .findByTopicIdOrderByUpdatedAtDesc(topicId, PageRequest.of(0, 20))
                .stream().map(r -> view(r, userId)).toList();
        return new ReviewsView(Math.round(average * 10) / 10.0, all.size(), mine, latest);
    }

    private ReviewView view(TopicReview r, Long userId) {
        return new ReviewView(r.getId(), r.getUser().getDisplayName(), r.getUser().getAvatar(), r.getRating(), r.getComment(),
                r.getUpdatedAt().toString(), r.getUser().getId().equals(userId));
    }
}

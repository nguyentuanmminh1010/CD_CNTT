package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.TopicReview;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TopicReviewRepository extends JpaRepository<TopicReview, Long> {

    List<TopicReview> findByTopicIdOrderByUpdatedAtDesc(Long topicId, Pageable pageable);

    List<TopicReview> findByTopicId(Long topicId);

    void deleteByTopicId(Long topicId);

    Optional<TopicReview> findByUserIdAndTopicId(Long userId, Long topicId);
}

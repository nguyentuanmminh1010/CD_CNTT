package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.UserLearningItemProgress;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserLearningItemProgressRepository extends JpaRepository<UserLearningItemProgress, Long> {

    Optional<UserLearningItemProgress> findByUserIdAndItemId(Long userId, Long itemId);

    List<UserLearningItemProgress> findByUserIdAndMasteredFalseOrderByLastReviewedAtDesc(Long userId);

    /** Số mục đã thuộc trong KHO CHUNG (không tính bộ thẻ riêng) — dùng cho tiến độ/xếp hạng/thành tựu. */
    long countByUserIdAndMasteredTrueAndItemTopicOwnerIsNull(Long userId);

    long countByUserIdAndMasteredTrueAndItemTopicCategoryAndItemTopicOwnerIsNull(
            Long userId, LearningCategory category);

    long countByUserIdAndMasteredTrueAndItemTopicId(Long userId, Long topicId);

    void deleteByItemId(Long itemId);

    void deleteByItemTopicId(Long topicId);

    /** Các mục đến hạn ôn lại (Leitner), đến hạn lâu nhất trước. */
    @Query("""
            SELECT p FROM UserLearningItemProgress p
            WHERE p.user.id = :userId AND p.nextReviewAt IS NOT NULL AND p.nextReviewAt <= :now
            ORDER BY p.nextReviewAt ASC
            """)
    List<UserLearningItemProgress> findDue(
            @Param("userId") Long userId, @Param("now") Instant now, Pageable pageable);

    @Query("""
            SELECT COUNT(p) FROM UserLearningItemProgress p
            WHERE p.user.id = :userId AND p.nextReviewAt IS NOT NULL AND p.nextReviewAt <= :now
            """)
    long countDue(@Param("userId") Long userId, @Param("now") Instant now);

    /** Xếp hạng toàn thời gian: [userId, displayName, số mục kho chung đã thuộc], nhiều nhất trước. */
    @Query("""
            SELECT p.user.id, p.user.displayName, COUNT(p)
            FROM UserLearningItemProgress p
            WHERE p.mastered = true AND p.item.topic.owner IS NULL
            GROUP BY p.user.id, p.user.displayName
            ORDER BY COUNT(p) DESC, p.user.id ASC
            """)
    List<Object[]> rankByMasteredCount();

    /** Như {@link #rankByMasteredCount()} nhưng chỉ tính mục chuyển sang "đã thuộc" kể từ [since]. */
    @Query("""
            SELECT p.user.id, p.user.displayName, COUNT(p)
            FROM UserLearningItemProgress p
            WHERE p.mastered = true AND p.item.topic.owner IS NULL AND p.masteredAt >= :since
            GROUP BY p.user.id, p.user.displayName
            ORDER BY COUNT(p) DESC, p.user.id ASC
            """)
    List<Object[]> rankByMasteredCountSince(@Param("since") Instant since);
}

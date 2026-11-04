package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Mọi truy vấn "kho chung" (đề thi, đếm tổng, đề TOEIC) chỉ lấy mục thuộc chủ đề HỆ THỐNG
 * ({@code topic.owner IS NULL}) — mục trong bộ thẻ riêng của người dùng không lẫn vào đó.
 */
public interface LearningItemRepository extends JpaRepository<LearningItem, Long> {

    List<LearningItem> findByTopicIdOrderByDifficultyLevelAscIdAsc(Long topicId);

    long countByTopicId(Long topicId);

    void deleteByTopicId(Long topicId);

    List<LearningItem> findByTopicOwnerIsNullAndDifficultyLevelBetween(int minLevel, int maxLevel);

    List<LearningItem> findByTopicOwnerIsNullAndTopicCategoryAndDifficultyLevelBetween(
            LearningCategory category, int minLevel, int maxLevel);

    /** Tổng mục của kho chung (không tính bộ thẻ riêng). */
    long countByTopicOwnerIsNull();

    long countByTopicOwnerIsNullAndTopicCategory(LearningCategory category);

    /** Tìm theo term/meaning (không phân biệt hoa thường) trong kho chung + bộ thẻ của chính người tìm. */
    @Query("""
            SELECT li FROM LearningItem li
            WHERE (li.topic.owner IS NULL OR li.topic.owner.id = :userId)
              AND (LOWER(li.term) LIKE LOWER(CONCAT('%', :query, '%'))
                   OR LOWER(li.meaning) LIKE LOWER(CONCAT('%', :query, '%')))
            ORDER BY li.term ASC
            """)
    List<LearningItem> searchByTermOrMeaning(
            @Param("query") String query, @Param("userId") Long userId, Pageable pageable);

    /** Mục (kho chung) người dùng chưa đánh dấu "đã thuộc" — nguồn cho đề luyện thi thích ứng. */
    @Query("""
            SELECT li FROM LearningItem li
            WHERE li.topic.owner IS NULL AND li.id NOT IN (
                SELECT p.item.id FROM UserLearningItemProgress p
                WHERE p.user.id = :userId AND p.mastered = true
            )
            ORDER BY li.difficultyLevel ASC, li.id ASC
            """)
    List<LearningItem> findUnmasteredForUser(@Param("userId") Long userId);
}

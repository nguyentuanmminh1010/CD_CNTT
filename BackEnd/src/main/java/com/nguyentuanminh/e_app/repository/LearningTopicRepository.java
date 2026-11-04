package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LearningTopicRepository extends JpaRepository<LearningTopic, Long> {

    List<LearningTopic> findByCategoryOrderById(LearningCategory category);

    /** Chủ đề hệ thống + bộ thẻ riêng của {@code userId} (null = chỉ chủ đề hệ thống). */
    @Query("""
            SELECT t FROM LearningTopic t
            WHERE t.category = :category AND (t.owner IS NULL OR t.owner.id = :userId)
            ORDER BY t.owner.id ASC NULLS FIRST, t.id ASC
            """)
    List<LearningTopic> findVisible(
            @Param("category") LearningCategory category, @Param("userId") Long userId);

    List<LearningTopic> findByOwnerIsNullOrderByCategoryAscIdAsc();

    List<LearningTopic> findByOwnerIdOrderByIdDesc(Long ownerId);

    java.util.Optional<LearningTopic> findByShareCode(String shareCode);
}

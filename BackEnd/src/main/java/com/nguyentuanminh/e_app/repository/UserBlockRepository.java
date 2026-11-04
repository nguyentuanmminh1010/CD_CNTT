package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.UserBlock;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserBlockRepository extends JpaRepository<UserBlock, Long> {

    Optional<UserBlock> findByBlockerIdAndBlockedId(Long blockerId, Long blockedId);

    List<UserBlock> findByBlockerIdOrderByCreatedAtDesc(Long blockerId);

    /** Có chặn theo bất kỳ chiều nào giữa hai người không. */
    @Query("""
            SELECT COUNT(b) > 0 FROM UserBlock b
            WHERE (b.blocker.id = :a AND b.blocked.id = :b) OR (b.blocker.id = :b AND b.blocked.id = :a)
            """)
    boolean existsBetween(@Param("a") Long a, @Param("b") Long b);

    /** Id những người đã chặn [userId]. */
    @Query("SELECT b.blocker.id FROM UserBlock b WHERE b.blocked.id = :userId")
    List<Long> findBlockerIdsOf(@Param("userId") Long userId);
}

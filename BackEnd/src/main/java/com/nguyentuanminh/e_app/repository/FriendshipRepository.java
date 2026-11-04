package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.FriendStatus;
import com.nguyentuanminh.e_app.domain.Friendship;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    /** Hàng quan hệ giữa hai người (theo cả hai chiều), nếu có. */
    @Query("""
            SELECT f FROM Friendship f
            WHERE (f.requester.id = :a AND f.addressee.id = :b)
               OR (f.requester.id = :b AND f.addressee.id = :a)
            """)
    Optional<Friendship> findBetween(@Param("a") Long a, @Param("b") Long b);

    /** Mọi hàng liên quan tới người dùng (đã là bạn, đã gửi, đã nhận). */
    @Query("SELECT f FROM Friendship f WHERE f.requester.id = :u OR f.addressee.id = :u")
    List<Friendship> findInvolving(@Param("u") Long userId);

    List<Friendship> findByAddresseeIdAndStatusOrderByCreatedAtDesc(Long addresseeId, FriendStatus status);

    /** Lời mời [userId] đã gửi và vừa được chấp nhận từ [since] — nguồn cho thông báo. */
    List<Friendship> findByRequesterIdAndStatusAndRespondedAtAfterOrderByRespondedAtDesc(
            Long requesterId, FriendStatus status, Instant since);
}

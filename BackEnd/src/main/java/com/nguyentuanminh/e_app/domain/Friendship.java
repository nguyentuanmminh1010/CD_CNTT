package com.nguyentuanminh.e_app.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Quan hệ bạn bè HAI CHIỀU: {@code requester} gửi lời mời cho {@code addressee}; khi đối phương chấp nhận
 * ({@link FriendStatus#ACCEPTED}) thì hai bên là bạn của nhau (một hàng duy nhất cho cả cặp).
 */
@Entity
@Table(
        name = "friendship",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_friendship",
                columnNames = {"requester_id", "addressee_id"}))
@Getter
@Setter
@NoArgsConstructor
public class Friendship {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    private User requester;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addressee_id", nullable = false)
    private User addressee;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private FriendStatus status = FriendStatus.PENDING;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    /** Thời điểm được chấp nhận (null nếu còn chờ) — dùng cho thông báo "X đã chấp nhận lời mời". */
    @Column(name = "responded_at")
    private Instant respondedAt;
}

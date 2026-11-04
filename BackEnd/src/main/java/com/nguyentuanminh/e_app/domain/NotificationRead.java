package com.nguyentuanminh.e_app.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
 * Một thông báo (khoá ổn định do client sinh, vd {@code due:2026-10-05}) mà người dùng đã đọc.
 * Thông báo tự thân được suy ra từ dữ liệu mỗi lần mở; bảng này chỉ nhớ cái nào đã đọc.
 */
@Entity
@Table(
        name = "notification_read",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_notification_read",
                columnNames = {"user_id", "notification_key"}))
@Getter
@Setter
@NoArgsConstructor
public class NotificationRead {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "notification_key", nullable = false, length = 120)
    private String notificationKey;

    @Column(name = "read_at", nullable = false)
    private Instant readAt = Instant.now();
}

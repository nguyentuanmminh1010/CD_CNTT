package com.nguyentuanminh.e_app.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.time.LocalDate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "app_user",
        uniqueConstraints = {
            @UniqueConstraint(name = "uk_user_email", columnNames = "email"),
            @UniqueConstraint(name = "uk_user_provider", columnNames = {"auth_provider", "provider_id"})
        })
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Null cho tài khoản chỉ đăng nhập qua social mà Google/Facebook không trả email. */
    @Column
    private String email;

    /** Null cho tài khoản social-only (không có mật khẩu local). */
    @Column(name = "password_hash")
    private String passwordHash;

    @Column(name = "display_name", nullable = false)
    private String displayName;

    @Enumerated(EnumType.STRING)
    @Column(name = "auth_provider", nullable = false)
    private AuthProvider authProvider;

    /** id của user bên Google/Facebook, null với tài khoản LOCAL. */
    @Column(name = "provider_id")
    private String providerId;

    /** Ảnh đại diện dạng data URL (base64, đã thu nhỏ ở client) — null nếu chưa đặt. */
    @Column(columnDefinition = "text")
    private String avatar;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    /** Dưới đây là dữ liệu khảo sát cá nhân hoá sau đăng ký — null cho tới khi
     * người dùng hoàn thành khảo sát (mutation {@code updateProfile}). */
    @Column
    private LocalDate dob;

    @Enumerated(EnumType.STRING)
    @Column
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(name = "learning_purpose")
    private LearningPurpose learningPurpose;

    @Column(name = "daily_minutes")
    private Integer dailyMinutes;

    @Enumerated(EnumType.STRING)
    @Column(name = "start_mode")
    private StartMode startMode;
}

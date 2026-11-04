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
import java.time.LocalDate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Một ngày người dùng có hoạt động học thật (gọi bất kỳ mutation
 * {@code mark*ItemMastered} nào — Flashcard/Trắc nghiệm/Ôn tập/Luyện thi
 * TOEIC) — nguồn dữ liệu cho chuỗi ngày học và tab Tiến độ, xem CLAUDE.md.
 */
@Entity
@Table(
        name = "user_activity_day",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_user_activity_date",
                columnNames = {"user_id", "activity_date"}))
@Getter
@Setter
@NoArgsConstructor
public class UserActivityDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "activity_date", nullable = false)
    private LocalDate activityDate;

    @Column(name = "items_completed", nullable = false)
    private int itemsCompleted = 0;
}

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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Tổng số lượt luyện tập + số lượt đúng của MỘT người dùng theo MỘT kỹ năng
 * (Đọc/Viết/Nghe/Nói) — nguồn dữ liệu cho radar chart 4 kỹ năng ở Hồ sơ. Ghi
 * nhận qua mutation `recordSkillAttempt`, gọi cạnh `mark*ItemMastered` ở các
 * bài tập đã gắn với 1 kỹ năng cụ thể (vd Trắc nghiệm = Đọc, Dịch câu = Viết). */
@Entity
@Table(
        name = "user_skill_stat",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_user_skill",
                columnNames = {"user_id", "skill"}))
@Getter
@Setter
@NoArgsConstructor
public class UserSkillStat {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Skill skill;

    @Column(name = "total_attempts", nullable = false)
    private int totalAttempts = 0;

    @Column(name = "correct_attempts", nullable = false)
    private int correctAttempts = 0;
}

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
 * Tiến độ học theo TỪNG người dùng cho một {@link LearningItem} bất kỳ (dùng
 * chung cho cả Vocabulary/Grammar/Sentence). Có thêm trạng thái lặp lại ngắt
 * quãng kiểu Leitner ({@link #box}, {@link #nextReviewAt}).
 */
@Entity
@Table(
        name = "user_learning_item_progress",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_user_learning_item",
                columnNames = {"user_id", "learning_item_id"}))
@Getter
@Setter
@NoArgsConstructor
public class UserLearningItemProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learning_item_id", nullable = false)
    private LearningItem item;

    /** Kết quả của lần trả lời gần nhất: đúng/đã thuộc = true. */
    @Column(nullable = false)
    private boolean mastered = false;

    @Column(name = "review_count", nullable = false)
    private int reviewCount = 0;

    @Column(name = "last_reviewed_at")
    private Instant lastReviewedAt;

    /** Thời điểm chuyển sang "đã thuộc" gần nhất (null khi chưa thuộc) — nguồn của xếp hạng tuần. */
    @Column(name = "mastered_at")
    private Instant masteredAt;

    /** Hộp Leitner 0..5: sai thì về 0, đúng thì lên 1 hộp. */
    @Column(name = "box", nullable = false, columnDefinition = "integer default 0")
    private int box = 0;

    /** Đến hạn ôn lại từ thời điểm này (null = chưa từng trả lời). */
    @Column(name = "next_review_at")
    private Instant nextReviewAt;
}

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
import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Một lượt làm bài hoàn chỉnh (Đánh giá/Xếp lớp/TOEIC/Đọc/Viết) — nguồn dữ
 * liệu cho lịch sử bài kiểm tra và các thành tựu. Câu trả lời từng câu vẫn lưu
 * ở {@link UserLearningItemProgress}; bảng này chỉ lưu kết quả tổng của lượt. */
@Entity
@Table(name = "attempt")
@Getter
@Setter
@NoArgsConstructor
public class Attempt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttemptType type;

    /** Tên hiển thị của bài (vd "Từ vựng cơ bản", "Kiểm tra xếp lớp"). */
    @Column(nullable = false)
    private String title;

    @Column(name = "total_questions", nullable = false)
    private int totalQuestions;

    @Column(name = "correct_count", nullable = false)
    private int correctCount;

    /** Khoá tham chiếu tuỳ chọn, vd "level:{courseId}:{level}" cho Level Test. */
    @Column(name = "ref_key")
    private String refKey;

    /** Khoá gom các {@link AttemptAnswer} của lượt này (do client sinh) — duy nhất theo user. */
    @Column(name = "attempt_key")
    private String attemptKey;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}

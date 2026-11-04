package com.nguyentuanminh.e_app.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Một câu trả lời ĐÃ ĐƯỢC BACKEND CHẤM. Gom theo {@code attemptKey} (do client sinh cho
 * mỗi lượt làm bài) để {@code finishAttempt} tính điểm từ chính các câu này, và để xem
 * lại đáp án ở lịch sử. {@code attemptKey} null = câu làm lẻ trong một chủ đề. */
@Entity
@Table(name = "attempt_answer", indexes = @Index(name = "idx_answer_attempt_key", columnList = "attempt_key"))
@Getter
@Setter
@NoArgsConstructor
public class AttemptAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learning_item_id", nullable = false)
    private LearningItem item;

    @Column(name = "attempt_key")
    private String attemptKey;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AnswerMode mode;

    @Column(length = 1000)
    private String answer;

    @Column(nullable = false)
    private boolean correct;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}

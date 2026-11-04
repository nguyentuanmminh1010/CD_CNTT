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

/** Đánh giá (1–5 sao + nhận xét) của một người dùng về một bài học (chủ đề);
 * mỗi user chỉ có một đánh giá cho mỗi chủ đề, gửi lại sẽ ghi đè. */
@Entity
@Table(
        name = "topic_review",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_review_user_topic",
                columnNames = {"user_id", "topic_id"}))
@Getter
@Setter
@NoArgsConstructor
public class TopicReview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id", nullable = false)
    private LearningTopic topic;

    @Column(nullable = false)
    private int rating;

    @Column(length = 1000)
    private String comment;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}

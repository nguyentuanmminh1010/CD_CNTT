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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Điểm thành thạo (mastery, 0..1) của MỘT người dùng với MỘT chủ đề — trung bình
 * trượt mũ của các lần trả lời, cập nhật sau mỗi câu; dùng chọn độ khó/chủ đề kế tiếp. */
@Entity
@Table(
        name = "user_topic_mastery",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_user_topic_mastery",
                columnNames = {"user_id", "topic_id"}))
@Getter
@Setter
@NoArgsConstructor
public class UserTopicMastery {

    /** Điểm khởi đầu cho chủ đề chưa từng học — thấp để bắt đầu từ câu dễ. */
    public static final double INITIAL_SCORE = 0.3;

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
    private double score = INITIAL_SCORE;

    @Column(nullable = false)
    private int answers = 0;
}

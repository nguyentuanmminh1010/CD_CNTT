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
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Một mục nội dung học — dùng chung cho cả Vocabulary (term/phonetic/meaning),
 * Grammar (tên cấu trúc/phonetic=null/giải thích) và Sentence (câu mẫu/nghĩa).
 * Cùng một hình dạng dữ liệu nên frontend tái dùng được y hệt UI Flashcard/Quiz
 * cho cả 3 mảng — xem CLAUDE.md > Kiến trúc Backend.
 */
@Entity
@Table(name = "learning_item")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LearningItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String term;

    /** Phiên âm — chủ yếu dùng cho Vocabulary, null với Grammar/Sentence. */
    private String phonetic;

    @Column(nullable = false)
    private String meaning;

    private String example;

    /** Lời giải thích (ngữ pháp/cách dùng) — hiện ở màn xem lại đáp án. Null = dùng lời giải sinh tự động. */
    @Column(columnDefinition = "text")
    private String explanation;

    /** Hình minh hoạ: URL http(s) hoặc data URL base64 (ảnh người dùng chọn, đã thu nhỏ). */
    @Column(name = "image_url", columnDefinition = "text")
    private String imageUrl;

    /** URL file audio (http/https). Không có thì client đọc {@code term} bằng giọng máy (TTS). */
    @Column(name = "audio_url", length = 500)
    private String audioUrl;

    /** 1 = cơ bản, 2 = trung bình, 3 = nâng cao. */
    @Column(name = "difficulty_level", nullable = false)
    private int difficultyLevel = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id", nullable = false)
    private LearningTopic topic;
}

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
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Chủ đề học — dùng chung cho cả 3 mảng nội dung (Vocabulary/Grammar/Sentence),
 * phân biệt bằng {@link #category}. Xem CLAUDE.md > Kiến trúc Backend.
 *
 * <p>{@link #owner} null = chủ đề HỆ THỐNG (seed/admin quản lý, ai cũng thấy, tính
 * vào xếp hạng/đề thi). {@link #owner} khác null = "bộ thẻ" riêng của một người dùng:
 * chỉ chủ sở hữu thấy và sửa, và <b>không</b> tính vào xếp hạng/đề thi chung (tránh
 * tự tạo thẻ để lấy điểm).
 */
@Entity
@Table(name = "learning_topic")
@Getter
@Setter
@NoArgsConstructor
public class LearningTopic {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    /** Tên icon Material (vd "style_rounded") để frontend render nhất quán. */
    private String icon;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LearningCategory category;

    /** Nội dung tab "Hướng dẫn" của bài học (văn bản, xuống dòng = bước mới). Null = client dùng bước mặc định. */
    @Column(columnDefinition = "text")
    private String guide;

    /** Mã chia sẻ bộ thẻ riêng (null = không chia sẻ); người khác nhập mã để sao chép bộ thẻ về. */
    @Column(name = "share_code", unique = true, length = 16)
    private String shareCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private User owner;

    public LearningTopic(Long id, String name, String description, String icon, LearningCategory category) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.icon = icon;
        this.category = category;
    }
}

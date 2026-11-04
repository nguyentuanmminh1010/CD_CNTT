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
 * Lần ĐẦU người dùng hoàn thành một khoá học = giấy chứng nhận đã cấp, lưu vĩnh viễn.
 *
 * <p>Tiến độ khoá học vẫn tính trực tiếp từ nội dung hiện tại (thêm mục vào chủ đề trong khoá làm % giảm), nhưng
 * chứng chỉ lấy từ bảng này nên không mất khi khoá có thêm nội dung. Ghi bởi {@code CourseService} khi lần đầu thấy
 * khoá đã đăng ký ở trạng thái hoàn thành.
 */
@Entity
@Table(
        name = "course_completion",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_course_completion_user_course",
                columnNames = {"user_id", "course_id"}))
@Getter
@Setter
@NoArgsConstructor
public class CourseCompletion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    @Column(name = "completed_at", nullable = false)
    private Instant completedAt = Instant.now();
}

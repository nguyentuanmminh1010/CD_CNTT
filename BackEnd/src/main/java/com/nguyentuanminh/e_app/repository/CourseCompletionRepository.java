package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.CourseCompletion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CourseCompletionRepository extends JpaRepository<CourseCompletion, Long> {

    Optional<CourseCompletion> findByUserIdAndCourseId(Long userId, Long courseId);

    /**
     * Ghi mốc hoàn thành nếu chưa có. Dùng ON CONFLICT vì nhiều request song song (danh sách khoá + chứng chỉ ở Hồ
     * sơ) có thể cùng thấy khoá vừa hoàn thành — insert thường sẽ vi phạm unique và làm hỏng transaction.
     */
    @Modifying
    @Query(value = "INSERT INTO course_completion (user_id, course_id, completed_at) VALUES (:userId, :courseId, now()) "
            + "ON CONFLICT (user_id, course_id) DO NOTHING", nativeQuery = true)
    int insertIfAbsent(@Param("userId") Long userId, @Param("courseId") Long courseId);

    List<CourseCompletion> findByUserIdOrderByCompletedAtAsc(Long userId);

    void deleteByCourseId(Long courseId);
}

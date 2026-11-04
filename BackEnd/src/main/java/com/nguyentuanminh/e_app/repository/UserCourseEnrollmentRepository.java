package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.UserCourseEnrollment;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserCourseEnrollmentRepository extends JpaRepository<UserCourseEnrollment, Long> {

    boolean existsByUserIdAndCourseId(Long userId, Long courseId);

    List<UserCourseEnrollment> findByUserId(Long userId);

    long countByUserId(Long userId);

    void deleteByCourseId(Long courseId);
}

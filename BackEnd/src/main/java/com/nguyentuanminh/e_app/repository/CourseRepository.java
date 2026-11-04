package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.Course;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseRepository extends JpaRepository<Course, Long> {

    boolean existsByTitle(String title);
}

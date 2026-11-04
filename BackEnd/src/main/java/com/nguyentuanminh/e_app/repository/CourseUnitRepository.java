package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.CourseUnit;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseUnitRepository extends JpaRepository<CourseUnit, Long> {

    List<CourseUnit> findByCourseIdOrderByLevelAscPositionAsc(Long courseId);

    void deleteByCourseId(Long courseId);
}

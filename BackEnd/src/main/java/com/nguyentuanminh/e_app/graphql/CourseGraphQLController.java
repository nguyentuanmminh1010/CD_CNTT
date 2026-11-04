package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.service.CourseService;
import com.nguyentuanminh.e_app.service.CourseView;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Khoá học (Level → Unit), đăng ký khoá học và giấy chứng nhận hoàn thành. */
@Controller
@RequiredArgsConstructor
public class CourseGraphQLController {

    private final CourseService courseService;

    @QueryMapping
    public List<CourseView> courses(@ContextValue(name = "userId", required = false) Long userId) {
        return courseService.getCourses(userId);
    }

    @QueryMapping
    public CourseView course(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long id) {
        return courseService.getCourse(userId, id);
    }

    @QueryMapping
    public List<CourseView> certificates(
            @ContextValue(name = "userId", required = false) Long userId) {
        return courseService.getCompletedCourses(userId);
    }

    @MutationMapping
    public CourseView createCourse(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument String title, @Argument String description, @Argument String icon) {
        return courseService.createCourse(userId, title, description, icon);
    }

    @MutationMapping
    public boolean deleteCourse(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long id) {
        return courseService.deleteCourse(userId, id);
    }

    @MutationMapping
    public CourseView addCourseUnit(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument Long courseId, @Argument int level, @Argument Long topicId) {
        return courseService.addUnit(userId, courseId, level, topicId);
    }

    @MutationMapping
    public CourseView removeCourseUnit(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long unitId) {
        return courseService.removeUnit(userId, unitId);
    }

    @MutationMapping
    public CourseView enrollCourse(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long courseId) {
        return courseService.enroll(userId, courseId);
    }
}

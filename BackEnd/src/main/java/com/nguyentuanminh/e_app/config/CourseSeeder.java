package com.nguyentuanminh.e_app.config;

import com.nguyentuanminh.e_app.domain.Course;
import com.nguyentuanminh.e_app.domain.CourseUnit;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.repository.CourseRepository;
import com.nguyentuanminh.e_app.repository.CourseUnitRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Seed các khoá học mẫu (4 khoá gốc chỉ khi chưa có khoá nào; khoá thêm sau tạo nếu chưa có — xem
 * {@link #seedAdvancedCourses()}) — mỗi Unit trỏ tới một
 * chủ đề đã seed bởi {@link LearningContentSeeder}, nên khoá học không có nội
 * dung riêng. Chạy sau seeder nội dung gốc và bổ sung (xem {@link Order}).
 */
@Component
@Order(3)
public class CourseSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(CourseSeeder.class);

    private final CourseRepository courseRepository;
    private final CourseUnitRepository unitRepository;
    private final LearningTopicRepository topicRepository;

    public CourseSeeder(CourseRepository courseRepository,
                        CourseUnitRepository unitRepository,
                        LearningTopicRepository topicRepository) {
        this.courseRepository = courseRepository;
        this.unitRepository = unitRepository;
        this.topicRepository = topicRepository;
    }

    /** Một Unit mẫu: Level + chủ đề (tra theo category và tên). */
    private record Ref(int level, LearningCategory category, String topicName) {
    }

    private static Ref r(int level, LearningCategory category, String topicName) {
        return new Ref(level, category, topicName);
    }

    @Override
    public void run(String... args) {
        if (topicRepository.count() == 0) {
            return;
        }
        if (courseRepository.count() == 0) {
            seedBaseCourses();
        }
        seedAdvancedCourses();
    }

    /**
     * Khoá thêm sau (04/11/2026) — tạo nếu CHƯA có khoá cùng tiêu đề, chạy mỗi lần khởi động để DB đang dùng cũng có.
     * Dùng các chủ đề ngữ pháp mới của {@link ContentSupplementSeeder} (chạy trước, {@code @Order(2)}); tách thành khoá
     * riêng thay vì thêm Unit vào "Ngữ pháp nền tảng" để người đã hoàn thành khoá đó không bị tính lại là chưa xong.
     * Mỗi Level 2 chủ đề × 6 điểm = đủ 12 câu cho Level Test.
     */
    private void seedAdvancedCourses() {
        LearningCategory g = LearningCategory.GRAMMAR;
        String title = "Ngữ pháp nâng cao";
        if (courseRepository.existsByTitle(title)) {
            return;
        }
        seed(title,
                "Học tiếp sau Ngữ pháp nền tảng: động từ khuyết thiếu, danh động từ, mệnh đề quan hệ và câu gián tiếp.",
                "gavel_rounded", List.of(
                        r(1, g, "Động từ khuyết thiếu"), r(1, g, "Danh động từ & To-V"),
                        r(2, g, "Mệnh đề quan hệ"), r(2, g, "Câu gián tiếp")));
        log.info("CourseSeeder: đã tạo khoá '{}'.", title);
    }

    private void seedBaseCourses() {
        LearningCategory v = LearningCategory.VOCABULARY;
        LearningCategory g = LearningCategory.GRAMMAR;
        LearningCategory s = LearningCategory.SENTENCE;

        seed("Từ vựng căn bản",
                "Làm quen 10 nhóm từ vựng thông dụng nhất, từ du lịch, công việc đến cảm xúc hằng ngày.",
                "style_rounded", List.of(
                        r(1, v, "Du lịch"), r(1, v, "Công việc"), r(1, v, "Đời sống"),
                        r(1, v, "Giáo dục"), r(1, v, "Công nghệ"),
                        r(2, v, "Sức khoẻ"), r(2, v, "Ẩm thực"), r(2, v, "Mua sắm"),
                        r(2, v, "Thời tiết"), r(2, v, "Cảm xúc")));

        seed("Ngữ pháp nền tảng",
                "Nắm chắc các thì, câu điều kiện, câu bị động và cấu trúc so sánh trong tiếng Anh.",
                "rule_rounded", List.of(
                        r(1, g, "Thì hiện tại"), r(1, g, "Thì quá khứ"), r(1, g, "Thì tương lai"),
                        r(1, g, "Danh từ & Mạo từ"),
                        r(2, g, "Câu điều kiện"), r(2, g, "Câu bị động"), r(2, g, "Giới từ"),
                        r(2, g, "So sánh")));

        seed("Giao tiếp hằng ngày",
                "Các mẫu câu dùng ngay trong đời sống: chào hỏi, nhà hàng, sân bay, công sở, điện thoại.",
                "chat_bubble_rounded", List.of(
                        r(1, s, "Chào hỏi"), r(1, s, "Giới thiệu bản thân"), r(1, s, "Tại nhà hàng"),
                        r(1, s, "Mua sắm"),
                        r(2, s, "Tại sân bay"), r(2, s, "Hỏi đường"), r(2, s, "Công sở"),
                        r(2, s, "Điện thoại")));

        seed("500+ TOEIC",
                "Lộ trình trộn từ vựng, ngữ pháp và mẫu câu hướng tới mục tiêu 500+ điểm TOEIC.",
                "workspace_premium_rounded", List.of(
                        r(1, v, "Công việc"), r(1, s, "Công sở"), r(1, g, "Thì hiện tại"),
                        r(1, g, "Thì quá khứ"),
                        r(2, v, "Du lịch"), r(2, s, "Tại sân bay"), r(2, g, "Giới từ"),
                        r(2, g, "Câu bị động"),
                        r(3, v, "Công nghệ"), r(3, g, "Câu điều kiện"), r(3, g, "So sánh")));
    }

    private void seed(String title, String description, String icon, List<Ref> refs) {
        Course course = courseRepository.save(new Course(null, title, description, icon));
        List<CourseUnit> units = new ArrayList<>();
        int position = 1;
        for (Ref ref : refs) {
            LearningTopic topic = topicRepository.findByCategoryOrderById(ref.category()).stream()
                    .filter(t -> t.getName().equals(ref.topicName()))
                    .findFirst()
                    .orElse(null);
            if (topic == null) {
                log.warn("CourseSeeder: không tìm thấy chủ đề '{}' ({}), bỏ qua Unit.",
                        ref.topicName(), ref.category());
                continue;
            }
            units.add(new CourseUnit(null, course, ref.level(), position++, topic));
        }
        unitRepository.saveAll(units);
    }
}

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
 * Seed các khoá học mẫu khi bảng {@code course} trống (DB mới, hoặc vừa nạp bộ nội dung mới — {@link OpenContentSeeder}
 * xoá khoá học cũ vì Unit trỏ tới chủ đề cũ). Mỗi Unit trỏ tới một chủ đề kho chung tra theo mảng + tên, nên khoá học
 * không có nội dung riêng. Mỗi Level có ≥ 12 mục để đủ đề Level Test.
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
    record Ref(int level, LearningCategory category, String topicName) {
    }

    record CourseSeed(String title, String description, String icon, List<Ref> units) {
    }

    private static Ref r(int level, LearningCategory category, String topicName) {
        return new Ref(level, category, topicName);
    }

    static List<CourseSeed> courses() {
        LearningCategory v = LearningCategory.VOCABULARY;
        LearningCategory g = LearningCategory.GRAMMAR;
        LearningCategory s = LearningCategory.SENTENCE;
        return List.of(
                new CourseSeed("Từ vựng căn bản",
                        "Những nhóm từ thông dụng nhất trong đời sống: gia đình, nhà cửa, ăn uống, mua sắm, du lịch, "
                                + "sức khoẻ và cảm xúc.",
                        "style_rounded", List.of(
                        r(1, v, "Con người & Gia đình"), r(1, v, "Nhà cửa & Sinh hoạt"), r(1, v, "Ăn uống & Nấu nướng"),
                        r(1, v, "Mua sắm"), r(1, v, "Thời tiết & Môi trường"),
                        r(2, v, "Du lịch"), r(2, v, "Giáo dục"), r(2, v, "Công nghệ"), r(2, v, "Sức khoẻ & Y tế"),
                        r(2, v, "Cảm xúc & Tính cách"), r(2, v, "Thể thao & Giải trí"))),
                new CourseSeed("Ngữ pháp nền tảng",
                        "Nắm chắc các thì, danh từ – mạo từ, đại từ, giới từ, so sánh, câu hỏi và câu bị động.",
                        "rule_rounded", List.of(
                        r(1, g, "Thì hiện tại"), r(1, g, "Thì quá khứ"), r(1, g, "Thì tương lai"),
                        r(1, g, "Danh từ, mạo từ & lượng từ"), r(1, g, "Đại từ"),
                        r(2, g, "Giới từ"), r(2, g, "So sánh"), r(2, g, "Câu hỏi & cấu trúc câu"),
                        r(2, g, "Câu bị động"))),
                new CourseSeed("Ngữ pháp nâng cao",
                        "Học tiếp sau Ngữ pháp nền tảng: động từ khuyết thiếu, danh động từ, mệnh đề quan hệ, câu gián "
                                + "tiếp và câu điều kiện.",
                        "gavel_rounded", List.of(
                        r(1, g, "Động từ khuyết thiếu"), r(1, g, "Danh động từ & To-V"),
                        r(2, g, "Mệnh đề quan hệ"), r(2, g, "Câu gián tiếp"), r(2, g, "Câu điều kiện & câu ước"))),
                new CourseSeed("Giao tiếp hằng ngày",
                        "Mẫu câu dùng ngay trong đời sống: chào hỏi, giới thiệu, ăn uống, mua sắm, hỏi đường, du lịch.",
                        "chat_bubble_rounded", List.of(
                        r(1, s, "Chào hỏi & Làm quen"), r(1, s, "Giới thiệu bản thân"), r(1, s, "Gia đình & Bạn bè"),
                        r(1, s, "Sở thích & Thời gian rảnh"), r(1, s, "Ăn uống & Nhà hàng"), r(1, s, "Mua sắm"),
                        r(2, s, "Hỏi đường & Đi lại"), r(2, s, "Du lịch & Khách sạn"), r(2, s, "Sức khoẻ"),
                        r(2, s, "Thời tiết"), r(2, s, "Lời mời & Đề nghị"), r(2, s, "Cảm ơn & Xin lỗi"))),
                new CourseSeed("500+ TOEIC",
                        "Lộ trình theo chủ đề thi TOEIC: văn phòng, thư từ, hội họp, tuyển dụng, đi lại, khách sạn, "
                                + "kinh doanh và sản xuất — kèm ngữ pháp hay ra thi.",
                        "workspace_premium_rounded", List.of(
                        r(1, v, "Văn phòng"), r(1, v, "Liên lạc & Thư từ"), r(1, s, "Công việc & Văn phòng"),
                        r(1, g, "Thì hiện tại"),
                        r(2, v, "Hội họp & Sự kiện"), r(2, v, "Tuyển dụng & Nhân sự"), r(2, v, "Sân bay & Giao thông"),
                        r(2, v, "Khách sạn & Đặt chỗ"), r(2, s, "Điện thoại & Hẹn gặp"), r(2, g, "Câu bị động"),
                        r(3, v, "Kinh doanh & Tài chính"), r(3, v, "Sản xuất & Kho vận"),
                        r(3, v, "Nhà hàng & Quán cà phê"), r(3, g, "Câu điều kiện & câu ước"), r(3, g, "Giới từ"))));
    }

    @Override
    public void run(String... args) {
        if (topicRepository.count() == 0 || courseRepository.count() > 0) {
            return;
        }
        for (CourseSeed c : courses()) {
            seed(c);
        }
        log.info("CourseSeeder: đã tạo {} khoá học mẫu.", courses().size());
    }

    private void seed(CourseSeed seed) {
        Course course = courseRepository.save(new Course(null, seed.title(), seed.description(), seed.icon()));
        List<CourseUnit> units = new ArrayList<>();
        int position = 1;
        for (Ref ref : seed.units()) {
            LearningTopic topic = topicRepository.findByCategoryOrderById(ref.category()).stream()
                    .filter(t -> t.getOwner() == null && t.getName().equals(ref.topicName()))
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

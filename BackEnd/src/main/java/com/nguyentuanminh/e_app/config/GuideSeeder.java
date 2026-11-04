package com.nguyentuanminh.e_app.config;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Điền nội dung tab "Hướng dẫn" mặc định cho chủ đề hệ thống chưa có (theo mảng nội dung, có tên chủ đề).
 * Chỉ ghi khi {@code guide} đang null — admin sửa tay ở màn quản trị nội dung sẽ không bị ghi đè.
 * Đây là hướng dẫn mẫu theo mảng, không phải nội dung biên tập riêng của từng bài.
 */
@Component
@Order(4)
public class GuideSeeder implements CommandLineRunner {

    private final LearningTopicRepository topicRepository;

    public GuideSeeder(LearningTopicRepository topicRepository) {
        this.topicRepository = topicRepository;
    }

    @Override
    public void run(String... args) {
        List<LearningTopic> missing = topicRepository.findByOwnerIsNullOrderByCategoryAscIdAsc().stream()
                .filter(t -> t.getGuide() == null || t.getGuide().isBlank())
                .toList();
        for (LearningTopic topic : missing) {
            topic.setGuide(defaultGuide(topic.getCategory(), topic.getName()));
        }
        if (!missing.isEmpty()) {
            topicRepository.saveAll(missing);
        }
    }

    static String defaultGuide(LearningCategory category, String name) {
        return switch (category) {
            case VOCABULARY -> String.join("\n",
                    "Xem lướt toàn bộ từ của chủ đề \"" + name + "\" ở tab Lý thuyết: chú ý phiên âm và câu ví dụ.",
                    "Học Flashcard: lật thẻ, đọc to từ đó, bấm \"Đã thuộc\" khi nhớ nghĩa hoặc \"Cần ôn\" nếu chưa chắc.",
                    "Làm Trắc nghiệm để kiểm tra nhớ nghĩa, rồi Sắp xếp câu để dùng từ đúng ngữ cảnh.",
                    "Ôn lại các từ làm sai ở \"Ôn tập lỗi sai\" — hệ thống tự nhắc ôn đúng hạn (sau 1, 2, 4, 8, 16 ngày).",
                    "Khi đã thuộc hết, làm Level Test của khoá học để mở khoá cấp tiếp theo.");
            case GRAMMAR -> String.join("\n",
                    "Đọc kỹ từng cấu trúc của \"" + name + "\" ở tab Lý thuyết: công thức, cách dùng và ví dụ.",
                    "Tự đặt một câu của riêng bạn cho mỗi cấu trúc rồi so với câu ví dụ.",
                    "Học Flashcard để nhớ công thức, rồi làm Trắc nghiệm để phân biệt các trường hợp dùng.",
                    "Luyện Sắp xếp câu để quen trật tự từ đúng của từng cấu trúc.",
                    "Xem lại phần lỗi sai và đọc lời giải thích ở màn \"Xem lại đáp án\" sau mỗi bài làm.");
            case SENTENCE -> String.join("\n",
                    "Đọc to từng mẫu câu của chủ đề \"" + name + "\" ở tab Lý thuyết, chú ý nhấn nhá và ngữ điệu.",
                    "Học Flashcard để nhớ nghĩa tiếng Việt của mẫu câu.",
                    "Luyện Sắp xếp câu và Dịch câu để quen cấu trúc và cách ghép từ.",
                    "Thử Luyện nói: nói mẫu câu vào micro để so khớp với câu mẫu.",
                    "Áp dụng ngay: dùng mẫu câu trong một tình huống thật của bạn trong ngày.");
        };
    }
}

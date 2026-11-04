package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.LearningTopic;
import java.util.List;

/** Khoá học kèm tiến độ của người dùng đang xem. {@code units} rỗng ở danh
 * sách khoá học (chỉ điền ở chi tiết một khoá). */
public record CourseView(
        Long id,
        String title,
        String description,
        String icon,
        boolean enrolled,
        int unitCount,
        int completedUnits,
        int totalItems,
        int masteredItems,
        boolean completed,
        /* Đã nhận chứng chỉ (lưu vĩnh viễn từ lần hoàn thành đầu tiên) — vẫn true dù khoá có thêm nội dung sau đó. */
        boolean certified,
        /* Thời điểm hoàn thành lần đầu (ISO-8601), null nếu chưa. */
        String certifiedAt,
        List<UnitView> units,
        List<LevelResult> levelResults) {

    public record UnitView(
            Long id,
            int level,
            int position,
            LearningTopic topic,
            int totalItems,
            int masteredItems,
            boolean completed,
            boolean locked) {
    }

    /** Kết quả Level Test của một Level: điểm cao nhất đã đạt và đã vượt ngưỡng chưa. */
    public record LevelResult(int level, int bestPercent, boolean attempted, boolean passed) {
    }
}

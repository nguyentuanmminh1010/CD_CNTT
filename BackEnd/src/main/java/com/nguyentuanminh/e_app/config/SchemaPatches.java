package com.nguyentuanminh.e_app.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Vá các thay đổi schema mà {@code spring.jpa.hibernate.ddl-auto=update} không tự làm.
 * Với cột enum lưu dạng chuỗi, Hibernate tạo ràng buộc CHECK liệt kê giá trị enum
 * lúc tạo bảng và KHÔNG cập nhật khi sau này thêm giá trị mới (vd {@code AttemptType.SPEAKING}),
 * khiến INSERT giá trị mới bị DB từ chối. Ở đây gỡ ràng buộc đó (idempotent) — việc kiểm
 * giá trị đã do enum Java + GraphQL đảm nhiệm. Thêm giá trị enum mới cho cột khác thì bổ sung
 * dòng tương ứng vào {@link #CONSTRAINTS_TO_DROP}. Chạy trước các seeder ({@code @Order(0)}).
 */
@Component
@Order(0)
public class SchemaPatches implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(SchemaPatches.class);

    private static final String[][] CONSTRAINTS_TO_DROP = {
            {"attempt", "attempt_type_check"},
    };

    private final JdbcTemplate jdbc;

    public SchemaPatches(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Cập nhật dữ liệu cũ cho các cột mới. */
    private static final String[] DATA_PATCHES = {
        // mục đã thuộc từ trước khi có cột mastered_at: lấy lần ôn gần nhất làm mốc (xếp hạng tuần)
        "UPDATE user_learning_item_progress SET mastered_at = last_reviewed_at "
                + "WHERE mastered = true AND mastered_at IS NULL",
        // mục chưa thuộc/chưa có lịch ôn: đến hạn ôn ngay để vào hàng đợi lặp lại ngắt quãng
        "UPDATE user_learning_item_progress SET next_review_at = last_reviewed_at "
                + "WHERE next_review_at IS NULL AND last_reviewed_at IS NOT NULL AND mastered = false",
    };

    @Override
    public void run(String... args) {
        for (String sql : DATA_PATCHES) {
            try {
                jdbc.update(sql);
            } catch (Exception e) {
                log.warn("SchemaPatches: bỏ qua bản vá dữ liệu: {}", e.getMessage());
            }
        }
        for (String[] c : CONSTRAINTS_TO_DROP) {
            try {
                jdbc.execute("ALTER TABLE " + c[0] + " DROP CONSTRAINT IF EXISTS " + c[1]);
            } catch (Exception e) {
                log.warn("SchemaPatches: không gỡ được ràng buộc {}.{}: {}", c[0], c[1], e.getMessage());
            }
        }
    }
}

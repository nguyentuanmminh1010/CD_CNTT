package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Quyền quản trị nội dung: email của user nằm trong {@code app.admin-emails}
 * (danh sách phân tách bằng dấu phẩy, đặt qua env ADMIN_EMAILS hoặc
 * application-local.properties). Chưa có bảng role riêng — đủ cho giai đoạn dev. */
@Component
public class AdminGuard {

    private final Set<String> adminEmails;
    private final UserRepository userRepository;

    public AdminGuard(@Value("${app.admin-emails:}") String adminEmails, UserRepository userRepository) {
        this.adminEmails = Arrays.stream(adminEmails.split(","))
                .map(s -> s.trim().toLowerCase())
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());
        this.userRepository = userRepository;
    }

    public boolean isAdmin(User user) {
        return user != null && user.getEmail() != null
                && adminEmails.contains(user.getEmail().trim().toLowerCase());
    }

    /** Ném lỗi nếu userId không phải admin. */
    public void require(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập.");
        }
        User user = userRepository.findById(userId).orElse(null);
        if (!isAdmin(user)) {
            throw new IllegalStateException("Bạn không có quyền quản trị nội dung.");
        }
    }
}

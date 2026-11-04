package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.NotificationRead;
import com.nguyentuanminh.e_app.repository.NotificationReadRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.util.HashSet;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Ghi nhớ thông báo nào người dùng đã đọc (nội dung thông báo do client suy ra từ dữ liệu thật). */
@Service
@RequiredArgsConstructor
public class NotificationService {

    private static final int MAX_KEYS_PER_CALL = 100;

    private final NotificationReadRepository readRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<String> readKeys(Long userId) {
        requireUser(userId);
        return readRepository.findKeysByUserId(userId);
    }

    @Transactional
    public boolean markRead(Long userId, List<String> keys) {
        requireUser(userId);
        if (keys == null || keys.isEmpty()) {
            return true;
        }
        var user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        Set<String> existing = new HashSet<>(readRepository.findKeysByUserId(userId));
        keys.stream()
                .filter(k -> k != null && !k.isBlank())
                .map(k -> k.trim().length() > 120 ? k.trim().substring(0, 120) : k.trim())
                .distinct()
                .limit(MAX_KEYS_PER_CALL)
                .filter(existing::add)
                .forEach(k -> {
                    NotificationRead n = new NotificationRead();
                    n.setUser(user);
                    n.setNotificationKey(k);
                    readRepository.save(n);
                });
        return true;
    }

    private static void requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập.");
        }
    }
}

package com.nguyentuanminh.e_app.service;

import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Giới hạn tần suất theo cửa sổ trượt, lưu trong bộ nhớ của một instance (đủ cho dev/1 máy chủ;
 * nhiều instance thì cần Redis hoặc tương đương). Dùng cho đăng nhập sai, yêu cầu đặt lại mật khẩu,
 * và gửi câu trả lời (chặn việc dò đáp án tự động).
 */
@Component
public class RateLimiter {

    private static final int CLEANUP_THRESHOLD = 5_000;

    private final Map<String, Deque<Long>> hits = new ConcurrentHashMap<>();

    /** Ghi một lần và ném lỗi nếu đã quá [max] lần trong [window]. */
    public void hitOrThrow(String key, int max, Duration window, String message) {
        assertBelow(key, max, window, message);
        hit(key);
    }

    /** Ném lỗi nếu số lần ghi nhận của [key] trong [window] đã đạt [max] (không ghi thêm). */
    public void assertBelow(String key, int max, Duration window, String message) {
        if (count(key, window) >= max) {
            throw new IllegalStateException(message);
        }
    }

    public void hit(String key) {
        Deque<Long> q = hits.computeIfAbsent(key, k -> new ArrayDeque<>());
        synchronized (q) {
            q.addLast(System.currentTimeMillis());
        }
        if (hits.size() > CLEANUP_THRESHOLD) {
            hits.entrySet().removeIf(e -> {
                synchronized (e.getValue()) {
                    return e.getValue().isEmpty()
                            || e.getValue().peekLast() < System.currentTimeMillis() - Duration.ofHours(1).toMillis();
                }
            });
        }
    }

    public void reset(String key) {
        hits.remove(key);
    }

    private int count(String key, Duration window) {
        Deque<Long> q = hits.get(key);
        if (q == null) return 0;
        long cutoff = System.currentTimeMillis() - window.toMillis();
        synchronized (q) {
            while (!q.isEmpty() && q.peekFirst() < cutoff) {
                q.pollFirst();
            }
            return q.size();
        }
    }
}

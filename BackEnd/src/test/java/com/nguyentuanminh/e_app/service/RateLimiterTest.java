package com.nguyentuanminh.e_app.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.nguyentuanminh.e_app.domain.LearningItem;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class RateLimiterTest {

    @Test
    void blocksAfterMaxHitsAndIsolatesKeys() {
        RateLimiter limiter = new RateLimiter();
        for (int i = 0; i < 3; i++) {
            limiter.hitOrThrow("a", 3, Duration.ofMinutes(1), "too fast");
        }
        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> limiter.hitOrThrow("a", 3, Duration.ofMinutes(1), "too fast"));
        assertEquals("too fast", e.getMessage());
        // khoá khác không bị ảnh hưởng
        assertDoesNotThrow(() -> limiter.hitOrThrow("b", 3, Duration.ofMinutes(1), "too fast"));
    }

    @Test
    void resetClearsFailuresAndOldHitsExpire() throws InterruptedException {
        RateLimiter limiter = new RateLimiter();
        limiter.hit("login:x");
        limiter.hit("login:x");
        assertThrows(IllegalStateException.class,
                () -> limiter.assertBelow("login:x", 2, Duration.ofMinutes(15), "locked"));
        limiter.reset("login:x");
        assertDoesNotThrow(() -> limiter.assertBelow("login:x", 2, Duration.ofMinutes(15), "locked"));

        limiter.hit("short");
        Thread.sleep(60);
        // lần ghi cũ nằm ngoài cửa sổ 30ms nên không còn tính
        assertDoesNotThrow(() -> limiter.assertBelow("short", 1, Duration.ofMillis(30), "locked"));
    }

    @Test
    void explanationFallsBackToMeaningAndExample() {
        LearningItem item = new LearningItem();
        item.setTerm("apple");
        item.setMeaning("quả táo");
        assertEquals("\"apple\" — quả táo", AttemptService.explanationOf(item));
        item.setExample("I eat an apple");
        assertEquals("\"apple\" — quả táo\nVí dụ: I eat an apple", AttemptService.explanationOf(item));
        item.setExplanation("Danh từ đếm được.");
        assertEquals("Danh từ đếm được.", AttemptService.explanationOf(item));
    }
}

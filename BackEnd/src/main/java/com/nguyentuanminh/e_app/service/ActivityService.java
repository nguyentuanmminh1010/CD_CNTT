package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.domain.UserActivityDay;
import com.nguyentuanminh.e_app.repository.UserActivityDayRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ghi nhận và tổng hợp hoạt động học theo ngày của người dùng — nguồn dữ liệu
 * cho chuỗi ngày học ("Chuỗi học" ở Home) và tab Tiến độ. Không phải bảng
 * tracking riêng cho từng loại bài; một ngày được coi là "có hoạt động" hễ
 * người dùng gọi bất kỳ mutation {@code mark*ItemMastered} nào (Flashcard,
 * Trắc nghiệm, Ôn tập, Luyện thi TOEIC).
 */
@Service
@RequiredArgsConstructor
public class ActivityService {

    private final UserActivityDayRepository repository;
    private final UserRepository userRepository;

    @Transactional
    public void recordActivityToday(Long userId) {
        if (userId == null) return;
        LocalDate today = LocalDate.now();
        UserActivityDay day = repository
                .findByUserIdAndActivityDate(userId, today)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
                    UserActivityDay created = new UserActivityDay();
                    created.setUser(user);
                    created.setActivityDate(today);
                    return created;
                });
        day.setItemsCompleted(day.getItemsCompleted() + 1);
        repository.save(day);
    }

    @Transactional(readOnly = true)
    public ActivitySummary getSummary(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem tiến độ.");
        }
        List<UserActivityDay> days = repository.findByUserIdOrderByActivityDateDesc(userId);
        int totalItemsCompleted = days.stream().mapToInt(UserActivityDay::getItemsCompleted).sum();
        return new ActivitySummary(computeStreak(days), days.size(), totalItemsCompleted, days);
    }

    /** Số ngày liên tiếp có hoạt động tính đến hôm nay (hoặc hôm qua nếu hôm
     * nay chưa học — chuỗi coi như vẫn còn "sống" tới hết ngày hôm nay). */
    private int computeStreak(List<UserActivityDay> daysDesc) {
        if (daysDesc.isEmpty()) return 0;
        Set<LocalDate> dates = new HashSet<>();
        for (UserActivityDay day : daysDesc) dates.add(day.getActivityDate());

        LocalDate cursor = LocalDate.now();
        if (!dates.contains(cursor)) {
            cursor = cursor.minusDays(1);
            if (!dates.contains(cursor)) return 0;
        }
        int streak = 0;
        while (dates.contains(cursor)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }
}

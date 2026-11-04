package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.UserActivityDay;
import java.util.List;

/** Tổng hợp hoạt động học của một người dùng — dữ liệu cho tab Tiến độ. */
public record ActivitySummary(
        int currentStreak,
        int totalActiveDays,
        int totalItemsCompleted,
        List<UserActivityDay> recentDays) {
}

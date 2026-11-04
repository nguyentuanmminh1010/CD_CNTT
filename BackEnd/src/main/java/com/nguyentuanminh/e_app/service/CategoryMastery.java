package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.LearningCategory;

/** Tổng số mục và số mục đã thuộc của MỘT category — dùng vẽ radar chart theo mảng ở Hồ sơ. */
public record CategoryMastery(LearningCategory category, int totalItems, int masteredItems) {
}

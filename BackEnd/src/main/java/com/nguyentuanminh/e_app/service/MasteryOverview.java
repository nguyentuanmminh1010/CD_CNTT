package com.nguyentuanminh.e_app.service;

/** Tổng số mục nội dung (mọi category) và số mục người dùng đã thuộc — dùng
 * cho tiến độ "Ôn thi TOEIC" ở Home và luyện tập thích ứng theo trình độ. */
public record MasteryOverview(int totalItems, int masteredItems) {
}

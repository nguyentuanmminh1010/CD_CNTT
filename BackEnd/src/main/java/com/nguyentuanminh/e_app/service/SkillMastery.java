package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.Skill;

/** Tổng số lượt luyện tập + số lượt đúng của MỘT kỹ năng — dùng vẽ radar chart
 * 4 kỹ năng ở Hồ sơ. `totalAttempts == 0` khi người dùng chưa luyện kỹ năng đó
 * (vd Nghe/Nói khi chưa có bài tập cho 2 kỹ năng này). */
public record SkillMastery(Skill skill, int totalAttempts, int correctAttempts) {
}

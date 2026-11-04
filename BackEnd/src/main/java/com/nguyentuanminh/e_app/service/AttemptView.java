package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.Attempt;
import com.nguyentuanminh.e_app.domain.AttemptType;

public record AttemptView(
        Long id,
        AttemptType type,
        String title,
        int totalQuestions,
        int correctCount,
        int scorePercent,
        String refKey,
        String createdAt) {

    public static AttemptView of(Attempt a) {
        int percent = a.getTotalQuestions() == 0
                ? 0
                : Math.round(a.getCorrectCount() * 100f / a.getTotalQuestions());
        return new AttemptView(a.getId(), a.getType(), a.getTitle(), a.getTotalQuestions(),
                a.getCorrectCount(), percent, a.getRefKey(), a.getCreatedAt().toString());
    }
}

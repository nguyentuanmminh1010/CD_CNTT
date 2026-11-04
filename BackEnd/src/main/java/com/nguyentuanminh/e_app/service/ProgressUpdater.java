package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.domain.UserLearningItemProgress;
import com.nguyentuanminh.e_app.domain.UserTopicMastery;
import com.nguyentuanminh.e_app.repository.UserLearningItemProgressRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import com.nguyentuanminh.e_app.repository.UserTopicMasteryRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Điểm DUY NHẤT cập nhật tiến độ sau mỗi lần trả lời một mục (đúng/sai hay "đã thuộc/cần
 * ôn" ở Flashcard): trạng thái đã thuộc, hộp lặp lại ngắt quãng (Leitner), điểm mastery theo
 * chủ đề và "hoạt động hôm nay" (chuỗi ngày học).
 */
@Component
@RequiredArgsConstructor
public class ProgressUpdater {

    /** Khoảng cách ôn lại theo hộp 1..5 (ngày): đúng càng nhiều lần thì càng lâu mới phải ôn. */
    private static final int[] BOX_INTERVAL_DAYS = {1, 2, 4, 8, 16};
    private static final int MAX_BOX = BOX_INTERVAL_DAYS.length;
    /** Hệ số trung bình trượt mũ của mastery: mỗi câu kéo điểm 25% về phía kết quả (1 hoặc 0). */
    private static final double MASTERY_ALPHA = 0.25;

    private final UserLearningItemProgressRepository progressRepository;
    private final UserTopicMasteryRepository masteryRepository;
    private final UserRepository userRepository;
    private final ActivityService activityService;

    @Transactional
    public UserLearningItemProgress record(Long userId, LearningItem item, boolean correct) {
        Instant now = Instant.now();
        UserLearningItemProgress progress = progressRepository
                .findByUserIdAndItemId(userId, item.getId())
                .orElseGet(() -> {
                    UserLearningItemProgress created = new UserLearningItemProgress();
                    created.setUser(requireUser(userId));
                    created.setItem(item);
                    return created;
                });

        boolean wasMastered = progress.isMastered();
        progress.setMastered(correct);
        progress.setReviewCount(progress.getReviewCount() + 1);
        progress.setLastReviewedAt(now);
        if (correct) {
            int box = Math.min(progress.getBox() + 1, MAX_BOX);
            progress.setBox(box);
            progress.setNextReviewAt(now.plus(Duration.ofDays(BOX_INTERVAL_DAYS[box - 1])));
            if (!wasMastered || progress.getMasteredAt() == null) {
                progress.setMasteredAt(now);
            }
        } else {
            progress.setBox(0);
            progress.setNextReviewAt(now); // sai thì đến hạn ôn ngay
            progress.setMasteredAt(null);
        }
        progressRepository.save(progress);

        updateTopicMastery(userId, item, correct);
        activityService.recordActivityToday(userId);
        return progress;
    }

    private void updateTopicMastery(Long userId, LearningItem item, boolean correct) {
        UserTopicMastery mastery = masteryRepository
                .findByUserIdAndTopicId(userId, item.getTopic().getId())
                .orElseGet(() -> {
                    UserTopicMastery created = new UserTopicMastery();
                    created.setUser(requireUser(userId));
                    created.setTopic(item.getTopic());
                    return created;
                });
        double target = correct ? 1.0 : 0.0;
        mastery.setScore(mastery.getScore() + MASTERY_ALPHA * (target - mastery.getScore()));
        mastery.setAnswers(mastery.getAnswers() + 1);
        masteryRepository.save(mastery);
    }

    private User requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
    }
}

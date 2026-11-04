package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.AnswerMode;
import com.nguyentuanminh.e_app.domain.Attempt;
import com.nguyentuanminh.e_app.domain.AttemptAnswer;
import com.nguyentuanminh.e_app.domain.AttemptType;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.AttemptAnswerRepository;
import com.nguyentuanminh.e_app.repository.AttemptRepository;
import com.nguyentuanminh.e_app.repository.CourseUnitRepository;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.util.HashSet;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lịch sử các lượt làm bài hoàn chỉnh. Điểm của một lượt được TÍNH Ở BACKEND từ các
 * {@link AttemptAnswer} đã chấm có cùng {@code attemptKey} — client không gửi được số câu đúng.
 */
@Service
@RequiredArgsConstructor
public class AttemptService {

    /** Một câu của lượt làm bài để xem lại đáp án. */
    public record AnswerView(
            Long itemId, String term, String meaning, String mode, String answer,
            boolean correct, String correctAnswer, String explanation, String imageUrl) {
    }

    private final AttemptRepository attemptRepository;
    private final AttemptAnswerRepository answerRepository;
    private final UserRepository userRepository;
    private final CourseUnitRepository unitRepository;
    private final LearningItemRepository itemRepository;

    /** Số câu của một Level Test (khớp với `levelTestQuestionCount` ở client). */
    static final int LEVEL_TEST_SIZE = 12;

    /**
     * Kết thúc một lượt: gom các câu trả lời theo [attemptKey] thành một {@link Attempt}.
     * [expectedTotal] là số câu của đề — nếu client bỏ bớt câu sai thì tổng vẫn không nhỏ hơn đó,
     * nên không thể "thổi" điểm bằng cách chỉ gửi câu đúng. Idempotent theo (user, attemptKey).
     */
    @Transactional
    public AttemptView finish(
            Long userId, String attemptKey, AttemptType type, String title, String refKey, Integer expectedTotal) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để lưu kết quả bài làm.");
        }
        if (attemptKey == null || attemptKey.isBlank()) {
            throw new IllegalArgumentException("Thiếu attemptKey.");
        }
        String key = attemptKey.trim();
        var existing = attemptRepository.findByUserIdAndAttemptKey(userId, key);
        if (existing.isPresent()) {
            return AttemptView.of(existing.get());
        }
        List<AttemptAnswer> answers = answerRepository.findByUserIdAndAttemptKeyOrderByIdAsc(userId, key);
        int minTotal = expectedTotal == null ? 0 : expectedTotal;
        if (refKey != null && refKey.trim().startsWith("level:")) {
            minTotal = Math.max(minTotal, checkLevelTest(refKey.trim(), answers));
        }
        int total = Math.max(answers.size(), minTotal);
        if (answers.isEmpty() || total <= 0) {
            throw new IllegalArgumentException("Lượt làm bài chưa có câu trả lời nào.");
        }
        int correct = (int) answers.stream().filter(AttemptAnswer::isCorrect).count();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(type);
        attempt.setTitle(title == null || title.isBlank() ? type.name() : title.trim());
        attempt.setTotalQuestions(total);
        attempt.setCorrectCount(correct);
        attempt.setRefKey(refKey == null || refKey.isBlank() ? null : refKey.trim());
        attempt.setAttemptKey(key);
        return AttemptView.of(attemptRepository.save(attempt));
    }

    /**
     * Level Test (refKey {@code level:{courseId}:{level}}): chỉ chấp nhận câu thuộc các chủ đề của đúng Level đó
     * (không thể "đạt" bằng cách trả lời mục dễ ở nơi khác) và luôn tính đủ [LEVEL_TEST_SIZE] câu
     * (hoặc toàn bộ mục của Level nếu ít hơn). Trả về số câu tối thiểu của đề.
     */
    private int checkLevelTest(String refKey, List<AttemptAnswer> answers) {
        String[] parts = refKey.split(":");
        long courseId;
        int level;
        try {
            courseId = Long.parseLong(parts[1]);
            level = Integer.parseInt(parts[2]);
        } catch (RuntimeException e) {
            throw new IllegalArgumentException("refKey Level Test không hợp lệ.");
        }
        Set<Long> topicIds = new HashSet<>();
        unitRepository.findByCourseIdOrderByLevelAscPositionAsc(courseId).stream()
                .filter(u -> u.getLevel() == level)
                .forEach(u -> topicIds.add(u.getTopic().getId()));
        if (topicIds.isEmpty()) {
            throw new IllegalArgumentException("Level Test không tồn tại.");
        }
        for (AttemptAnswer a : answers) {
            if (!topicIds.contains(a.getItem().getTopic().getId())) {
                throw new IllegalArgumentException("Có câu trả lời không thuộc Level Test này.");
            }
        }
        long available = topicIds.stream().mapToLong(itemRepository::countByTopicId).sum();
        return (int) Math.min(LEVEL_TEST_SIZE, available);
    }

    @Transactional(readOnly = true)
    public List<AttemptView> list(Long userId, int limit) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem lịch sử bài làm.");
        }
        return attemptRepository
                .findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, Math.max(1, limit)))
                .stream()
                .map(AttemptView::of)
                .toList();
    }

    /** Chi tiết từng câu của một lượt (đáp án đã chọn vs đáp án đúng) — màn "xem lại đáp án". */
    @Transactional(readOnly = true)
    public List<AnswerView> answers(Long userId, Long attemptId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem lại bài làm.");
        }
        Attempt attempt = attemptRepository.findById(attemptId)
                .filter(a -> a.getUser().getId().equals(userId))
                .orElseThrow(() -> new NoSuchElementException("Attempt not found: " + attemptId));
        if (attempt.getAttemptKey() == null) {
            return List.of();
        }
        return answerRepository.findByUserIdAndAttemptKeyOrderByIdAsc(userId, attempt.getAttemptKey())
                .stream()
                .map(a -> new AnswerView(
                        a.getItem().getId(), a.getItem().getTerm(), a.getItem().getMeaning(),
                        a.getMode().name(), a.getAnswer(), a.isCorrect(),
                        AnswerService.correctAnswerOf(a.getItem(), a.getMode()),
                        explanationOf(a.getItem()), a.getItem().getImageUrl()))
                .toList();
    }

    /** Lời giải thích của mục; chưa có thì sinh từ nghĩa + ví dụ để màn xem lại luôn có chữ giải thích. */
    static String explanationOf(com.nguyentuanminh.e_app.domain.LearningItem item) {
        if (item.getExplanation() != null && !item.getExplanation().isBlank()) {
            return item.getExplanation();
        }
        String text = "\"" + item.getTerm() + "\" — " + item.getMeaning();
        if (item.getExample() != null && !item.getExample().isBlank()) {
            text += "\nVí dụ: " + item.getExample();
        }
        return text;
    }
}

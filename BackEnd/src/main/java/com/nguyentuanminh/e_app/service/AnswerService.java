package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.AnswerMode;
import com.nguyentuanminh.e_app.domain.AttemptAnswer;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.Skill;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.AttemptAnswerRepository;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Chấm điểm câu trả lời Ở BACKEND (client chỉ gửi câu trả lời, không gửi "đúng/sai"): so với
 * đáp án của {@link LearningItem} theo {@link AnswerMode}, lưu lại {@link AttemptAnswer}, rồi
 * cập nhật tiến độ ({@link ProgressUpdater}) và thống kê kỹ năng nếu có.
 */
@Service
@RequiredArgsConstructor
public class AnswerService {

    /** Giới hạn số câu trả lời gửi lên mỗi phút của một người dùng. */
    static final int MAX_ANSWERS_PER_MINUTE = 120;

    public record AnswerResult(boolean correct, String correctAnswer, double similarity) {
    }

    private final LearningItemRepository itemRepository;
    private final AttemptAnswerRepository answerRepository;
    private final UserRepository userRepository;
    private final ProgressUpdater progressUpdater;
    private final SkillService skillService;
    private final LearningService learningService;
    private final RateLimiter rateLimiter;

    @Transactional
    public AnswerResult submit(
            Long userId, Long itemId, AnswerMode mode, String answer, String attemptKey, Skill skill) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để làm bài.");
        }
        // Chặn script dò đáp án hàng loạt: người làm bài thật hiếm khi trả lời quá ~1 câu/giây liên tục.
        rateLimiter.hitOrThrow("answer:" + userId, MAX_ANSWERS_PER_MINUTE, java.time.Duration.ofMinutes(1),
                "Bạn gửi câu trả lời quá nhanh. Hãy chậm lại một chút.");
        LearningItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new NoSuchElementException("LearningItem not found: " + itemId));
        learningService.requireVisible(item.getTopic(), userId);

        String given = answer == null ? "" : answer.trim();
        double similarity = mode == AnswerMode.SPOKEN ? SpeechMatcher.similarity(given, item.getTerm()) : 0;
        boolean correct = switch (mode) {
            case MEANING -> given.equals(item.getMeaning().trim());
            case TERM -> !given.isEmpty()
                    && SpeechMatcher.normalizeTyped(given).equals(SpeechMatcher.normalizeTyped(item.getTerm()));
            case SENTENCE -> !given.isEmpty() && sameWords(given, sentenceOf(item));
            case SPOKEN -> similarity >= SpeechMatcher.PASS_RATIO;
        };

        String key = attemptKey == null || attemptKey.isBlank() ? null : attemptKey.trim();
        // Mỗi mục chỉ được chấm MỘT lần trong một lượt: gửi lại thì trả kết quả cũ (không thử-sai-để-dò đáp án,
        // không cộng thêm điểm). Ngoại lệ: luyện nói cho "Nói lại" — chỉ nâng một câu sai thành đúng.
        if (key != null) {
            var previous = answerRepository.findFirstByUserIdAndAttemptKeyAndItemId(userId, key, itemId);
            if (previous.isPresent()) {
                AttemptAnswer old = previous.get();
                if (mode == AnswerMode.SPOKEN && old.getMode() == AnswerMode.SPOKEN && !old.isCorrect() && correct) {
                    old.setAnswer(given.length() > 1000 ? given.substring(0, 1000) : given);
                    old.setCorrect(true);
                    answerRepository.save(old);
                    progressUpdater.record(userId, item, true);
                    if (skill != null) {
                        skillService.recordAttempt(userId, skill, true);
                    }
                    return new AnswerResult(true, correctAnswerOf(item, mode), similarity);
                }
                return new AnswerResult(old.isCorrect(), correctAnswerOf(item, old.getMode()),
                        old.getMode() == AnswerMode.SPOKEN ? SpeechMatcher.similarity(old.getAnswer(), item.getTerm()) : 0);
            }
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        AttemptAnswer saved = new AttemptAnswer();
        saved.setUser(user);
        saved.setItem(item);
        saved.setMode(mode);
        saved.setAnswer(given.length() > 1000 ? given.substring(0, 1000) : given);
        saved.setCorrect(correct);
        saved.setAttemptKey(key);
        answerRepository.save(saved);

        progressUpdater.record(userId, item, correct);
        if (skill != null) {
            skillService.recordAttempt(userId, skill, correct);
        }
        return new AnswerResult(correct, correctAnswerOf(item, mode), similarity);
    }

    public static String correctAnswerOf(LearningItem item, AnswerMode mode) {
        return switch (mode) {
            case MEANING -> item.getMeaning();
            case TERM, SPOKEN -> item.getTerm();
            case SENTENCE -> sentenceOf(item);
        };
    }

    /** Câu dùng cho bài Sắp xếp: câu ví dụ (mục không có ví dụ thì dùng chính {@code term}). */
    private static String sentenceOf(LearningItem item) {
        return item.getExample() != null && !item.getExample().isBlank() ? item.getExample() : item.getTerm();
    }

    /** So khớp từng từ theo đúng thứ tự (cả hai phía cùng tách theo khoảng trắng, như bộ sinh đề ở client). */
    private static boolean sameWords(String a, String b) {
        return java.util.Arrays.equals(a.trim().split("\\s+"), b.trim().split("\\s+"));
    }
}

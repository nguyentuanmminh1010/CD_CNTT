package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.domain.UserLearningItemProgress;
import com.nguyentuanminh.e_app.domain.UserTopicMastery;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import com.nguyentuanminh.e_app.repository.UserLearningItemProgressRepository;
import com.nguyentuanminh.e_app.repository.UserTopicMasteryRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Nghiệp vụ dùng chung cho cả 3 mảng nội dung Vocabulary/Grammar/Sentence — chỉ khác nhau ở
 * {@link LearningCategory} lọc chủ đề. Xem CLAUDE.md > Kiến trúc Backend để biết vì sao gộp
 * chung thay vì 3 bộ entity/service riêng.
 *
 * <p>Chủ đề có {@code owner} là "bộ thẻ" riêng của một người dùng: chỉ chủ sở hữu thấy
 * ({@link #requireVisible}) và không tính vào kho chung (đề thi, tiến độ, xếp hạng).
 */
@Service
@RequiredArgsConstructor
public class LearningService {

    /** Mastery dưới ngưỡng này ⇒ ưu tiên câu dễ (1); dưới ngưỡng kế ⇒ câu vừa (2); còn lại ⇒ câu khó (3). */
    static final double EASY_BELOW = 0.45;
    static final double MEDIUM_BELOW = 0.75;

    /** Gợi ý: một chủ đề kèm điểm mastery của người dùng và độ khó nên luyện. */
    public record RecommendedTopic(
            LearningTopic topic, double score, int suggestedDifficulty, int totalItems, int masteredItems) {
    }

    private final LearningTopicRepository topicRepository;
    private final LearningItemRepository itemRepository;
    private final UserLearningItemProgressRepository progressRepository;
    private final UserTopicMasteryRepository masteryRepository;
    private final ProgressUpdater progressUpdater;

    @Transactional(readOnly = true)
    public List<LearningTopic> getTopics(LearningCategory category, Long userId) {
        return topicRepository.findVisible(category, userId);
    }

    public long countItemsInTopic(Long topicId) {
        return itemRepository.countByTopicId(topicId);
    }

    /** Chặn truy cập vào bộ thẻ riêng của người khác. */
    public void requireVisible(LearningTopic topic, Long userId) {
        if (topic.getOwner() != null && (userId == null || !topic.getOwner().getId().equals(userId))) {
            throw new NoSuchElementException("Topic not found: " + topic.getId());
        }
    }

    /**
     * @param expectedCategory chủ đề của category nào (vd GRAMMAR) — chặn việc lỡ truyền nhầm
     *                         topicId của category khác (vd gọi grammarItems với topicId của Vocabulary).
     */
    @Transactional(readOnly = true)
    public List<LearningItem> getItems(Long topicId, LearningCategory expectedCategory, Long userId) {
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        requireVisible(topic, userId);
        if (topic.getCategory() != expectedCategory) {
            throw new IllegalArgumentException(
                    "topicId " + topicId + " không thuộc mảng " + expectedCategory + ".");
        }
        return itemRepository.findByTopicIdOrderByDifficultyLevelAscIdAsc(topicId);
    }

    /** Các mục người dùng trả lời sai/đánh dấu chưa thuộc gần nhất — dữ liệu cho "Ôn tập lỗi sai". */
    @Transactional(readOnly = true)
    public List<LearningItem> getWrongItems(Long userId) {
        requireUser(userId, "Bạn cần đăng nhập để xem danh sách Ôn tập.");
        return progressRepository
                .findByUserIdAndMasteredFalseOrderByLastReviewedAtDesc(userId)
                .stream()
                .map(UserLearningItemProgress::getItem)
                .toList();
    }

    /** Các mục đến hạn ôn lại theo lịch lặp lại ngắt quãng (Leitner). */
    @Transactional(readOnly = true)
    public List<LearningItem> getDueItems(Long userId, int limit) {
        requireUser(userId, "Bạn cần đăng nhập để xem danh sách Ôn tập.");
        return progressRepository.findDue(userId, Instant.now(), PageRequest.of(0, Math.max(1, limit)))
                .stream()
                .map(UserLearningItemProgress::getItem)
                .toList();
    }

    @Transactional(readOnly = true)
    public int countDueItems(Long userId) {
        requireUser(userId, "Bạn cần đăng nhập để xem danh sách Ôn tập.");
        return (int) progressRepository.countDue(userId, Instant.now());
    }

    /** userId null (chưa đăng nhập) -> luôn coi như chưa thuộc. */
    @Transactional(readOnly = true)
    public boolean isMastered(Long userId, Long itemId) {
        if (userId == null) return false;
        return progressRepository.findByUserIdAndItemId(userId, itemId)
                .map(UserLearningItemProgress::isMastered)
                .orElse(false);
    }

    /** Tự đánh giá "đã thuộc/cần ôn" ở Flashcard (không chấm điểm) — cập nhật tiến độ như mọi lần trả lời. */
    @Transactional
    public LearningItem markMastered(Long userId, Long itemId, boolean mastered) {
        requireUser(userId, "Bạn cần đăng nhập để lưu tiến độ học.");
        LearningItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new NoSuchElementException("LearningItem not found: " + itemId));
        requireVisible(item.getTopic(), userId);
        progressUpdater.record(userId, item, mastered);
        return item;
    }

    /** Tổng mục kho chung và số mục người dùng đã thuộc — tiến độ "Ôn thi TOEIC" ở Home. */
    @Transactional(readOnly = true)
    public MasteryOverview getMasteryOverview(Long userId) {
        requireUser(userId, "Bạn cần đăng nhập để xem tiến độ.");
        long total = itemRepository.countByTopicOwnerIsNull();
        long mastered = progressRepository.countByUserIdAndMasteredTrueAndItemTopicOwnerIsNull(userId);
        return new MasteryOverview((int) total, (int) mastered);
    }

    /** Tổng mục và số mục đã thuộc CỦA TỪNG category (kho chung) — radar chart/biểu đồ tròn ở Hồ sơ. */
    @Transactional(readOnly = true)
    public List<CategoryMastery> getMasteryByCategory(Long userId) {
        requireUser(userId, "Bạn cần đăng nhập để xem tiến độ.");
        return Arrays.stream(LearningCategory.values())
                .map(category -> new CategoryMastery(
                        category,
                        (int) itemRepository.countByTopicOwnerIsNullAndTopicCategory(category),
                        (int) progressRepository
                                .countByUserIdAndMasteredTrueAndItemTopicCategoryAndItemTopicOwnerIsNull(
                                        userId, category)))
                .toList();
    }

    /** Tìm kiếm trong kho chung + bộ thẻ của chính người tìm. Chuỗi rỗng trả về danh sách rỗng. */
    @Transactional(readOnly = true)
    public List<LearningItem> searchItems(String query, int limit, Long userId) {
        if (query == null || query.trim().isEmpty()) {
            return List.of();
        }
        return itemRepository.searchByTermOrMeaning(query.trim(), userId, PageRequest.of(0, limit));
    }

    /** Đề cho một bài test ở tab Đánh giá: ngẫu nhiên [limit] mục kho chung theo category và độ khó. */
    @Transactional(readOnly = true)
    public List<LearningItem> getAssessmentItems(
            LearningCategory category, int minDifficulty, int maxDifficulty, int limit) {
        List<LearningItem> pool = new ArrayList<>(category == null
                ? itemRepository.findByTopicOwnerIsNullAndDifficultyLevelBetween(minDifficulty, maxDifficulty)
                : itemRepository.findByTopicOwnerIsNullAndTopicCategoryAndDifficultyLevelBetween(
                        category, minDifficulty, maxDifficulty));
        Collections.shuffle(pool);
        return pool.stream().limit(Math.max(1, limit)).toList();
    }

    /**
     * Đề luyện thi THÍCH ỨNG: các mục chưa thuộc, ưu tiên mục có độ khó khớp với mastery của
     * người dùng ở chủ đề đó (mastery thấp → câu dễ, cao → câu khó), rồi ưu tiên chủ đề yếu nhất.
     */
    @Transactional(readOnly = true)
    public List<LearningItem> getToeicPracticeItems(Long userId, int limit) {
        requireUser(userId, "Bạn cần đăng nhập để luyện tập.");
        Map<Long, Double> scores = masteryScores(userId);
        return itemRepository.findUnmasteredForUser(userId).stream()
                .sorted(Comparator
                        .comparingInt((LearningItem li) -> Math.abs(
                                li.getDifficultyLevel() - difficultyFor(scoreOf(scores, li.getTopic().getId()))))
                        .thenComparingDouble(li -> scoreOf(scores, li.getTopic().getId()))
                        .thenComparingLong(LearningItem::getId))
                .limit(Math.max(1, limit))
                .toList();
    }

    /** Chủ đề nên luyện tiếp: điểm mastery thấp nhất trong số chủ đề (hệ thống + của bạn) còn mục chưa thuộc. */
    @Transactional(readOnly = true)
    public List<RecommendedTopic> getRecommendedTopics(Long userId, int limit) {
        requireUser(userId, "Bạn cần đăng nhập để xem gợi ý.");
        Map<Long, Double> scores = masteryScores(userId);
        List<RecommendedTopic> all = new ArrayList<>();
        for (LearningCategory category : LearningCategory.values()) {
            for (LearningTopic topic : topicRepository.findVisible(category, userId)) {
                if (topic.getOwner() != null) continue; // gợi ý chỉ trong kho chung
                int total = (int) itemRepository.countByTopicId(topic.getId());
                int mastered = (int) progressRepository
                        .countByUserIdAndMasteredTrueAndItemTopicId(userId, topic.getId());
                if (total == 0 || mastered >= total) continue;
                double score = scoreOf(scores, topic.getId());
                all.add(new RecommendedTopic(topic, score, difficultyFor(score), total, mastered));
            }
        }
        all.sort(Comparator.comparingDouble(RecommendedTopic::score)
                .thenComparingInt(r -> r.masteredItems() * -1)
                .thenComparingLong(r -> r.topic().getId()));
        return all.stream().limit(Math.max(1, limit)).toList();
    }

    static int difficultyFor(double mastery) {
        return mastery < EASY_BELOW ? 1 : mastery < MEDIUM_BELOW ? 2 : 3;
    }

    private Map<Long, Double> masteryScores(Long userId) {
        Map<Long, Double> scores = new HashMap<>();
        for (UserTopicMastery m : masteryRepository.findByUserId(userId)) {
            scores.put(m.getTopic().getId(), m.getScore());
        }
        return scores;
    }

    private static double scoreOf(Map<Long, Double> scores, Long topicId) {
        return scores.getOrDefault(topicId, UserTopicMastery.INITIAL_SCORE);
    }

    private static void requireUser(Long userId, String message) {
        if (userId == null) {
            throw new IllegalStateException(message);
        }
    }
}

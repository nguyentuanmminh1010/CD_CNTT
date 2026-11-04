package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.Attempt;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.AttemptRepository;
import com.nguyentuanminh.e_app.repository.UserCourseEnrollmentRepository;
import com.nguyentuanminh.e_app.repository.UserLearningItemProgressRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Bảng xếp hạng và thành tựu — cả hai đều tổng hợp lúc query từ dữ liệu đã có (số mục kho chung
 * đã thuộc, chuỗi ngày, lịch sử bài làm), không lưu bảng riêng. */
@Service
@RequiredArgsConstructor
public class RankingService {

    /** Phạm vi xếp hạng: ALL = mọi người; WEEK = mục thuộc trong 7 ngày qua; FRIENDS = bạn bè + mình. */
    public enum Period { ALL, WEEK, FRIENDS }

    public record LeaderboardEntry(int rank, Long userId, String displayName, int score, boolean me, String avatar) {
    }

    public record Achievement(
            String code, String title, String description,
            int tier, int maxTier, int current, int nextTarget) {
    }

    private final UserLearningItemProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final ActivityService activityService;
    private final UserCourseEnrollmentRepository enrollmentRepository;
    private final UserRepository userRepository;
    private final FriendService friendService;

    /** Điểm xếp hạng = số mục KHO CHUNG đã thuộc (bộ thẻ riêng không tính — tránh tự tạo thẻ lấy điểm). */
    @Transactional(readOnly = true)
    public List<LeaderboardEntry> leaderboard(Long userId, int limit, Period period) {
        requireUser(userId);
        List<LeaderboardEntry> top = rankAll(userId, period).stream().limit(Math.max(1, limit)).toList();
        return withAvatars(top);
    }

    /** Vị trí của chính người dùng — kể cả khi chưa thuộc mục nào (điểm 0, xếp cuối). */
    @Transactional(readOnly = true)
    public LeaderboardEntry myRank(Long userId, Period period) {
        requireUser(userId);
        List<LeaderboardEntry> all = rankAll(userId, period);
        LeaderboardEntry mine = all.stream().filter(LeaderboardEntry::me).findFirst().orElse(null);
        if (mine != null) {
            return withAvatars(List.of(mine)).get(0);
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        return new LeaderboardEntry(all.size() + 1, userId, user.getDisplayName(), 0, true, user.getAvatar());
    }

    private List<LeaderboardEntry> rankAll(Long userId, Period period) {
        List<Object[]> rows = period == Period.WEEK
                ? progressRepository.rankByMasteredCountSince(Instant.now().minus(Duration.ofDays(7)))
                : progressRepository.rankByMasteredCount();

        Set<Long> allowed = null;
        if (period == Period.FRIENDS) {
            allowed = new HashSet<>(friendService.friendIds(userId));
            allowed.add(userId);
        }
        // Với FRIENDS, bạn chưa thuộc mục nào cũng phải có mặt (điểm 0) để bảng không bị trống.
        List<Object[]> filtered = new ArrayList<>();
        Set<Long> seen = new HashSet<>();
        for (Object[] row : rows) {
            Long id = (Long) row[0];
            if (allowed == null || allowed.contains(id)) {
                filtered.add(row);
                seen.add(id);
            }
        }
        if (allowed != null) {
            for (Long id : allowed) {
                if (!seen.contains(id)) {
                    userRepository.findById(id).ifPresent(u ->
                            filtered.add(new Object[] {u.getId(), u.getDisplayName(), 0L}));
                }
            }
        }
        List<LeaderboardEntry> result = new ArrayList<>();
        int rank = 1;
        for (Object[] row : filtered) {
            Long id = (Long) row[0];
            result.add(new LeaderboardEntry(rank++, id, (String) row[1],
                    ((Number) row[2]).intValue(), id.equals(userId), null));
        }
        return result;
    }

    /** Điền ảnh đại diện cho các dòng (tra theo id một lần, không kéo avatar vào truy vấn xếp hạng). */
    private List<LeaderboardEntry> withAvatars(List<LeaderboardEntry> entries) {
        Map<Long, String> avatars = userRepository
                .findAllById(entries.stream().map(LeaderboardEntry::userId).toList()).stream()
                .filter(u -> u.getAvatar() != null)
                .collect(Collectors.toMap(User::getId, User::getAvatar, (a, b) -> a));
        return entries.stream()
                .map(e -> new LeaderboardEntry(e.rank(), e.userId(), e.displayName(), e.score(), e.me(),
                        avatars.get(e.userId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<Achievement> achievements(Long userId) {
        requireUser(userId);
        List<Attempt> attempts = attemptRepository.findByUserId(userId);
        int perfect = (int) attempts.stream()
                .filter(a -> a.getTotalQuestions() > 0 && a.getCorrectCount() == a.getTotalQuestions())
                .count();
        int mastered = (int) progressRepository.countByUserIdAndMasteredTrueAndItemTopicOwnerIsNull(userId);
        int streak = activityService.getSummary(userId).currentStreak();
        int courses = (int) enrollmentRepository.countByUserId(userId);

        return List.of(
                tiered("STREAK", "Chuỗi ngày học", "Học liên tiếp mỗi ngày", streak, 3, 7, 14, 30),
                tiered("MASTERED", "Thợ săn kiến thức", "Thuộc nhiều mục nội dung", mastered, 10, 50, 100, 200),
                tiered("ATTEMPTS", "Nhà thử thách", "Hoàn thành các bài kiểm tra", attempts.size(), 1, 5, 10, 25),
                tiered("PERFECT", "Điểm tuyệt đối", "Đạt 100% ở một bài kiểm tra", perfect, 1, 3, 5, 10),
                tiered("COURSES", "Người lập kế hoạch", "Đăng ký khoá học", courses, 1, 2, 3, 4));
    }

    private static Achievement tiered(String code, String title, String description, int current, int... targets) {
        int tier = 0;
        for (int target : targets) {
            if (current >= target) tier++;
        }
        int nextTarget = targets[Math.min(tier, targets.length - 1)];
        return new Achievement(code, title, description, tier, targets.length, current, nextTarget);
    }

    private void requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem bảng xếp hạng.");
        }
    }
}

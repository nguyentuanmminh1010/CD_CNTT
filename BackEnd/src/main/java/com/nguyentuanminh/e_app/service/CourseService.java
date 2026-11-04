package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.Attempt;
import com.nguyentuanminh.e_app.domain.Course;
import com.nguyentuanminh.e_app.domain.CourseCompletion;
import com.nguyentuanminh.e_app.domain.CourseUnit;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.domain.UserCourseEnrollment;
import com.nguyentuanminh.e_app.repository.AttemptRepository;
import com.nguyentuanminh.e_app.repository.CourseCompletionRepository;
import com.nguyentuanminh.e_app.repository.CourseRepository;
import com.nguyentuanminh.e_app.repository.CourseUnitRepository;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import com.nguyentuanminh.e_app.repository.UserCourseEnrollmentRepository;
import com.nguyentuanminh.e_app.repository.UserLearningItemProgressRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.TreeSet;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Khoá học theo lộ trình Level → Unit. Tiến độ Unit/khoá học không lưu riêng:
 * tính trực tiếp từ {@code UserLearningItemProgress} của chủ đề mà Unit trỏ tới.
 * Level Test được ghi bằng {@link Attempt} có {@code refKey = level:{courseId}:{level}};
 * đạt từ {@link #PASS_PERCENT}% thì Level kế tiếp được mở khoá.
 *
 * <p>Riêng giấy chứng nhận được lưu vĩnh viễn ({@link CourseCompletion}): lần đầu thấy khoá đã đăng ký ở trạng thái
 * hoàn thành thì ghi mốc lại, nên chứng chỉ không mất khi khoá có thêm nội dung (tiến độ % vẫn phản ánh nội dung mới). */
@Service
@RequiredArgsConstructor
public class CourseService {

    /** Ngưỡng % để vượt Level Test. */
    public static final int PASS_PERCENT = 70;

    private final CourseRepository courseRepository;
    private final CourseUnitRepository unitRepository;
    private final UserCourseEnrollmentRepository enrollmentRepository;
    private final LearningItemRepository itemRepository;
    private final LearningTopicRepository topicRepository;
    private final UserLearningItemProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final UserRepository userRepository;
    private final CourseCompletionRepository completionRepository;
    private final AdminGuard adminGuard;

    // Không readOnly: dựng view có thể ghi mốc hoàn thành (chứng chỉ) lần đầu.
    @Transactional
    public List<CourseView> getCourses(Long userId) {
        requireUser(userId);
        return courseRepository.findAll().stream()
                .map(course -> build(course, userId, false))
                .toList();
    }

    @Transactional
    public CourseView getCourse(Long userId, Long courseId) {
        requireUser(userId);
        return build(findCourse(courseId), userId, true);
    }

    @Transactional
    public CourseView enroll(Long userId, Long courseId) {
        requireUser(userId);
        Course course = findCourse(courseId);
        if (!enrollmentRepository.existsByUserIdAndCourseId(userId, courseId)) {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
            UserCourseEnrollment enrollment = new UserCourseEnrollment();
            enrollment.setUser(user);
            enrollment.setCourse(course);
            enrollmentRepository.save(enrollment);
        }
        return build(course, userId, true);
    }

    /**
     * Giấy chứng nhận: khoá đã đăng ký và ĐÃ TỪNG hoàn thành (mọi Unit + mọi Level Test), theo thứ tự hoàn thành.
     * Lấy theo mốc đã lưu nên vẫn còn khi khoá có thêm nội dung sau đó.
     */
    @Transactional
    public List<CourseView> getCompletedCourses(Long userId) {
        requireUser(userId);
        return enrollmentRepository.findByUserId(userId).stream()
                .map(e -> build(e.getCourse(), userId, false))
                .filter(CourseView::certified)
                .sorted(Comparator.comparing(CourseView::certifiedAt))
                .toList();
    }

    // ---- Quản trị nội dung (chỉ admin) ----

    @Transactional
    public CourseView createCourse(Long userId, String title, String description, String icon) {
        adminGuard.require(userId);
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("Tên khoá học không được để trống.");
        }
        Course course = courseRepository.save(new Course(null, title.trim(),
                description == null ? null : description.trim(),
                icon == null || icon.isBlank() ? "style_rounded" : icon.trim()));
        return build(course, userId, true);
    }

    @Transactional
    public boolean deleteCourse(Long userId, Long courseId) {
        adminGuard.require(userId);
        Course course = findCourse(courseId);
        enrollmentRepository.deleteByCourseId(courseId);
        completionRepository.deleteByCourseId(courseId);
        unitRepository.deleteByCourseId(courseId);
        courseRepository.delete(course);
        return true;
    }

    @Transactional
    public CourseView addUnit(Long userId, Long courseId, int level, Long topicId) {
        adminGuard.require(userId);
        if (level < 1) {
            throw new IllegalArgumentException("Level phải từ 1 trở lên.");
        }
        Course course = findCourse(courseId);
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        List<CourseUnit> existing = unitRepository.findByCourseIdOrderByLevelAscPositionAsc(courseId);
        if (existing.stream().anyMatch(u -> u.getTopic().getId().equals(topicId))) {
            throw new IllegalArgumentException("Chủ đề này đã có trong khoá học.");
        }
        int position = existing.stream().mapToInt(CourseUnit::getPosition).max().orElse(0) + 1;
        unitRepository.save(new CourseUnit(null, course, level, position, topic));
        return build(course, userId, true);
    }

    @Transactional
    public CourseView removeUnit(Long userId, Long unitId) {
        adminGuard.require(userId);
        CourseUnit unit = unitRepository.findById(unitId)
                .orElseThrow(() -> new NoSuchElementException("Unit not found: " + unitId));
        Course course = unit.getCourse();
        unitRepository.delete(unit);
        return build(course, userId, true);
    }

    // ---- Dựng view ----

    private Course findCourse(Long courseId) {
        return courseRepository.findById(courseId)
                .orElseThrow(() -> new NoSuchElementException("Course not found: " + courseId));
    }

    private CourseView build(Course course, Long userId, boolean withUnits) {
        List<CourseUnit> units = unitRepository.findByCourseIdOrderByLevelAscPositionAsc(course.getId());

        // Điểm cao nhất của Level Test theo từng Level.
        Map<Integer, Integer> bestByLevel = new HashMap<>();
        String prefix = "level:" + course.getId() + ":";
        for (Attempt a : attemptRepository.findByUserIdAndRefKeyStartingWith(userId, prefix)) {
            try {
                int level = Integer.parseInt(a.getRefKey().substring(prefix.length()));
                int percent = a.getTotalQuestions() == 0
                        ? 0 : Math.round(a.getCorrectCount() * 100f / a.getTotalQuestions());
                bestByLevel.merge(level, percent, Math::max);
            } catch (NumberFormatException ignored) {
                // refKey sai định dạng — bỏ qua.
            }
        }
        TreeSet<Integer> levels = new TreeSet<>();
        units.forEach(u -> levels.add(u.getLevel()));
        List<CourseView.LevelResult> levelResults = levels.stream()
                .map(l -> new CourseView.LevelResult(l, bestByLevel.getOrDefault(l, 0),
                        bestByLevel.containsKey(l), bestByLevel.getOrDefault(l, 0) >= PASS_PERCENT))
                .toList();

        List<CourseView.UnitView> unitViews = units.stream().map(u -> {
            int total = (int) itemRepository.countByTopicId(u.getTopic().getId());
            int mastered = (int) progressRepository
                    .countByUserIdAndMasteredTrueAndItemTopicId(userId, u.getTopic().getId());
            Integer previous = levels.lower(u.getLevel());
            boolean locked = previous != null && bestByLevel.getOrDefault(previous, 0) < PASS_PERCENT;
            return new CourseView.UnitView(u.getId(), u.getLevel(), u.getPosition(), u.getTopic(),
                    total, mastered, total > 0 && mastered >= total, locked);
        }).toList();

        int totalItems = unitViews.stream().mapToInt(CourseView.UnitView::totalItems).sum();
        int masteredItems = unitViews.stream().mapToInt(CourseView.UnitView::masteredItems).sum();
        int completedUnits = (int) unitViews.stream().filter(CourseView.UnitView::completed).count();
        boolean allLevelsPassed = levelResults.stream().allMatch(CourseView.LevelResult::passed);
        boolean completed = !unitViews.isEmpty() && completedUnits == unitViews.size() && allLevelsPassed;
        boolean enrolled = enrollmentRepository.existsByUserIdAndCourseId(userId, course.getId());
        String certifiedAt = certify(userId, course.getId(), enrolled && completed);

        return new CourseView(
                course.getId(), course.getTitle(), course.getDescription(), course.getIcon(),
                enrolled,
                unitViews.size(), completedUnits, totalItems, masteredItems, completed,
                certifiedAt != null, certifiedAt,
                withUnits ? unitViews : List.of(), withUnits ? levelResults : List.of());
    }

    /** Mốc hoàn thành lần đầu (ISO-8601); [completedNow] = vừa thấy hoàn thành thì ghi nếu chưa có. Null = chưa có chứng chỉ. */
    private String certify(Long userId, Long courseId, boolean completedNow) {
        if (completedNow) {
            completionRepository.insertIfAbsent(userId, courseId);
        }
        return completionRepository.findByUserIdAndCourseId(userId, courseId)
                .map(c -> c.getCompletedAt().toString())
                .orElse(null);
    }

    private void requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem khoá học.");
        }
    }
}

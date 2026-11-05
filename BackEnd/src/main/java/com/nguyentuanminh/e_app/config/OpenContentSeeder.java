package com.nguyentuanminh.e_app.config;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import tools.jackson.databind.ObjectMapper;
import com.nguyentuanminh.e_app.domain.AppSetting;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.repository.AppSettingRepository;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Nạp kho nội dung chung từ {@code src/main/resources/content/{vocabulary,grammar,sentences}.json} — bộ dữ liệu dựng
 * từ nguồn mở (NGSL/TSL, CEFR-J, Wiktionary, Tatoeba; nguồn + giấy phép ghi ở trường {@code sources} của từng file,
 * cách dựng ở docs/STATUS.md).
 *
 * <p>Chọn chế độ theo {@code version} của bộ nội dung so với giá trị đã lưu ở {@code app_setting}:
 * <ul>
 *   <li><b>Khác phiên bản</b> (DB mới, hoặc chuyển sang bộ nội dung mới): xoá kho chung cũ cùng mọi dữ liệu gắn với nó
 *   ({@link #RESET_SQL}: tiến độ, câu trả lời, lịch sử bài làm, mastery, đánh giá chủ đề, khoá học + đăng ký + chứng
 *   chỉ, thống kê kỹ năng) rồi nạp lại. Tài khoản, bạn bè, ngày hoạt động và bộ thẻ riêng của người dùng giữ nguyên.</li>
 *   <li><b>Cùng phiên bản</b>: chỉ thêm chủ đề/mục còn thiếu (chủ đề tra theo mảng + tên, mục theo {@code term} không
 *   phân biệt hoa thường). Thêm nội dung vào JSON mà giữ nguyên {@code version} thì DB đang chạy nhận phần mới mà không
 *   mất tiến độ, và mục admin đã sửa không bị ghi đè. Chỉ đổi {@code version} khi thực sự muốn thay cả bộ.</li>
 * </ul>
 * Chạy trước {@link CourseSeeder} (khoá học trỏ tới chủ đề theo tên) và {@link GuideSeeder} (điền hướng dẫn mặc định).
 */
@Component
@Order(1)
public class OpenContentSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(OpenContentSeeder.class);

    static final String VERSION_KEY = "content.version";
    static final List<String> FILES = List.of(
            "content/vocabulary.json", "content/grammar.json", "content/sentences.json");

    private static final String SHARED_TOPICS = "SELECT id FROM learning_topic WHERE owner_id IS NULL";
    private static final String SHARED_ITEMS = "SELECT id FROM learning_item WHERE topic_id IN (" + SHARED_TOPICS + ")";

    /**
     * Xoá kho chung cũ theo thứ tự khoá ngoại. Lượt làm bài (`attempt`) bị xoá nếu có câu trả lời thuộc kho chung,
     * là Level Test của khoá học, hoặc là bản ghi cũ không có attemptKey (từ thời chưa chấm ở backend).
     */
    static final List<String> RESET_SQL = List.of(
            "DELETE FROM attempt WHERE attempt_key IS NULL OR ref_key LIKE 'level:%' OR (user_id, attempt_key) IN ("
                    + "SELECT user_id, attempt_key FROM attempt_answer WHERE attempt_key IS NOT NULL"
                    + " AND learning_item_id IN (" + SHARED_ITEMS + "))",
            "DELETE FROM attempt_answer WHERE learning_item_id IN (" + SHARED_ITEMS + ")",
            "DELETE FROM user_learning_item_progress WHERE learning_item_id IN (" + SHARED_ITEMS + ")",
            "DELETE FROM user_topic_mastery WHERE topic_id IN (" + SHARED_TOPICS + ")",
            "DELETE FROM topic_review WHERE topic_id IN (" + SHARED_TOPICS + ")",
            "DELETE FROM deck_gift WHERE topic_id IN (" + SHARED_TOPICS + ")",
            "DELETE FROM user_skill_stat",
            "DELETE FROM course_completion",
            "DELETE FROM user_course_enrollment",
            "DELETE FROM course_unit",
            "DELETE FROM course",
            "DELETE FROM learning_item WHERE topic_id IN (" + SHARED_TOPICS + ")",
            "DELETE FROM learning_topic WHERE owner_id IS NULL");

    @JsonIgnoreProperties(ignoreUnknown = true)
    record ItemSeed(String term, String phonetic, String meaning, String example, String explanation, int level) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record TopicSeed(String name, String description, String icon, List<ItemSeed> items) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    record ContentFile(String version, LearningCategory category, List<TopicSeed> topics) {
    }

    private final LearningTopicRepository topicRepository;
    private final LearningItemRepository itemRepository;
    private final AppSettingRepository settingRepository;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public OpenContentSeeder(LearningTopicRepository topicRepository, LearningItemRepository itemRepository,
                             AppSettingRepository settingRepository, JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.topicRepository = topicRepository;
        this.itemRepository = itemRepository;
        this.settingRepository = settingRepository;
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    static List<ContentFile> load(ObjectMapper mapper) {
        List<ContentFile> files = new ArrayList<>();
        for (String path : FILES) {
            try (InputStream in = new ClassPathResource(path).getInputStream()) {
                files.add(mapper.readValue(in, ContentFile.class));
            } catch (IOException e) {
                throw new IllegalStateException("Không đọc được bộ nội dung " + path, e);
            }
        }
        return files;
    }

    static String versionOf(List<ContentFile> files) {
        List<String> versions = files.stream().map(ContentFile::version).distinct().toList();
        if (versions.size() != 1 || versions.get(0) == null || versions.get(0).isBlank()) {
            throw new IllegalStateException("Các file content/*.json phải cùng một version, đang có: " + versions);
        }
        return versions.get(0);
    }

    @Override
    @Transactional
    public void run(String... args) {
        List<ContentFile> files = load(objectMapper);
        String version = versionOf(files);
        String loaded = settingRepository.findById(VERSION_KEY).map(AppSetting::getValue).orElse(null);
        if (!version.equals(loaded)) {
            long oldTopics = topicRepository.findByOwnerIsNullOrderByCategoryAscIdAsc().size();
            RESET_SQL.forEach(jdbc::update);
            log.info("Nội dung kho chung: chuyển từ phiên bản {} sang {} — đã xoá {} chủ đề cũ và dữ liệu liên quan.",
                    loaded, version, oldTopics);
        }
        int[] added = ensure(files);
        settingRepository.save(new AppSetting(VERSION_KEY, version));
        if (added[0] > 0 || added[1] > 0) {
            log.info("Nội dung kho chung {}: thêm {} chủ đề, {} mục.", version, added[0], added[1]);
        }
    }

    /** Thêm chủ đề/mục còn thiếu; trả về {số chủ đề mới, số mục mới}. */
    private int[] ensure(List<ContentFile> files) {
        List<LearningTopic> shared = topicRepository.findByOwnerIsNullOrderByCategoryAscIdAsc();
        int topics = 0;
        int items = 0;
        for (ContentFile file : files) {
            for (TopicSeed t : file.topics()) {
                LearningTopic topic = shared.stream()
                        .filter(x -> x.getCategory() == file.category() && t.name().equals(x.getName()))
                        .findFirst()
                        .orElse(null);
                if (topic == null) {
                    topic = topicRepository.save(
                            new LearningTopic(null, t.name(), t.description(), t.icon(), file.category()));
                    topics++;
                }
                Set<String> existing = itemRepository.findByTopicIdOrderByDifficultyLevelAscIdAsc(topic.getId())
                        .stream()
                        .map(i -> key(i.getTerm()))
                        .collect(Collectors.toSet());
                List<LearningItem> toSave = new ArrayList<>();
                for (ItemSeed s : t.items()) {
                    if (!existing.add(key(s.term()))) {
                        continue;
                    }
                    LearningItem item = new LearningItem();
                    item.setTerm(s.term());
                    item.setPhonetic(s.phonetic());
                    item.setMeaning(s.meaning());
                    item.setExample(s.example());
                    item.setExplanation(s.explanation());
                    item.setDifficultyLevel(s.level());
                    item.setTopic(topic);
                    toSave.add(item);
                }
                itemRepository.saveAll(toSave);
                items += toSave.size();
            }
        }
        return new int[] {topics, items};
    }

    private static String key(String term) {
        return term.trim().toLowerCase(Locale.ROOT);
    }
}

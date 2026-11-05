package com.nguyentuanminh.e_app.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import tools.jackson.databind.ObjectMapper;
import com.nguyentuanminh.e_app.config.OpenContentSeeder.ContentFile;
import com.nguyentuanminh.e_app.config.OpenContentSeeder.ItemSeed;
import com.nguyentuanminh.e_app.config.OpenContentSeeder.TopicSeed;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Kiểm tra bộ nội dung content/*.json theo ràng buộc của engine sinh đề ở client (practice_builder.dart). */
class OpenContentSeederTest {

    private final List<ContentFile> files = OpenContentSeeder.load(new ObjectMapper());

    @Test
    void filesShareOneVersionAndCoverAllCategories() {
        assertNotNull(OpenContentSeeder.versionOf(files));
        Set<LearningCategory> categories = EnumSet.noneOf(LearningCategory.class);
        files.forEach(f -> categories.add(f.category()));
        assertEquals(EnumSet.allOf(LearningCategory.class), categories);
        long items = files.stream().flatMap(f -> f.topics().stream()).mapToLong(t -> t.items().size()).sum();
        assertTrue(items >= 600, "kho chung chỉ có " + items + " mục");
    }

    @Test
    void termsAndMeaningsAreUniqueWithinTopicAndLevelsValid() {
        for (ContentFile f : files) {
            for (TopicSeed t : f.topics()) {
                assertTrue(t.items().size() >= 6, t.name() + " có " + t.items().size() + " mục");
                Set<String> terms = new HashSet<>();
                Set<String> meanings = new HashSet<>();
                for (ItemSeed s : t.items()) {
                    assertTrue(terms.add(s.term().toLowerCase(Locale.ROOT)), "term trùng: " + s.term());
                    assertTrue(meanings.add(s.meaning().toLowerCase(Locale.ROOT)), "nghĩa trùng: " + s.meaning());
                    assertTrue(s.level() >= 1 && s.level() <= 3, s.term());
                }
            }
        }
    }

    @Test
    void itemsWorkWithEveryExerciseType() {
        for (ContentFile f : files) {
            for (TopicSeed t : f.topics()) {
                for (ItemSeed s : t.items()) {
                    // Sắp xếp câu dùng example (không có thì term) và cần 3–14 từ.
                    String sentence = s.example() != null ? s.example() : s.term();
                    int words = sentence.trim().split("\\s+").length;
                    if (f.category() != LearningCategory.VOCABULARY || s.example() != null) {
                        assertTrue(words >= 3 && words <= 14, "câu " + words + " từ: " + sentence);
                    }
                    if (f.category() == LearningCategory.VOCABULARY) {
                        // Điền chỗ trống: câu ví dụ phải chứa đúng từ; Đánh vần: chỉ chữ cái.
                        Pattern p = Pattern.compile("\\b" + Pattern.quote(s.term()) + "\\b", Pattern.CASE_INSENSITIVE);
                        assertTrue(p.matcher(s.example()).find(), s.term() + " không có trong: " + s.example());
                        assertTrue(s.term().matches("[A-Za-z' -]+"), "term có ký tự lạ: " + s.term());
                        assertNotNull(s.phonetic(), s.term() + " thiếu phiên âm");
                    }
                    if (f.category() == LearningCategory.SENTENCE) {
                        assertTrue(!s.term().matches(".*\\d.*"), "Nghe chép không chấm được chữ số: " + s.term());
                    }
                }
            }
        }
    }

    @Test
    void everyCourseUnitPointsToAContentTopicAndLevelsCanFillALevelTest() {
        Map<String, Integer> sizes = new HashMap<>();
        for (ContentFile f : files) {
            for (TopicSeed t : f.topics()) {
                sizes.put(f.category() + "/" + t.name(), t.items().size());
            }
        }
        for (CourseSeeder.CourseSeed c : CourseSeeder.courses()) {
            Map<Integer, Integer> perLevel = new HashMap<>();
            for (CourseSeeder.Ref r : c.units()) {
                Integer n = sizes.get(r.category() + "/" + r.topicName());
                assertNotNull(n, c.title() + ": không có chủ đề " + r.category() + "/" + r.topicName());
                perLevel.merge(r.level(), n, Integer::sum);
            }
            perLevel.forEach((level, n) ->
                    assertTrue(n >= 12, c.title() + " Level " + level + " chỉ có " + n + " mục (Level Test cần 12)"));
        }
    }
}

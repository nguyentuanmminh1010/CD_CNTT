package com.nguyentuanminh.e_app.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.nguyentuanminh.e_app.config.ContentSupplementSeeder.Seed;
import com.nguyentuanminh.e_app.config.ContentSupplementSeeder.TopicSeed;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.junit.jupiter.api.Test;

class ContentSupplementSeederTest {

    private final List<TopicSeed> topics = ContentSupplementSeeder.supplements();

    @Test
    void everySentenceTopicGetsAnAdvancedSentence() {
        List<TopicSeed> sentences = topics.stream().filter(t -> t.category() == LearningCategory.SENTENCE).toList();
        assertEquals(8, sentences.size());
        for (TopicSeed t : sentences) {
            assertTrue(t.items().stream().anyMatch(s -> s.level() == 3), t.name() + " thiếu câu độ khó 3");
        }
    }

    @Test
    void termsAndMeaningsAreUniqueWithinTopic() {
        // Ghép cặp cần term và nghĩa không trùng trong cùng chủ đề.
        for (TopicSeed t : topics) {
            Set<String> terms = new HashSet<>();
            Set<String> meanings = new HashSet<>();
            for (Seed s : t.items()) {
                assertTrue(terms.add(s.term().toLowerCase(Locale.ROOT)), "term trùng: " + s.term());
                assertTrue(meanings.add(s.meaning().toLowerCase(Locale.ROOT)), "nghĩa trùng: " + s.meaning());
            }
        }
    }

    @Test
    void newGrammarTopicsHaveAtLeastSixPoints() {
        for (String name : List.of("Động từ khuyết thiếu", "Mệnh đề quan hệ", "Câu gián tiếp", "Danh động từ & To-V")) {
            TopicSeed t = topics.stream().filter(x -> x.name().equals(name)).findFirst().orElseThrow();
            assertEquals(LearningCategory.GRAMMAR, t.category());
            assertTrue(t.items().size() >= 6, name + " có " + t.items().size() + " mục");
        }
    }

    @Test
    void levelsAndExamplesAreUsableByExerciseBuilder() {
        for (TopicSeed t : topics) {
            for (Seed s : t.items()) {
                assertTrue(s.level() >= 1 && s.level() <= 3, s.term());
                int words = s.example().trim().split("\\s+").length;
                // Sắp xếp câu dùng câu ví dụ 3–14 từ.
                assertTrue(words >= 3 && words <= 14, "câu ví dụ " + words + " từ: " + s.example());
            }
        }
    }
}

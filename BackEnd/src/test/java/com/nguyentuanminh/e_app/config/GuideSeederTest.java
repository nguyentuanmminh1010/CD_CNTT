package com.nguyentuanminh.e_app.config;

import static org.junit.jupiter.api.Assertions.assertTrue;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import org.junit.jupiter.api.Test;

class GuideSeederTest {

    @Test
    void everyCategoryGetsAMultiStepGuideMentioningTheTopic() {
        for (LearningCategory category : LearningCategory.values()) {
            String guide = GuideSeeder.defaultGuide(category, "Du lịch");
            assertTrue(guide.split("\n").length >= 4, category + " should have several steps");
            assertTrue(guide.contains("Du lịch"), category + " guide should mention the topic name");
        }
    }
}

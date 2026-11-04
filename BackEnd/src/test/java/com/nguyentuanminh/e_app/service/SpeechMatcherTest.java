package com.nguyentuanminh.e_app.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Bản Java của bộ so khớp giọng nói/gõ lại phải cho cùng kết quả với {@code speech_matcher.dart}. */
class SpeechMatcherTest {

    @Test
    void normalisesCaseAndPunctuation() {
        assertEquals(List.of("don't", "worry", "be", "happy"), SpeechMatcher.words("Don't  worry, BE happy!"));
        assertTrue(SpeechMatcher.words("   ").isEmpty());
    }

    @Test
    void identicalAndNearSentencesPass() {
        assertEquals(1.0, SpeechMatcher.similarity("How are you?", "how are you"), 1e-9);
        assertTrue(SpeechMatcher.similarity("i would like a table for two",
                "i would like a table for two please") >= SpeechMatcher.PASS_RATIO);
    }

    @Test
    void missingWordsAndWrongOrderFail() {
        assertEquals(2.0 / 3, SpeechMatcher.similarity("how you", "how are you"), 1e-9);
        assertTrue(SpeechMatcher.similarity("how you", "how are you") < SpeechMatcher.PASS_RATIO);
        assertTrue(SpeechMatcher.similarity("you are how", "how are you") < SpeechMatcher.PASS_RATIO);
        assertEquals(0.0, SpeechMatcher.similarity("", "hello"), 1e-9);
    }

    @Test
    void typedAnswersIgnoreCaseSpacesAndTrailingPunctuation() {
        assertEquals(SpeechMatcher.normalizeTyped("Hello, World."), SpeechMatcher.normalizeTyped("  hello,   world "));
        assertFalse(SpeechMatcher.normalizeTyped("hello").equals(SpeechMatcher.normalizeTyped("hallo")));
    }

    @Test
    void adaptiveDifficultyThresholds() {
        assertEquals(1, LearningService.difficultyFor(0.30));
        assertEquals(1, LearningService.difficultyFor(0.44));
        assertEquals(2, LearningService.difficultyFor(0.45));
        assertEquals(2, LearningService.difficultyFor(0.74));
        assertEquals(3, LearningService.difficultyFor(0.75));
        assertEquals(3, LearningService.difficultyFor(1.0));
    }
}

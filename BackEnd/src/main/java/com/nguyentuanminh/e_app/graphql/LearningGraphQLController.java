package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.domain.AnswerMode;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.domain.Skill;
import com.nguyentuanminh.e_app.service.AnswerService;
import com.nguyentuanminh.e_app.service.DeckService;
import com.nguyentuanminh.e_app.service.LearningService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;

/**
 * Một controller dùng chung cho cả Vocabulary/Grammar/Sentence — mỗi mảng có tên query/mutation
 * riêng cho rõ ràng ở API, nhưng cùng chạy qua {@link LearningService}. Kèm chấm điểm câu trả lời
 * ({@link AnswerService}) và quản lý bộ thẻ/nội dung ({@link DeckService}).
 */
@Controller
@RequiredArgsConstructor
public class LearningGraphQLController {

    private static final String USER = "userId";

    private final LearningService learningService;
    private final AnswerService answerService;
    private final DeckService deckService;

    // ---- Chủ đề / mục theo từng mảng ----

    @QueryMapping
    public List<LearningTopic> vocabularyTopics(@ContextValue(name = USER, required = false) Long userId) {
        return learningService.getTopics(LearningCategory.VOCABULARY, userId);
    }

    @QueryMapping
    public List<LearningItem> vocabularyItems(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return learningService.getItems(topicId, LearningCategory.VOCABULARY, userId);
    }

    @QueryMapping
    public List<LearningTopic> grammarTopics(@ContextValue(name = USER, required = false) Long userId) {
        return learningService.getTopics(LearningCategory.GRAMMAR, userId);
    }

    @QueryMapping
    public List<LearningItem> grammarItems(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return learningService.getItems(topicId, LearningCategory.GRAMMAR, userId);
    }

    @QueryMapping
    public List<LearningTopic> sentenceTopics(@ContextValue(name = USER, required = false) Long userId) {
        return learningService.getTopics(LearningCategory.SENTENCE, userId);
    }

    @QueryMapping
    public List<LearningItem> sentenceItems(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return learningService.getItems(topicId, LearningCategory.SENTENCE, userId);
    }

    @MutationMapping
    public LearningItem markVocabularyItemMastered(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long itemId, @Argument boolean mastered) {
        return learningService.markMastered(userId, itemId, mastered);
    }

    @MutationMapping
    public LearningItem markGrammarItemMastered(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long itemId, @Argument boolean mastered) {
        return learningService.markMastered(userId, itemId, mastered);
    }

    @MutationMapping
    public LearningItem markSentenceItemMastered(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long itemId, @Argument boolean mastered) {
        return learningService.markMastered(userId, itemId, mastered);
    }

    // ---- Ôn tập / gợi ý / tìm kiếm ----

    @QueryMapping
    public List<LearningItem> wrongItems(@ContextValue(name = USER, required = false) Long userId) {
        return learningService.getWrongItems(userId);
    }

    @QueryMapping
    public List<LearningItem> dueItems(
            @ContextValue(name = USER, required = false) Long userId, @Argument Integer limit) {
        return learningService.getDueItems(userId, limit == null ? 30 : limit);
    }

    @QueryMapping
    public int dueItemCount(@ContextValue(name = USER, required = false) Long userId) {
        return learningService.countDueItems(userId);
    }

    @QueryMapping
    public List<LearningService.RecommendedTopic> recommendedTopics(
            @ContextValue(name = USER, required = false) Long userId, @Argument Integer limit) {
        return learningService.getRecommendedTopics(userId, limit == null ? 3 : limit);
    }

    @QueryMapping
    public List<LearningItem> searchItems(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument String query, @Argument Integer limit) {
        return learningService.searchItems(query, limit == null ? 30 : limit, userId);
    }

    // ---- Chấm điểm ở backend ----

    @MutationMapping
    public AnswerService.AnswerResult submitAnswer(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long itemId,
            @Argument AnswerMode mode,
            @Argument String answer,
            @Argument String attemptKey,
            @Argument Skill skill) {
        return answerService.submit(userId, itemId, mode, answer, attemptKey, skill);
    }

    // ---- Bộ thẻ / quản lý nội dung ----

    @QueryMapping
    public List<LearningTopic> myDecks(@ContextValue(name = USER, required = false) Long userId) {
        return deckService.myDecks(userId);
    }

    @QueryMapping
    public List<LearningTopic> systemTopics(@ContextValue(name = USER, required = false) Long userId) {
        return deckService.systemTopics(userId);
    }

    @MutationMapping
    public LearningTopic createDeck(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument String name,
            @Argument String description,
            @Argument LearningCategory category,
            @Argument String icon) {
        return deckService.createDeck(userId, name, description, category, icon);
    }

    @MutationMapping
    public LearningTopic updateTopic(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long topicId, @Argument String name, @Argument String description, @Argument String guide) {
        return deckService.updateTopic(userId, topicId, name, description, guide);
    }

    @MutationMapping
    public boolean deleteTopic(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return deckService.deleteTopic(userId, topicId);
    }

    @MutationMapping
    public LearningItem addItem(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long topicId,
            @Argument String term,
            @Argument String phonetic,
            @Argument String meaning,
            @Argument String example,
            @Argument Integer difficultyLevel,
            @Argument String explanation,
            @Argument String imageUrl,
            @Argument String audioUrl) {
        return deckService.addItem(userId, topicId, term, phonetic, meaning, example, difficultyLevel,
                explanation, imageUrl, audioUrl);
    }

    @MutationMapping
    public LearningItem updateItem(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long itemId,
            @Argument String term,
            @Argument String phonetic,
            @Argument String meaning,
            @Argument String example,
            @Argument Integer difficultyLevel,
            @Argument String explanation,
            @Argument String imageUrl,
            @Argument String audioUrl) {
        return deckService.updateItem(userId, itemId, term, phonetic, meaning, example, difficultyLevel,
                explanation, imageUrl, audioUrl);
    }

    @MutationMapping
    public boolean deleteItem(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long itemId) {
        return deckService.deleteItem(userId, itemId);
    }

    @MutationMapping
    public DeckService.ImportResult importItems(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long topicId, @Argument String text) {
        return deckService.importItems(userId, topicId, text);
    }

    @MutationMapping
    public String shareDeck(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return deckService.shareDeck(userId, topicId);
    }

    @MutationMapping
    public boolean unshareDeck(
            @ContextValue(name = USER, required = false) Long userId, @Argument Long topicId) {
        return deckService.unshareDeck(userId, topicId);
    }

    @QueryMapping
    public DeckService.SharedDeck sharedDeck(
            @ContextValue(name = USER, required = false) Long userId, @Argument String code) {
        return deckService.sharedDeck(userId, code);
    }

    @MutationMapping
    public LearningTopic importSharedDeck(
            @ContextValue(name = USER, required = false) Long userId, @Argument String code) {
        return deckService.importSharedDeck(userId, code);
    }

    @QueryMapping
    public List<DeckService.DeckGiftView> deckGifts(@ContextValue(name = USER, required = false) Long userId) {
        return deckService.receivedGifts(userId);
    }

    @MutationMapping
    public boolean sendDeckToFriend(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long topicId, @Argument Long friendId) {
        return deckService.sendToFriend(userId, topicId, friendId);
    }

    @MutationMapping
    public LearningTopic respondDeckGift(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument Long giftId, @Argument boolean accept) {
        return deckService.respondGift(userId, giftId, accept);
    }

    // ---- Trường tính toán ----

    @SchemaMapping(typeName = "LearningTopic", field = "wordCount")
    public int wordCount(LearningTopic topic) {
        return (int) learningService.countItemsInTopic(topic.getId());
    }

    @SchemaMapping(typeName = "LearningTopic", field = "mine")
    public boolean mine(LearningTopic topic) {
        return topic.getOwner() != null;
    }

    @SchemaMapping(typeName = "LearningTopic", field = "editable")
    public boolean editable(
            LearningTopic topic, @ContextValue(name = USER, required = false) Long userId) {
        return deckService.canEdit(topic, userId);
    }

    @SchemaMapping(typeName = "LearningTopic", field = "shareCode")
    public String shareCode(LearningTopic topic, @ContextValue(name = USER, required = false) Long userId) {
        return topic.getOwner() != null && topic.getOwner().getId().equals(userId) ? topic.getShareCode() : null;
    }

    @SchemaMapping(typeName = "LearningItem", field = "mastered")
    public boolean mastered(
            LearningItem item, @ContextValue(name = USER, required = false) Long userId) {
        return learningService.isMastered(userId, item.getId());
    }
}

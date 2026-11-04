package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.domain.AttemptType;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.service.AttemptService;
import com.nguyentuanminh.e_app.service.AttemptView;
import com.nguyentuanminh.e_app.service.LearningService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Lịch sử bài làm và đề cho các bài test ở tab Đánh giá. */
@Controller
@RequiredArgsConstructor
public class AttemptGraphQLController {

    private final AttemptService attemptService;
    private final LearningService learningService;

    @QueryMapping
    public List<AttemptView> myAttempts(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument Integer limit) {
        return attemptService.list(userId, limit == null ? 20 : limit);
    }

    @MutationMapping
    public AttemptView finishAttempt(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument String attemptKey,
            @Argument AttemptType type,
            @Argument String title,
            @Argument String refKey,
            @Argument Integer expectedTotal) {
        return attemptService.finish(userId, attemptKey, type, title, refKey, expectedTotal);
    }

    @QueryMapping
    public List<AttemptService.AnswerView> attemptAnswers(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long attemptId) {
        return attemptService.answers(userId, attemptId);
    }

    @QueryMapping
    public List<LearningItem> assessmentItems(
            @Argument LearningCategory category,
            @Argument Integer minDifficulty,
            @Argument Integer maxDifficulty,
            @Argument Integer limit) {
        return learningService.getAssessmentItems(
                category,
                minDifficulty == null ? 1 : minDifficulty,
                maxDifficulty == null ? 3 : maxDifficulty,
                limit == null ? 10 : limit);
    }
}

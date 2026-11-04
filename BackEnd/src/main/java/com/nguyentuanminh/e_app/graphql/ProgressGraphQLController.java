package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.service.ActivityService;
import com.nguyentuanminh.e_app.service.ActivitySummary;
import com.nguyentuanminh.e_app.service.CategoryMastery;
import com.nguyentuanminh.e_app.service.LearningService;
import com.nguyentuanminh.e_app.service.MasteryOverview;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Dữ liệu cho tab Tiến độ và tiến độ "Ôn thi TOEIC" ở Home. */
@Controller
@RequiredArgsConstructor
public class ProgressGraphQLController {

    private final ActivityService activityService;
    private final LearningService learningService;

    @QueryMapping
    public ActivitySummary myActivity(
            @ContextValue(name = "userId", required = false) Long userId) {
        return activityService.getSummary(userId);
    }

    @QueryMapping
    public MasteryOverview masteryOverview(
            @ContextValue(name = "userId", required = false) Long userId) {
        return learningService.getMasteryOverview(userId);
    }

    @QueryMapping
    public List<CategoryMastery> masteryByCategory(
            @ContextValue(name = "userId", required = false) Long userId) {
        return learningService.getMasteryByCategory(userId);
    }

    @QueryMapping
    public List<LearningItem> toeicPracticeItems(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument Integer limit) {
        return learningService.getToeicPracticeItems(userId, limit == null ? 10 : limit);
    }
}

package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.service.TopicReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class TopicReviewGraphQLController {

    private final TopicReviewService reviewService;

    @QueryMapping
    public TopicReviewService.ReviewsView topicReviews(
            @ContextValue(name = "userId", required = false) Long userId, @Argument Long topicId) {
        return reviewService.getReviews(userId, topicId);
    }

    @MutationMapping
    public TopicReviewService.ReviewsView submitTopicReview(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument Long topicId,
            @Argument int rating,
            @Argument String comment) {
        return reviewService.submit(userId, topicId, rating, comment);
    }
}

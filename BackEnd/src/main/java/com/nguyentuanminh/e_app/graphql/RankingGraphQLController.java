package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.service.RankingService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Bảng xếp hạng và thành tựu ở Hồ sơ/tab Đánh giá. */
@Controller
@RequiredArgsConstructor
public class RankingGraphQLController {

    private final RankingService rankingService;

    @QueryMapping
    public List<RankingService.LeaderboardEntry> leaderboard(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument Integer limit,
            @Argument String period) {
        return rankingService.leaderboard(userId, limit == null ? 20 : limit, periodOf(period));
    }

    @QueryMapping
    public RankingService.LeaderboardEntry myRank(
            @ContextValue(name = "userId", required = false) Long userId, @Argument String period) {
        return rankingService.myRank(userId, periodOf(period));
    }

    private static RankingService.Period periodOf(String period) {
        return period == null ? RankingService.Period.ALL : RankingService.Period.valueOf(period);
    }

    @QueryMapping
    public List<RankingService.Achievement> achievements(
            @ContextValue(name = "userId", required = false) Long userId) {
        return rankingService.achievements(userId);
    }
}

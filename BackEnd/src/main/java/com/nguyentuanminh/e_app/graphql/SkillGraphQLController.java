package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.domain.Skill;
import com.nguyentuanminh.e_app.service.SkillMastery;
import com.nguyentuanminh.e_app.service.SkillService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Dữ liệu cho radar chart 4 kỹ năng (Đọc/Viết/Nghe/Nói) ở Hồ sơ. */
@Controller
@RequiredArgsConstructor
public class SkillGraphQLController {

    private final SkillService skillService;

    @QueryMapping
    public List<SkillMastery> skillMastery(
            @ContextValue(name = "userId", required = false) Long userId) {
        return skillService.getSkillMastery(userId);
    }
}

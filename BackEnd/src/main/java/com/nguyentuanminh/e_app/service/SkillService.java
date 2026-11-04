package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.Skill;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.domain.UserSkillStat;
import com.nguyentuanminh.e_app.repository.UserRepository;
import com.nguyentuanminh.e_app.repository.UserSkillStatRepository;
import java.util.Arrays;
import java.util.List;
import java.util.NoSuchElementException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Theo dõi số lượt luyện tập + số lượt đúng theo từng kỹ năng (Đọc/Viết/Nghe/
 * Nói) — độc lập với {@link LearningService} (vốn theo dõi theo category nội
 * dung), vì 1 kỹ năng có thể áp dụng lên mục nội dung của bất kỳ category nào. */
@Service
@RequiredArgsConstructor
public class SkillService {

    private final UserSkillStatRepository statRepository;
    private final UserRepository userRepository;

    @Transactional
    public SkillMastery recordAttempt(Long userId, Skill skill, boolean correct) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để lưu tiến độ luyện tập.");
        }
        UserSkillStat stat = statRepository.findByUserIdAndSkill(userId, skill)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
                    UserSkillStat created = new UserSkillStat();
                    created.setUser(user);
                    created.setSkill(skill);
                    return created;
                });
        stat.setTotalAttempts(stat.getTotalAttempts() + 1);
        if (correct) {
            stat.setCorrectAttempts(stat.getCorrectAttempts() + 1);
        }
        statRepository.save(stat);
        return new SkillMastery(skill, stat.getTotalAttempts(), stat.getCorrectAttempts());
    }

    @Transactional(readOnly = true)
    public List<SkillMastery> getSkillMastery(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để xem tiến độ.");
        }
        return Arrays.stream(Skill.values())
                .map(skill -> statRepository.findByUserIdAndSkill(userId, skill)
                        .map(s -> new SkillMastery(skill, s.getTotalAttempts(), s.getCorrectAttempts()))
                        .orElseGet(() -> new SkillMastery(skill, 0, 0)))
                .toList();
    }
}

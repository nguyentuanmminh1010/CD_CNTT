package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.Skill;
import com.nguyentuanminh.e_app.domain.UserSkillStat;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserSkillStatRepository extends JpaRepository<UserSkillStat, Long> {

    Optional<UserSkillStat> findByUserIdAndSkill(Long userId, Skill skill);
}

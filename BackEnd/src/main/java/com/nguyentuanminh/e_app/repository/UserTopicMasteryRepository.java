package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.UserTopicMastery;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserTopicMasteryRepository extends JpaRepository<UserTopicMastery, Long> {

    Optional<UserTopicMastery> findByUserIdAndTopicId(Long userId, Long topicId);

    List<UserTopicMastery> findByUserId(Long userId);

    void deleteByTopicId(Long topicId);
}

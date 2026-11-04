package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.AttemptAnswer;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AttemptAnswerRepository extends JpaRepository<AttemptAnswer, Long> {

    List<AttemptAnswer> findByUserIdAndAttemptKeyOrderByIdAsc(Long userId, String attemptKey);

    java.util.Optional<AttemptAnswer> findFirstByUserIdAndAttemptKeyAndItemId(Long userId, String attemptKey, Long itemId);

    void deleteByItemId(Long itemId);

    void deleteByItemTopicId(Long topicId);
}

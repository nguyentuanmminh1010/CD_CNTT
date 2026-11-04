package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.Attempt;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AttemptRepository extends JpaRepository<Attempt, Long> {

    List<Attempt> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    List<Attempt> findByUserId(Long userId);

    List<Attempt> findByUserIdAndRefKeyStartingWith(Long userId, String prefix);

    java.util.Optional<Attempt> findByUserIdAndAttemptKey(Long userId, String attemptKey);
}

package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.UserActivityDay;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserActivityDayRepository extends JpaRepository<UserActivityDay, Long> {

    Optional<UserActivityDay> findByUserIdAndActivityDate(Long userId, LocalDate activityDate);

    List<UserActivityDay> findByUserIdOrderByActivityDateDesc(Long userId);
}

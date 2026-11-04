package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.NotificationRead;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationReadRepository extends JpaRepository<NotificationRead, Long> {

    @Query("SELECT n.notificationKey FROM NotificationRead n WHERE n.user.id = :userId")
    List<String> findKeysByUserId(@Param("userId") Long userId);

    boolean existsByUserIdAndNotificationKey(Long userId, String key);
}

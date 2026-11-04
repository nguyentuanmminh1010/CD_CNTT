package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.PasswordResetToken;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {

    Optional<PasswordResetToken> findFirstByUserIdAndUsedFalseOrderByIdDesc(Long userId);
}

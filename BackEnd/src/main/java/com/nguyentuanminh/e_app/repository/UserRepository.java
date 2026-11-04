package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.AuthProvider;
import com.nguyentuanminh.e_app.domain.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByAuthProviderAndProviderId(AuthProvider authProvider, String providerId);

    boolean existsByEmail(String email);

    java.util.List<User> findTop10ByDisplayNameContainingIgnoreCaseOrEmailIgnoreCase(String name, String email);
}

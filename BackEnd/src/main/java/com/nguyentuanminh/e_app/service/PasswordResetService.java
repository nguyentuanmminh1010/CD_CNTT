package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.AuthProvider;
import com.nguyentuanminh.e_app.domain.PasswordResetToken;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.PasswordResetTokenRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Đặt lại mật khẩu bằng mã 6 số: {@code request} tạo + gửi mã (qua {@link ResetCodeSender}),
 * {@code reset} kiểm mã rồi đổi mật khẩu. Không tiết lộ email có tồn tại hay không. */
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final Duration TTL = Duration.ofMinutes(15);
    private static final int MAX_ATTEMPTS = 5;
    static final int MIN_PASSWORD_LENGTH = 6;

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final ResetCodeSender sender;
    private final RateLimiter rateLimiter;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private final SecureRandom random = new SecureRandom();

    @Transactional
    public boolean request(String email) {
        if (email == null || email.isBlank()) {
            return true;
        }
        rateLimiter.hitOrThrow("reset:" + email.trim().toLowerCase(), 3, Duration.ofMinutes(10),
                "Bạn yêu cầu mã quá nhanh. Hãy đợi vài phút rồi thử lại.");
        // Chỉ tài khoản đăng ký bằng email/mật khẩu (LOCAL) mới có mật khẩu để đặt lại.
        userRepository.findByEmail(email.trim().toLowerCase())
                .filter(u -> u.getAuthProvider() == AuthProvider.LOCAL)
                .ifPresent(user -> {
                    tokenRepository.findFirstByUserIdAndUsedFalseOrderByIdDesc(user.getId()).ifPresent(old -> {
                        old.setUsed(true);
                        tokenRepository.save(old);
                    });
                    String code = String.format("%06d", random.nextInt(1_000_000));
                    PasswordResetToken token = new PasswordResetToken();
                    token.setUser(user);
                    token.setCodeHash(encoder.encode(code));
                    token.setExpiresAt(Instant.now().plus(TTL));
                    tokenRepository.save(token);
                    sender.send(user.getEmail(), code);
                });
        return true;
    }

    @Transactional
    public boolean reset(String email, String code, String newPassword) {
        if (newPassword == null || newPassword.length() < MIN_PASSWORD_LENGTH) {
            throw new IllegalArgumentException("Mật khẩu mới cần có ít nhất " + MIN_PASSWORD_LENGTH + " ký tự.");
        }
        String error = "Mã không đúng hoặc đã hết hạn.";
        User user = userRepository.findByEmail(email == null ? "" : email.trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException(error));
        PasswordResetToken token = tokenRepository.findFirstByUserIdAndUsedFalseOrderByIdDesc(user.getId())
                .orElseThrow(() -> new IllegalArgumentException(error));
        if (token.getExpiresAt().isBefore(Instant.now()) || token.getAttempts() >= MAX_ATTEMPTS) {
            token.setUsed(true);
            tokenRepository.save(token);
            throw new IllegalArgumentException(error);
        }
        if (code == null || !encoder.matches(code.trim(), token.getCodeHash())) {
            token.setAttempts(token.getAttempts() + 1);
            tokenRepository.save(token);
            throw new IllegalArgumentException(error);
        }
        token.setUsed(true);
        tokenRepository.save(token);
        user.setPasswordHash(encoder.encode(newPassword));
        userRepository.save(user);
        return true;
    }
}

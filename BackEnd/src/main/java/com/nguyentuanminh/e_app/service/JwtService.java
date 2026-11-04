package com.nguyentuanminh.e_app.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class JwtService {

    private final SecretKey key;
    private final Duration expiration;
    private final boolean configured;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-minutes}") long expirationMinutes) {
        this.configured = StringUtils.hasText(secret);
        // Fallback key so the app still boots when JWT_SECRET isn't set yet;
        // tokens signed with it are only valid for this running instance.
        String effectiveSecret = configured ? secret : "insecure-dev-fallback-secret-do-not-use-in-prod";
        this.key = Keys.hmacShaKeyFor(pad(effectiveSecret).getBytes(StandardCharsets.UTF_8));
        this.expiration = Duration.ofMinutes(expirationMinutes);
    }

    private static String pad(String secret) {
        // HS256 needs a key of at least 256 bits (32 bytes).
        StringBuilder sb = new StringBuilder(secret);
        while (sb.length() < 32) {
            sb.append(secret);
        }
        return sb.toString();
    }

    public String issueToken(Long userId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(expiration)))
                .signWith(key)
                .compact();
    }

    /** Trả về userId nếu token hợp lệ, null nếu thiếu/hết hạn/sai chữ ký. */
    public Long parseUserId(String token) {
        try {
            Claims claims = Jwts.parser().verifyWith(key).build()
                    .parseSignedClaims(token)
                    .getPayload();
            return Long.valueOf(claims.getSubject());
        } catch (JwtException | IllegalArgumentException e) {
            return null;
        }
    }
}

package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.AuthProvider;
import com.nguyentuanminh.e_app.domain.Gender;
import com.nguyentuanminh.e_app.domain.LearningPurpose;
import com.nguyentuanminh.e_app.domain.StartMode;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.time.LocalDate;
import java.util.Map;
import java.util.NoSuchElementException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /** Sai quá [LOGIN_MAX_FAILURES] lần trong [LOGIN_WINDOW] thì tạm khoá đăng nhập email đó. */
    static final int LOGIN_MAX_FAILURES = 8;
    static final java.time.Duration LOGIN_WINDOW = java.time.Duration.ofMinutes(15);

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final RestClient restClient = RestClient.create();
    private final RateLimiter rateLimiter;

    private final String googleClientId;
    private final String facebookAppId;

    public AuthService(
            UserRepository userRepository,
            JwtService jwtService,
            RateLimiter rateLimiter,
            @Value("${app.oauth.google.client-id}") String googleClientId,
            @Value("${app.oauth.facebook.app-id}") String facebookAppId) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.rateLimiter = rateLimiter;
        this.googleClientId = googleClientId;
        this.facebookAppId = facebookAppId;
    }

    @Transactional
    public AuthPayload register(String email, String rawPassword, String displayName) {
        String normalizedEmail = email.trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException("Email đã được sử dụng.");
        }
        User user = new User();
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setDisplayName(displayName);
        user.setAuthProvider(AuthProvider.LOCAL);
        user = userRepository.save(user);
        return new AuthPayload(jwtService.issueToken(user.getId()), user);
    }

    @Transactional(readOnly = true)
    public AuthPayload login(String email, String rawPassword) {
        String key = "login:" + email.trim().toLowerCase();
        rateLimiter.assertBelow(key, LOGIN_MAX_FAILURES, LOGIN_WINDOW,
                "Bạn đã nhập sai quá nhiều lần. Hãy thử lại sau 15 phút hoặc dùng \"Quên mật khẩu\".");
        User user = userRepository.findByEmail(email.trim().toLowerCase()).orElse(null);
        if (user == null
                || user.getPasswordHash() == null
                || !passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            rateLimiter.hit(key);
            throw new IllegalArgumentException("Email hoặc mật khẩu không đúng.");
        }
        rateLimiter.reset(key);
        return new AuthPayload(jwtService.issueToken(user.getId()), user);
    }

    @Transactional
    public AuthPayload loginWithGoogle(String idToken) {
        if (!StringUtils.hasText(googleClientId)) {
            throw new IllegalStateException(
                    "Google Sign-In chưa được cấu hình ở máy chủ (thiếu GOOGLE_CLIENT_ID).");
        }
        Map<String, Object> claims;
        try {
            claims = restClient.get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token={t}", idToken)
                    .retrieve()
                    .body(Map.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Google token không hợp lệ hoặc đã hết hạn.");
        }
        if (claims == null || !googleClientId.equals(claims.get("aud"))) {
            throw new IllegalArgumentException("Google token không khớp với ứng dụng.");
        }
        String providerId = String.valueOf(claims.get("sub"));
        String email = (String) claims.get("email");
        String name = (String) claims.getOrDefault("name", email != null ? email : "Người dùng Google");
        // Chỉ tin email do Google xác thực (email_verified) khi gộp vào tài khoản đã có cùng email.
        boolean verified = "true".equalsIgnoreCase(String.valueOf(claims.get("email_verified")));
        return findOrCreateSocialUser(AuthProvider.GOOGLE, providerId, verified ? email : null, name);
    }

    @Transactional
    public AuthPayload loginWithFacebook(String accessToken) {
        if (!StringUtils.hasText(facebookAppId)) {
            throw new IllegalStateException(
                    "Facebook Sign-In chưa được cấu hình ở máy chủ (thiếu FACEBOOK_APP_ID).");
        }
        Map<String, Object> profile;
        try {
            // Token phải do CHÍNH app này cấp — không thì token lấy từ app Facebook khác cũng đăng nhập được.
            Map<String, Object> app = facebookGraph("https://graph.facebook.com/app?access_token={t}", accessToken);
            if (!facebookAppId.equals(String.valueOf(app.get("id")))) {
                throw new IllegalArgumentException("Facebook access token không thuộc ứng dụng này.");
            }
            profile = facebookGraph("https://graph.facebook.com/me?fields=id,name,email&access_token={t}", accessToken);
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (RestClientResponseException e) {
            // Facebook trả lỗi kèm JSON {"error":{"message":...,"code":...}} — ghi log và báo lại lý do thật.
            String body = e.getResponseBodyAsString();
            log.warn("Facebook Graph API từ chối token: HTTP {} {}", e.getStatusCode().value(), body);
            throw new IllegalArgumentException("Facebook từ chối đăng nhập: " + facebookErrorMessage(body));
        } catch (Exception e) {
            log.warn("Không gọi được Facebook Graph API", e);
            throw new IllegalArgumentException("Không kết nối được tới Facebook để xác minh đăng nhập. Vui lòng thử lại.");
        }
        if (profile.get("id") == null) {
            throw new IllegalArgumentException("Không lấy được thông tin tài khoản Facebook.");
        }
        String providerId = String.valueOf(profile.get("id"));
        String email = (String) profile.get("email");
        String name = (String) profile.getOrDefault("name", "Người dùng Facebook");
        return findOrCreateSocialUser(AuthProvider.FACEBOOK, providerId, email, name);
    }

    /**
     * Gọi Graph API và đọc JSON. Facebook trả phản hồi thành công với `Content-Type: text/javascript` nên KHÔNG dùng
     * `.body(Map.class)` (Spring không có converter cho kiểu đó → UnknownContentTypeException); đọc chuỗi rồi tự parse.
     */
    private Map<String, Object> facebookGraph(String uriTemplate, String accessToken) {
        String body = restClient.get().uri(uriTemplate, accessToken).retrieve().body(String.class);
        if (body == null || body.isBlank()) {
            throw new IllegalArgumentException("Facebook không trả dữ liệu.");
        }
        return org.springframework.boot.json.JsonParserFactory.getJsonParser().parseMap(body);
    }

    /** Lấy `error.message` trong JSON lỗi của Graph API; không đọc được thì trả nguyên văn (cắt ngắn). */
    static String facebookErrorMessage(String body) {
        if (body == null || body.isBlank()) return "không rõ lý do";
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile("\"message\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
                .matcher(body);
        String msg = m.find() ? m.group(1).replace("\\\"", "\"") : body;
        return msg.length() > 200 ? msg.substring(0, 200) : msg;
    }

    @Transactional
    public User updateProfile(
            Long userId,
            String displayName,
            String dob,
            Gender gender,
            LearningPurpose learningPurpose,
            Integer dailyMinutes,
            StartMode startMode) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để cập nhật hồ sơ.");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));

        if (StringUtils.hasText(displayName)) user.setDisplayName(displayName);
        if (dob != null) user.setDob(LocalDate.parse(dob));
        if (gender != null) user.setGender(gender);
        if (learningPurpose != null) user.setLearningPurpose(learningPurpose);
        if (dailyMinutes != null) user.setDailyMinutes(dailyMinutes);
        if (startMode != null) user.setStartMode(startMode);

        return userRepository.save(user);
    }

    /** Đặt/xoá ảnh đại diện (data URL). Giới hạn ~400KB để không phình bảng user. */
    public User updateAvatar(Long userId, String avatar) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập để đổi ảnh đại diện.");
        }
        if (avatar != null && avatar.length() > 400_000) {
            throw new IllegalArgumentException("Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn.");
        }
        if (avatar != null && !avatar.isEmpty() && !avatar.startsWith("data:image/")) {
            throw new IllegalArgumentException("Ảnh đại diện không hợp lệ.");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        user.setAvatar(avatar == null || avatar.isEmpty() ? null : avatar);
        return userRepository.save(user);
    }

    /**
     * Đăng nhập/đăng ký bằng Google/Facebook: đã từng đăng nhập bằng nhà cung cấp này thì lấy lại tài khoản đó;
     * chưa, nhưng email (đã được nhà cung cấp xác thực) trùng một tài khoản có sẵn — vd đã đăng ký bằng email/mật khẩu
     * hoặc bằng nhà cung cấp khác — thì đăng nhập vào CHÍNH tài khoản đó (gộp, không tạo trùng email); còn lại tạo mới.
     */
    private AuthPayload findOrCreateSocialUser(
            AuthProvider provider, String providerId, String email, String displayName) {
        String normalizedEmail = email != null && !email.isBlank() ? email.trim().toLowerCase() : null;
        User user = userRepository.findByAuthProviderAndProviderId(provider, providerId)
                .or(() -> normalizedEmail == null ? java.util.Optional.empty() : userRepository.findByEmail(normalizedEmail))
                .orElseGet(() -> {
                    User created = new User();
                    created.setAuthProvider(provider);
                    created.setProviderId(providerId);
                    created.setEmail(normalizedEmail);
                    created.setDisplayName(displayName);
                    return userRepository.save(created);
                });
        return new AuthPayload(jwtService.issueToken(user.getId()), user);
    }
}

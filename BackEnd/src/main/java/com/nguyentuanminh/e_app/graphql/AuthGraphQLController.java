package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.domain.Gender;
import com.nguyentuanminh.e_app.domain.LearningPurpose;
import com.nguyentuanminh.e_app.domain.StartMode;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.UserRepository;
import com.nguyentuanminh.e_app.service.AdminGuard;
import com.nguyentuanminh.e_app.service.AuthPayload;
import com.nguyentuanminh.e_app.service.AuthService;
import com.nguyentuanminh.e_app.service.PasswordResetService;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;

@Controller
public class AuthGraphQLController {

    private final AuthService authService;
    private final UserRepository userRepository;
    private final AdminGuard adminGuard;
    private final PasswordResetService passwordResetService;

    public AuthGraphQLController(
            AuthService authService,
            UserRepository userRepository,
            AdminGuard adminGuard,
            PasswordResetService passwordResetService) {
        this.passwordResetService = passwordResetService;
        this.authService = authService;
        this.userRepository = userRepository;
        this.adminGuard = adminGuard;
    }

    @QueryMapping
    public User me(@ContextValue(name = "userId", required = false) Long userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findById(userId).orElse(null);
    }

    @MutationMapping
    public User updateAvatar(
            @ContextValue(name = "userId", required = false) Long userId, @Argument String avatar) {
        return authService.updateAvatar(userId, avatar);
    }

    @SchemaMapping(typeName = "User", field = "isAdmin")
    public boolean isAdmin(User user) {
        return adminGuard.isAdmin(user);
    }

    @MutationMapping
    public boolean requestPasswordReset(@Argument String email) {
        return passwordResetService.request(email);
    }

    @MutationMapping
    public boolean resetPassword(
            @Argument String email, @Argument String code, @Argument String newPassword) {
        return passwordResetService.reset(email, code, newPassword);
    }

    @MutationMapping
    public AuthPayload register(
            @Argument String email, @Argument String password, @Argument String displayName) {
        return authService.register(email, password, displayName);
    }

    @MutationMapping
    public AuthPayload login(@Argument String email, @Argument String password) {
        return authService.login(email, password);
    }

    @MutationMapping
    public AuthPayload loginWithGoogle(@Argument String idToken) {
        return authService.loginWithGoogle(idToken);
    }

    @MutationMapping
    public AuthPayload loginWithFacebook(@Argument String accessToken) {
        return authService.loginWithFacebook(accessToken);
    }

    @MutationMapping
    public User updateProfile(
            @ContextValue(name = "userId", required = false) Long userId,
            @Argument String displayName,
            @Argument String dob,
            @Argument Gender gender,
            @Argument LearningPurpose learningPurpose,
            @Argument Integer dailyMinutes,
            @Argument StartMode startMode) {
        return authService.updateProfile(
                userId, displayName, dob, gender, learningPurpose, dailyMinutes, startMode);
    }
}

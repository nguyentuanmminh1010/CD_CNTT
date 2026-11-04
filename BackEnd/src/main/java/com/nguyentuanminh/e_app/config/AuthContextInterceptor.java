package com.nguyentuanminh.e_app.config;

import com.nguyentuanminh.e_app.service.JwtService;
import org.springframework.graphql.server.WebGraphQlInterceptor;
import org.springframework.graphql.server.WebGraphQlRequest;
import org.springframework.graphql.server.WebGraphQlResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import reactor.core.publisher.Mono;

/**
 * Đọc header {@code Authorization: Bearer <jwt>}, xác thực và đưa userId vào
 * GraphQLContext để các resolver lấy ra qua {@code @ContextValue("userId")}.
 */
@Component
public class AuthContextInterceptor implements WebGraphQlInterceptor {

    private final JwtService jwtService;

    public AuthContextInterceptor(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    public Mono<WebGraphQlResponse> intercept(WebGraphQlRequest request, Chain chain) {
        String header = request.getHeaders().getFirst("Authorization");
        Long userId = null;
        if (StringUtils.hasText(header) && header.startsWith("Bearer ")) {
            userId = jwtService.parseUserId(header.substring(7).trim());
        }
        if (userId != null) {
            Long finalUserId = userId;
            request.configureExecutionInput((executionInput, builder) ->
                    builder.graphQLContext(ctx -> ctx.put("userId", finalUserId)).build());
        }
        return chain.next(request);
    }
}

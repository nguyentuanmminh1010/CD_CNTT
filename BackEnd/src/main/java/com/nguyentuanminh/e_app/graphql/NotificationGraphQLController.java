package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.service.NotificationService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class NotificationGraphQLController {

    private final NotificationService notificationService;

    @QueryMapping
    public List<String> readNotificationKeys(@ContextValue(name = "userId", required = false) Long userId) {
        return notificationService.readKeys(userId);
    }

    @MutationMapping
    public boolean markNotificationsRead(
            @ContextValue(name = "userId", required = false) Long userId, @Argument List<String> keys) {
        return notificationService.markRead(userId, keys);
    }
}

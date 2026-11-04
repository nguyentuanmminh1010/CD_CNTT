package com.nguyentuanminh.e_app.graphql;

import com.nguyentuanminh.e_app.service.FriendService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.ContextValue;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

/** Bạn bè hai chiều (lời mời/chấp nhận/chặn) — nguồn cho bảng xếp hạng Bạn bè. */
@Controller
@RequiredArgsConstructor
public class SocialGraphQLController {

    private static final String USER = "userId";

    private final FriendService friendService;

    @QueryMapping
    public List<FriendService.PublicUser> searchUsers(
            @ContextValue(name = USER, required = false) Long userId, @Argument String query) {
        return friendService.search(userId, query);
    }

    @QueryMapping
    public List<FriendService.PublicUser> friends(@ContextValue(name = USER, required = false) Long userId) {
        return friendService.friends(userId);
    }

    @QueryMapping
    public List<FriendService.PublicUser> friendRequests(@ContextValue(name = USER, required = false) Long userId) {
        return friendService.friendRequests(userId);
    }

    @QueryMapping
    public List<FriendService.PublicUser> recentFriends(@ContextValue(name = USER, required = false) Long userId) {
        return friendService.recentFriends(userId);
    }

    @QueryMapping
    public List<FriendService.PublicUser> blockedUsers(@ContextValue(name = USER, required = false) Long userId) {
        return friendService.blockedUsers(userId);
    }

    @MutationMapping
    public FriendService.PublicUser sendFriendRequest(
            @ContextValue(name = USER, required = false) Long userId, @Argument(name = "userId") Long targetId) {
        return friendService.sendRequest(userId, targetId);
    }

    @MutationMapping
    public FriendService.PublicUser respondFriendRequest(
            @ContextValue(name = USER, required = false) Long userId,
            @Argument(name = "userId") Long fromUserId,
            @Argument boolean accept) {
        return friendService.respond(userId, fromUserId, accept);
    }

    @MutationMapping
    public FriendService.PublicUser removeFriend(
            @ContextValue(name = USER, required = false) Long userId, @Argument(name = "userId") Long targetId) {
        return friendService.remove(userId, targetId);
    }

    @MutationMapping
    public FriendService.PublicUser blockUser(
            @ContextValue(name = USER, required = false) Long userId, @Argument(name = "userId") Long targetId) {
        return friendService.block(userId, targetId);
    }

    @MutationMapping
    public FriendService.PublicUser unblockUser(
            @ContextValue(name = USER, required = false) Long userId, @Argument(name = "userId") Long targetId) {
        return friendService.unblock(userId, targetId);
    }
}

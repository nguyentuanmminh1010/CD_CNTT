package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.FriendStatus;
import com.nguyentuanminh.e_app.domain.Friendship;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.domain.UserBlock;
import com.nguyentuanminh.e_app.repository.FriendshipRepository;
import com.nguyentuanminh.e_app.repository.UserBlockRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Bạn bè HAI CHIỀU: gửi lời mời → đối phương chấp nhận/từ chối; có thể huỷ kết bạn và chặn.
 * Nguồn cho bảng xếp hạng "Bạn bè" và các thông báo (lời mời mới, lời mời được chấp nhận).
 */
@Service
@RequiredArgsConstructor
public class FriendService {

    /** Quan hệ của người dùng hiện tại với một người khác. */
    public enum Relation {
        NONE,
        REQUEST_SENT,
        REQUEST_RECEIVED,
        FRIEND,
        BLOCKED
    }

    /** Thông tin công khai của một người dùng (không lộ email). */
    public record PublicUser(Long id, String displayName, String avatar, Relation relation) {
    }

    private final FriendshipRepository friendshipRepository;
    private final UserBlockRepository blockRepository;
    private final UserRepository userRepository;

    /** Tìm theo tên hiển thị (chứa chuỗi) hoặc đúng email; loại chính mình và những người đã chặn mình. */
    @Transactional(readOnly = true)
    public List<PublicUser> search(Long userId, String query) {
        requireUser(userId);
        if (query == null || query.trim().length() < 2) {
            return List.of();
        }
        String q = query.trim();
        Map<Long, Relation> relations = relationMap(userId);
        Set<Long> blockedMe = new HashSet<>(blockRepository.findBlockerIdsOf(userId));
        Map<Long, User> found = new LinkedHashMap<>();
        for (User u : userRepository.findTop10ByDisplayNameContainingIgnoreCaseOrEmailIgnoreCase(q, q)) {
            if (!u.getId().equals(userId) && !blockedMe.contains(u.getId())) found.put(u.getId(), u);
        }
        return found.values().stream()
                .map(u -> toPublic(u, relations.getOrDefault(u.getId(), Relation.NONE)))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PublicUser> friends(Long userId) {
        requireUser(userId);
        return friendshipRepository.findInvolving(userId).stream()
                .filter(f -> f.getStatus() == FriendStatus.ACCEPTED)
                .map(f -> toPublic(other(f, userId), Relation.FRIEND))
                .toList();
    }

    /** Lời mời kết bạn đang chờ bạn trả lời. */
    @Transactional(readOnly = true)
    public List<PublicUser> friendRequests(Long userId) {
        requireUser(userId);
        Set<Long> blocked = blockedIds(userId);
        return friendshipRepository.findByAddresseeIdAndStatusOrderByCreatedAtDesc(userId, FriendStatus.PENDING)
                .stream()
                .filter(f -> !blocked.contains(f.getRequester().getId()))
                .map(f -> toPublic(f.getRequester(), Relation.REQUEST_RECEIVED))
                .toList();
    }

    /** Bạn mới trong 7 ngày qua do ĐỐI PHƯƠNG chấp nhận lời mời của bạn — nguồn cho thông báo. */
    @Transactional(readOnly = true)
    public List<PublicUser> recentFriends(Long userId) {
        requireUser(userId);
        return friendshipRepository
                .findByRequesterIdAndStatusAndRespondedAtAfterOrderByRespondedAtDesc(
                        userId, FriendStatus.ACCEPTED, Instant.now().minus(Duration.ofDays(7)))
                .stream()
                .map(f -> toPublic(f.getAddressee(), Relation.FRIEND))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PublicUser> blockedUsers(Long userId) {
        requireUser(userId);
        return blockRepository.findByBlockerIdOrderByCreatedAtDesc(userId).stream()
                .map(b -> toPublic(b.getBlocked(), Relation.BLOCKED))
                .toList();
    }

    /** Gửi lời mời; nếu đối phương đã mời bạn từ trước thì hai bên thành bạn luôn. */
    @Transactional
    public PublicUser sendRequest(Long userId, Long targetId) {
        requireUser(userId);
        if (userId.equals(targetId)) {
            throw new IllegalArgumentException("Bạn không thể kết bạn với chính mình.");
        }
        User target = userRepository.findById(targetId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + targetId));
        if (blockRepository.existsBetween(userId, targetId)) {
            // Không nói rõ ai chặn ai để không lộ việc bị chặn.
            throw new IllegalStateException("Không thể gửi lời mời cho người dùng này.");
        }
        var existing = friendshipRepository.findBetween(userId, targetId);
        if (existing.isPresent()) {
            Friendship f = existing.get();
            if (f.getStatus() == FriendStatus.ACCEPTED) {
                return toPublic(target, Relation.FRIEND);
            }
            if (f.getRequester().getId().equals(userId)) {
                return toPublic(target, Relation.REQUEST_SENT);
            }
            accept(f);
            return toPublic(target, Relation.FRIEND);
        }
        Friendship f = new Friendship();
        f.setRequester(userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId)));
        f.setAddressee(target);
        friendshipRepository.save(f);
        return toPublic(target, Relation.REQUEST_SENT);
    }

    /** Trả lời lời mời của [fromUserId]: chấp nhận hoặc từ chối (xoá lời mời). */
    @Transactional
    public PublicUser respond(Long userId, Long fromUserId, boolean accept) {
        requireUser(userId);
        Friendship f = friendshipRepository.findBetween(userId, fromUserId)
                .filter(x -> x.getStatus() == FriendStatus.PENDING && x.getAddressee().getId().equals(userId))
                .orElseThrow(() -> new NoSuchElementException("Không có lời mời kết bạn từ người này."));
        User from = f.getRequester();
        if (accept) {
            accept(f);
            return toPublic(from, Relation.FRIEND);
        }
        friendshipRepository.delete(f);
        return toPublic(from, Relation.NONE);
    }

    /** Huỷ kết bạn, hoặc thu hồi lời mời bạn đã gửi. */
    @Transactional
    public PublicUser remove(Long userId, Long targetId) {
        requireUser(userId);
        User target = userRepository.findById(targetId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + targetId));
        friendshipRepository.findBetween(userId, targetId).ifPresent(f -> {
            // Lời mời người khác gửi cho bạn thì dùng respond(accept=false), không xoá ở đây.
            if (f.getStatus() == FriendStatus.ACCEPTED || f.getRequester().getId().equals(userId)) {
                friendshipRepository.delete(f);
            }
        });
        friendshipRepository.flush();
        return toPublic(target, relationMap(userId).getOrDefault(targetId, Relation.NONE));
    }

    @Transactional
    public PublicUser block(Long userId, Long targetId) {
        requireUser(userId);
        if (userId.equals(targetId)) {
            throw new IllegalArgumentException("Bạn không thể chặn chính mình.");
        }
        User target = userRepository.findById(targetId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + targetId));
        friendshipRepository.findBetween(userId, targetId).ifPresent(friendshipRepository::delete);
        if (blockRepository.findByBlockerIdAndBlockedId(userId, targetId).isEmpty()) {
            UserBlock b = new UserBlock();
            b.setBlocker(userRepository.findById(userId)
                    .orElseThrow(() -> new NoSuchElementException("User not found: " + userId)));
            b.setBlocked(target);
            blockRepository.save(b);
        }
        return toPublic(target, Relation.BLOCKED);
    }

    @Transactional
    public PublicUser unblock(Long userId, Long targetId) {
        requireUser(userId);
        User target = userRepository.findById(targetId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + targetId));
        blockRepository.findByBlockerIdAndBlockedId(userId, targetId).ifPresent(blockRepository::delete);
        return toPublic(target, Relation.NONE);
    }

    /** Id bạn bè (đã chấp nhận) của [userId] — nguồn cho bảng xếp hạng Bạn bè. */
    @Transactional(readOnly = true)
    public Set<Long> friendIds(Long userId) {
        Set<Long> ids = new HashSet<>();
        for (Friendship f : friendshipRepository.findInvolving(userId)) {
            if (f.getStatus() == FriendStatus.ACCEPTED) ids.add(other(f, userId).getId());
        }
        return ids;
    }

    private void accept(Friendship f) {
        f.setStatus(FriendStatus.ACCEPTED);
        f.setRespondedAt(Instant.now());
        friendshipRepository.save(f);
    }

    private Map<Long, Relation> relationMap(Long userId) {
        Map<Long, Relation> map = new HashMap<>();
        for (Friendship f : friendshipRepository.findInvolving(userId)) {
            Long otherId = other(f, userId).getId();
            if (f.getStatus() == FriendStatus.ACCEPTED) {
                map.put(otherId, Relation.FRIEND);
            } else {
                map.put(otherId, f.getRequester().getId().equals(userId)
                        ? Relation.REQUEST_SENT : Relation.REQUEST_RECEIVED);
            }
        }
        blockRepository.findByBlockerIdOrderByCreatedAtDesc(userId)
                .forEach(b -> map.put(b.getBlocked().getId(), Relation.BLOCKED));
        return map;
    }

    private Set<Long> blockedIds(Long userId) {
        Set<Long> ids = new HashSet<>(blockRepository.findBlockerIdsOf(userId));
        blockRepository.findByBlockerIdOrderByCreatedAtDesc(userId).forEach(b -> ids.add(b.getBlocked().getId()));
        return ids;
    }

    private static User other(Friendship f, Long userId) {
        return f.getRequester().getId().equals(userId) ? f.getAddressee() : f.getRequester();
    }

    private static PublicUser toPublic(User u, Relation relation) {
        return new PublicUser(u.getId(), u.getDisplayName(), u.getAvatar(), relation);
    }

    private static void requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập.");
        }
    }
}

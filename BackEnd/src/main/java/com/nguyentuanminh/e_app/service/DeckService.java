package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.DeckGift;
import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.domain.User;
import com.nguyentuanminh.e_app.repository.AttemptAnswerRepository;
import com.nguyentuanminh.e_app.repository.DeckGiftRepository;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import com.nguyentuanminh.e_app.repository.TopicReviewRepository;
import com.nguyentuanminh.e_app.repository.UserLearningItemProgressRepository;
import com.nguyentuanminh.e_app.repository.UserRepository;
import com.nguyentuanminh.e_app.repository.UserTopicMasteryRepository;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Quản lý nội dung: người dùng tạo/sửa/xoá "bộ thẻ" (chủ đề + thẻ) của riêng mình; admin sửa
 * được cả nội dung chủ đề HỆ THỐNG (thêm/sửa/xoá thẻ, đổi tên/mô tả — nhưng không xoá chủ đề
 * hệ thống vì khoá học đang trỏ tới).
 */
@Service
@RequiredArgsConstructor
public class DeckService {

    private final LearningTopicRepository topicRepository;
    private final LearningItemRepository itemRepository;
    private final UserLearningItemProgressRepository progressRepository;
    private final UserTopicMasteryRepository masteryRepository;
    private final AttemptAnswerRepository answerRepository;
    private final TopicReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final AdminGuard adminGuard;
    private final DeckGiftRepository giftRepository;
    private final FriendService friendService;

    @Transactional(readOnly = true)
    public List<LearningTopic> myDecks(Long userId) {
        requireUser(userId);
        return topicRepository.findByOwnerIdOrderByIdDesc(userId);
    }

    /** Admin: toàn bộ chủ đề hệ thống (mọi category) để quản lý nội dung. */
    @Transactional(readOnly = true)
    public List<LearningTopic> systemTopics(Long userId) {
        adminGuard.require(userId);
        return topicRepository.findByOwnerIsNullOrderByCategoryAscIdAsc();
    }

    @Transactional
    public LearningTopic createDeck(Long userId, String name, String description, LearningCategory category, String icon) {
        requireUser(userId);
        String cleanName = requireText(name, "Tên bộ thẻ không được để trống.", 100);
        User owner = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        LearningTopic topic = new LearningTopic(null, cleanName, trimToNull(description, 255),
                icon == null || icon.isBlank() ? "style_rounded" : icon.trim(),
                category == null ? LearningCategory.VOCABULARY : category);
        topic.setOwner(owner);
        return topicRepository.save(topic);
    }

    @Transactional
    public LearningTopic updateTopic(Long userId, Long topicId, String name, String description, String guide) {
        LearningTopic topic = editableTopic(userId, topicId);
        if (name != null) topic.setName(requireText(name, "Tên không được để trống.", 100));
        if (description != null) topic.setDescription(trimToNull(description, 255));
        if (guide != null) topic.setGuide(trimToNull(guide, 4000));
        return topicRepository.save(topic);
    }

    /** Xoá bộ thẻ riêng cùng toàn bộ thẻ, tiến độ, câu trả lời, đánh giá liên quan. */
    @Transactional
    public boolean deleteTopic(Long userId, Long topicId) {
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        requireUser(userId);
        if (topic.getOwner() == null || !topic.getOwner().getId().equals(userId)) {
            throw new IllegalStateException("Chỉ xoá được bộ thẻ do chính bạn tạo.");
        }
        progressRepository.deleteByItemTopicId(topicId);
        answerRepository.deleteByItemTopicId(topicId);
        masteryRepository.deleteByTopicId(topicId);
        reviewRepository.deleteByTopicId(topicId);
        giftRepository.deleteByTopicId(topicId);
        itemRepository.deleteByTopicId(topicId);
        topicRepository.delete(topic);
        return true;
    }

    @Transactional
    public LearningItem addItem(
            Long userId, Long topicId, String term, String phonetic, String meaning, String example, Integer difficulty,
            String explanation, String imageUrl, String audioUrl) {
        LearningTopic topic = editableTopic(userId, topicId);
        LearningItem item = new LearningItem();
        item.setTopic(topic);
        apply(item, term, phonetic, meaning, example, difficulty, explanation, imageUrl, audioUrl);
        return itemRepository.save(item);
    }

    @Transactional
    public LearningItem updateItem(
            Long userId, Long itemId, String term, String phonetic, String meaning, String example, Integer difficulty,
            String explanation, String imageUrl, String audioUrl) {
        LearningItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new NoSuchElementException("LearningItem not found: " + itemId));
        editableTopic(userId, item.getTopic().getId());
        apply(item, term, phonetic, meaning, example, difficulty, explanation, imageUrl, audioUrl);
        return itemRepository.save(item);
    }

    @Transactional
    public boolean deleteItem(Long userId, Long itemId) {
        LearningItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new NoSuchElementException("LearningItem not found: " + itemId));
        editableTopic(userId, item.getTopic().getId());
        progressRepository.deleteByItemId(itemId);
        answerRepository.deleteByItemId(itemId);
        itemRepository.delete(item);
        return true;
    }

    // ---- Nhập hàng loạt ----

    public record ImportResult(int added, int skipped, List<String> errors) {
    }

    private static final int MAX_IMPORT_LINES = 500;

    /**
     * Nhập nhiều thẻ từ văn bản dán vào: mỗi dòng {@code term | nghĩa | ví dụ | phiên âm} (ví dụ và phiên âm
     * tuỳ chọn). Dấu phân cách: Tab (dán từ Excel/Sheets), {@code ;} hoặc {@code |}; không có thì tách theo dấu phẩy
     * (chỉ 3 cột term, nghĩa, ví dụ — dấu phẩy trong ví dụ được giữ). Dòng trống bị bỏ qua, từ trùng (không phân biệt hoa-thường) bị bỏ qua.
     */
    @Transactional
    public ImportResult importItems(Long userId, Long topicId, String text) {
        LearningTopic topic = editableTopic(userId, topicId);
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("Hãy dán danh sách thẻ cần nhập.");
        }
        Set<String> existing = new HashSet<>();
        for (LearningItem it : itemRepository.findByTopicIdOrderByDifficultyLevelAscIdAsc(topicId)) {
            existing.add(it.getTerm().trim().toLowerCase());
        }
        List<LearningItem> toSave = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        int skipped = 0;
        String[] lines = text.split("\\r?\\n");
        int seen = 0;
        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();
            if (line.isEmpty()) continue;
            if (++seen > MAX_IMPORT_LINES) {
                errors.add("Chỉ nhập tối đa " + MAX_IMPORT_LINES + " dòng mỗi lần — các dòng còn lại bị bỏ qua.");
                break;
            }
            String[] parts = splitLine(line);
            if (seen == 1 && isHeader(parts)) {
                seen = 0;
                continue;
            }
            String term = parts.length > 0 ? parts[0].trim() : "";
            String meaning = parts.length > 1 ? parts[1].trim() : "";
            if (term.isEmpty() || meaning.isEmpty()) {
                errors.add("Dòng " + (i + 1) + ": cần có đủ từ và nghĩa.");
                continue;
            }
            if (!existing.add(term.toLowerCase())) {
                skipped++;
                continue;
            }
            LearningItem item = new LearningItem();
            item.setTopic(topic);
            item.setTerm(term.length() > 255 ? term.substring(0, 255) : term);
            item.setMeaning(meaning.length() > 500 ? meaning.substring(0, 500) : meaning);
            item.setExample(parts.length > 2 ? trimToNull(parts[2], 255) : null);
            item.setPhonetic(parts.length > 3 ? trimToNull(parts[3], 255) : null);
            toSave.add(item);
        }
        itemRepository.saveAll(toSave);
        return new ImportResult(toSave.size(), skipped, errors);
    }

    /** Dòng tiêu đề của file CSV (do chức năng xuất tạo ra hoặc tự soạn): "term, meaning, ..." / "từ, nghĩa, ...". */
    private static boolean isHeader(String[] parts) {
        if (parts.length < 2) return false;
        String a = parts[0].trim().toLowerCase();
        String b = parts[1].trim().toLowerCase();
        return (a.equals("term") || a.equals("từ") || a.equals("word")) && (b.equals("meaning") || b.equals("nghĩa"));
    }

    /**
     * Tách một dòng. Dòng bắt đầu bằng dấu {@code "} được hiểu là CSV chuẩn (RFC 4180: trường đặt trong ngoặc kép,
     * {@code ""} là một dấu ngoặc kép) — định dạng của chức năng xuất bộ thẻ nên xuất rồi nhập lại không mất dữ liệu.
     */
    static String[] splitLine(String line) {
        if (line.startsWith("\"")) return parseQuotedCsv(line);
        for (String sep : new String[] {"\t", ";", "|"}) {
            if (line.contains(sep)) return line.split(java.util.regex.Pattern.quote(sep), -1);
        }
        // CSV đơn giản: tối đa 3 cột term, nghĩa, ví dụ — dấu phẩy trong câu ví dụ được giữ nguyên.
        return line.split(",", 3);
    }

    private static String[] parseQuotedCsv(String line) {
        List<String> fields = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (quoted) {
                if (c == '"') {
                    if (i + 1 < line.length() && line.charAt(i + 1) == '"') {
                        cur.append('"');
                        i++;
                    } else {
                        quoted = false;
                    }
                } else {
                    cur.append(c);
                }
            } else if (c == '"') {
                quoted = true;
            } else if (c == ',') {
                fields.add(cur.toString());
                cur.setLength(0);
            } else {
                cur.append(c);
            }
        }
        fields.add(cur.toString());
        return fields.toArray(new String[0]);
    }

    // ---- Chia sẻ bộ thẻ ----

    /** Bản xem trước bộ thẻ được chia sẻ qua mã. */
    public record SharedDeck(String code, String name, String description, LearningCategory category,
                             int wordCount, String ownerName) {
    }

    private static final String CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();

    /** Bật chia sẻ cho bộ thẻ riêng của bạn và trả mã (giữ nguyên mã nếu đã chia sẻ). */
    @Transactional
    public String shareDeck(Long userId, Long topicId) {
        LearningTopic topic = ownedDeck(userId, topicId);
        if (topic.getShareCode() == null) {
            String code;
            do {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < 8; i++) sb.append(CODE_ALPHABET.charAt(random.nextInt(CODE_ALPHABET.length())));
                code = sb.toString();
            } while (topicRepository.findByShareCode(code).isPresent());
            topic.setShareCode(code);
            topicRepository.save(topic);
        }
        return topic.getShareCode();
    }

    /** Tắt chia sẻ — mã cũ không còn dùng được (những bản đã sao chép thì vẫn giữ). */
    @Transactional
    public boolean unshareDeck(Long userId, Long topicId) {
        LearningTopic topic = ownedDeck(userId, topicId);
        topic.setShareCode(null);
        topicRepository.save(topic);
        return true;
    }

    @Transactional(readOnly = true)
    public SharedDeck sharedDeck(Long userId, String code) {
        requireUser(userId);
        LearningTopic topic = bySharedCode(code);
        return new SharedDeck(topic.getShareCode(), topic.getName(), topic.getDescription(), topic.getCategory(),
                (int) itemRepository.countByTopicId(topic.getId()), topic.getOwner().getDisplayName());
    }

    /** Sao chép bộ thẻ được chia sẻ (cùng toàn bộ thẻ) thành bộ thẻ riêng mới của bạn. */
    @Transactional
    public LearningTopic importSharedDeck(Long userId, String code) {
        requireUser(userId);
        return copyDeck(bySharedCode(code), userId);
    }

    private LearningTopic copyDeck(LearningTopic source, Long userId) {
        User me = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));
        LearningTopic copy = new LearningTopic(null, source.getName(), source.getDescription(), source.getIcon(),
                source.getCategory());
        copy.setGuide(source.getGuide());
        copy.setOwner(me);
        copy = topicRepository.save(copy);
        List<LearningItem> items = new ArrayList<>();
        for (LearningItem it : itemRepository.findByTopicIdOrderByDifficultyLevelAscIdAsc(source.getId())) {
            LearningItem c = new LearningItem();
            c.setTopic(copy);
            c.setTerm(it.getTerm());
            c.setPhonetic(it.getPhonetic());
            c.setMeaning(it.getMeaning());
            c.setExample(it.getExample());
            c.setExplanation(it.getExplanation());
            c.setImageUrl(it.getImageUrl());
            c.setAudioUrl(it.getAudioUrl());
            c.setDifficultyLevel(it.getDifficultyLevel());
            items.add(c);
        }
        itemRepository.saveAll(items);
        return copy;
    }

    // ---- Gửi bộ thẻ riêng cho một người bạn ----

    /** Bộ thẻ đang chờ bạn nhận (hiện ở thông báo). */
    public record DeckGiftView(Long id, String name, int wordCount, String senderName, String createdAt) {
    }

    /** Gửi bộ thẻ riêng của bạn cho một người BẠN BÈ; gửi lại khi bản trước còn chờ thì không tạo thêm. */
    @Transactional
    public boolean sendToFriend(Long userId, Long topicId, Long friendId) {
        LearningTopic topic = ownedDeck(userId, topicId);
        if (friendId == null || !friendService.friendIds(userId).contains(friendId)) {
            throw new IllegalStateException("Chỉ gửi được bộ thẻ cho người đã là bạn bè của bạn.");
        }
        if (giftRepository.findByTopicIdAndRecipientIdAndStatus(topicId, friendId, DeckGift.Status.PENDING).isEmpty()) {
            DeckGift gift = new DeckGift();
            gift.setTopic(topic);
            gift.setSender(topic.getOwner());
            gift.setRecipient(userRepository.findById(friendId)
                    .orElseThrow(() -> new NoSuchElementException("User not found: " + friendId)));
            giftRepository.save(gift);
        }
        return true;
    }

    @Transactional(readOnly = true)
    public List<DeckGiftView> receivedGifts(Long userId) {
        requireUser(userId);
        List<DeckGiftView> out = new ArrayList<>();
        for (DeckGift g : giftRepository.findByRecipientIdAndStatusOrderByCreatedAtDesc(userId, DeckGift.Status.PENDING)) {
            out.add(new DeckGiftView(g.getId(), g.getTopic().getName(), (int) itemRepository.countByTopicId(g.getTopic().getId()),
                    g.getSender().getDisplayName(), g.getCreatedAt().toString()));
        }
        return out;
    }

    /** Nhận (sao chép về thành bộ thẻ riêng, trả về bộ thẻ mới) hoặc từ chối (trả null) bộ thẻ được gửi. */
    @Transactional
    public LearningTopic respondGift(Long userId, Long giftId, boolean accept) {
        requireUser(userId);
        DeckGift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy bộ thẻ được gửi."));
        if (!gift.getRecipient().getId().equals(userId) || gift.getStatus() != DeckGift.Status.PENDING) {
            throw new IllegalStateException("Bộ thẻ này không còn chờ bạn nhận.");
        }
        if (!accept) {
            gift.setStatus(DeckGift.Status.DECLINED);
            giftRepository.save(gift);
            return null;
        }
        LearningTopic copy = copyDeck(gift.getTopic(), userId);
        gift.setStatus(DeckGift.Status.ACCEPTED);
        giftRepository.save(gift);
        return copy;
    }

    private LearningTopic bySharedCode(String code) {
        String clean = code == null ? "" : code.trim().toUpperCase();
        return topicRepository.findByShareCode(clean)
                .filter(t -> t.getOwner() != null)
                .orElseThrow(() -> new NoSuchElementException("Mã chia sẻ không đúng hoặc bộ thẻ đã ngừng chia sẻ."));
    }

    private LearningTopic ownedDeck(Long userId, Long topicId) {
        requireUser(userId);
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        if (topic.getOwner() == null || !topic.getOwner().getId().equals(userId)) {
            throw new IllegalStateException("Chỉ chia sẻ được bộ thẻ do chính bạn tạo.");
        }
        return topic;
    }

    /** Người dùng sửa được bộ thẻ của mình; admin sửa được chủ đề hệ thống. */
    public boolean canEdit(LearningTopic topic, Long userId) {
        if (userId == null) return false;
        if (topic.getOwner() != null) return topic.getOwner().getId().equals(userId);
        return userRepository.findById(userId).map(adminGuard::isAdmin).orElse(false);
    }

    private LearningTopic editableTopic(Long userId, Long topicId) {
        requireUser(userId);
        LearningTopic topic = topicRepository.findById(topicId)
                .orElseThrow(() -> new NoSuchElementException("Topic not found: " + topicId));
        if (!canEdit(topic, userId)) {
            throw new IllegalStateException("Bạn không có quyền sửa chủ đề này.");
        }
        return topic;
    }

    private void apply(LearningItem item, String term, String phonetic, String meaning, String example, Integer difficulty,
            String explanation, String imageUrl, String audioUrl) {
        item.setTerm(requireText(term, "Từ/cụm từ không được để trống.", 255));
        item.setMeaning(requireText(meaning, "Nghĩa không được để trống.", 500));
        item.setPhonetic(trimToNull(phonetic, 255));
        item.setExample(trimToNull(example, 255));
        item.setExplanation(trimToNull(explanation, 2000));
        item.setImageUrl(cleanImage(imageUrl));
        item.setAudioUrl(cleanHttpUrl(audioUrl, "Link audio"));
        int level = difficulty == null ? item.getDifficultyLevel() : difficulty;
        if (level < 1 || level > 3) {
            throw new IllegalArgumentException("Độ khó phải từ 1 đến 3.");
        }
        item.setDifficultyLevel(level);
    }

    /** Ảnh: URL http(s) hoặc data URL base64 (ảnh người dùng chọn — đã thu nhỏ ở client, tối đa ~300KB). */
    private static String cleanImage(String value) {
        if (value == null || value.isBlank()) return null;
        String v = value.trim();
        if (v.startsWith("data:image/")) {
            if (v.length() > 400_000) throw new IllegalArgumentException("Ảnh quá lớn (tối đa ~300KB).");
            return v;
        }
        return cleanHttpUrl(v, "Link ảnh");
    }

    private static String cleanHttpUrl(String value, String label) {
        if (value == null || value.isBlank()) return null;
        String v = value.trim();
        if (!(v.startsWith("http://") || v.startsWith("https://")) || v.length() > 500) {
            throw new IllegalArgumentException(label + " phải bắt đầu bằng http:// hoặc https:// (tối đa 500 ký tự).");
        }
        return v;
    }

    private static String requireText(String value, String message, int max) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        String v = value.trim();
        return v.length() > max ? v.substring(0, max) : v;
    }

    private static String trimToNull(String value, int max) {
        if (value == null || value.isBlank()) return null;
        String v = value.trim();
        return v.length() > max ? v.substring(0, max) : v;
    }

    private static void requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Bạn cần đăng nhập.");
        }
    }
}

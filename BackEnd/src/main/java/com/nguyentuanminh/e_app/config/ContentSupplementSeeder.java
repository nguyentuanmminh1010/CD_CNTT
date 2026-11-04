package com.nguyentuanminh.e_app.config;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Nội dung bổ sung cho kho chung (04/11/2026): Mẫu câu độ khó 3 + mỗi chủ đề Mẫu câu ít nhất 6 câu, thêm điểm ngữ
 * pháp vào các chủ đề cũ và 4 chủ đề ngữ pháp mới.
 *
 * <p>Khác {@link LearningContentSeeder} (chỉ chạy khi DB trống), lớp này chạy MỖI lần khởi động và chỉ thêm phần
 * còn thiếu: chủ đề kho chung tra theo (category, tên) — chưa có thì tạo; mục tra theo {@code term} (không phân biệt
 * hoa thường) trong chủ đề — đã có thì bỏ qua. Nhờ vậy DB đang dùng cũng nhận được nội dung mới, chạy lại không
 * thêm trùng, và mục admin đã sửa không bị ghi đè. Chạy sau seeder nội dung gốc ({@code @Order(1)}) và trước
 * {@link CourseSeeder} ({@code @Order(3)}, tạo khoá "Ngữ pháp nâng cao" từ 4 chủ đề mới) và {@link GuideSeeder}
 * ({@code @Order(4)}) để chủ đề mới có hướng dẫn mặc định.
 *
 * <p>Chủ đề ngữ pháp mới KHÔNG được thêm vào khoá học "Ngữ pháp nền tảng" ({@link CourseSeeder} gắn Unit theo tên cố
 * định): thêm Unit vào khoá đã có sẽ làm khoá của người đã hoàn thành bị tính lại là chưa xong.
 */
@Component
@Order(2)
public class ContentSupplementSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(ContentSupplementSeeder.class);

    private final LearningTopicRepository topicRepository;
    private final LearningItemRepository itemRepository;

    public ContentSupplementSeeder(LearningTopicRepository topicRepository, LearningItemRepository itemRepository) {
        this.topicRepository = topicRepository;
        this.itemRepository = itemRepository;
    }

    record Seed(String term, String meaning, String example, int level) {
    }

    /** Một chủ đề kho chung và các mục cần có trong đó. */
    record TopicSeed(LearningCategory category, String name, String description, String icon, List<Seed> items) {
    }

    private static Seed s(String term, String meaning, String example, int level) {
        return new Seed(term, meaning, example, level);
    }

    @Override
    public void run(String... args) {
        // DB trống nghĩa là LearningContentSeeder chưa chạy/đã lỗi — không tạo chủ đề rời rạc.
        if (topicRepository.count() == 0) {
            return;
        }
        List<LearningTopic> shared = topicRepository.findByOwnerIsNullOrderByCategoryAscIdAsc();
        int added = 0;
        int createdTopics = 0;
        for (TopicSeed t : supplements()) {
            LearningTopic topic = shared.stream()
                    .filter(x -> x.getCategory() == t.category() && t.name().equals(x.getName()))
                    .findFirst()
                    .orElse(null);
            if (topic == null) {
                topic = topicRepository.save(new LearningTopic(null, t.name(), t.description(), t.icon(), t.category()));
                createdTopics++;
            }
            Set<String> existing = itemRepository.findByTopicIdOrderByDifficultyLevelAscIdAsc(topic.getId()).stream()
                    .map(i -> i.getTerm().trim().toLowerCase(Locale.ROOT))
                    .collect(Collectors.toSet());
            List<LearningItem> toSave = new ArrayList<>();
            for (Seed seed : t.items()) {
                if (!existing.add(seed.term().trim().toLowerCase(Locale.ROOT))) {
                    continue;
                }
                LearningItem item = new LearningItem();
                item.setTerm(seed.term());
                item.setMeaning(seed.meaning());
                item.setExample(seed.example());
                item.setDifficultyLevel(seed.level());
                item.setTopic(topic);
                toSave.add(item);
            }
            itemRepository.saveAll(toSave);
            added += toSave.size();
        }
        if (added > 0 || createdTopics > 0) {
            log.info("Bổ sung nội dung kho chung: {} chủ đề mới, {} mục mới.", createdTopics, added);
        }
    }

    static List<TopicSeed> supplements() {
        LearningCategory sen = LearningCategory.SENTENCE;
        LearningCategory gr = LearningCategory.GRAMMAR;
        return List.of(
                // ---------------- MẪU CÂU: thêm câu độ khó 3, mỗi chủ đề >= 6 câu ----------------
                new TopicSeed(sen, "Chào hỏi", "Mẫu câu chào hỏi thông dụng", "waving_hand_rounded", List.of(
                        s("It's been ages since we last caught up.", "Lâu lắm rồi chúng ta mới gặp lại nhau.",
                                "It's been ages since we last caught up! How's your family?", 3),
                        s("I hope everything's been going well for you.", "Hy vọng mọi việc của bạn vẫn suôn sẻ.",
                                "I hope everything's been going well for you since you moved.", 3))),
                new TopicSeed(sen, "Giới thiệu bản thân", "Mẫu câu tự giới thiệu", "badge_rounded", List.of(
                        s("I've been passionate about languages since I was a child.",
                                "Tôi đam mê ngôn ngữ từ khi còn nhỏ.",
                                "I've been passionate about languages since I was a child, so I study English.", 3),
                        s("What I enjoy most about my job is meeting new people.",
                                "Điều tôi thích nhất ở công việc là được gặp gỡ người mới.",
                                "What I enjoy most about my job is meeting new people every day.", 3))),
                new TopicSeed(sen, "Tại nhà hàng", "Mẫu câu khi đi ăn ở nhà hàng", "restaurant_menu_rounded", List.of(
                        s("Could you recommend something that isn't too heavy?",
                                "Bạn gợi ý giúp món nào không quá nặng bụng được không?",
                                "Could you recommend something that isn't too heavy for lunch?", 3),
                        s("I'm afraid there's been a mistake with our order.",
                                "E là món chúng tôi gọi đã bị nhầm rồi.",
                                "Excuse me, I'm afraid there's been a mistake with our order.", 3))),
                new TopicSeed(sen, "Tại sân bay", "Mẫu câu khi đi máy bay", "flight_rounded", List.of(
                        s("My connecting flight has been cancelled. What are my options?",
                                "Chuyến bay nối chuyến của tôi bị huỷ. Tôi có những lựa chọn nào?",
                                "My connecting flight has been cancelled. What are my options now?", 3),
                        s("My luggage didn't arrive, so I'd like to file a claim.",
                                "Hành lý của tôi không đến nên tôi muốn làm đơn khiếu nại.",
                                "My luggage didn't arrive, so I'd like to file a claim, please.", 3))),
                new TopicSeed(sen, "Mua sắm", "Mẫu câu khi đi mua sắm", "local_mall_rounded", List.of(
                        s("Would it be possible to get a refund without a receipt?",
                                "Có thể hoàn tiền mà không cần hoá đơn không?",
                                "Would it be possible to get a refund without a receipt?", 3),
                        s("Is there any chance you could give me a discount?",
                                "Bạn có thể giảm giá cho tôi một chút được không?",
                                "I'm buying three. Is there any chance you could give me a discount?", 3))),
                new TopicSeed(sen, "Hỏi đường", "Mẫu câu hỏi và chỉ đường", "signpost_rounded", List.of(
                        s("Which bus goes to the city centre?", "Xe buýt nào đi vào trung tâm thành phố?",
                                "Excuse me, which bus goes to the city centre?", 2),
                        s("Would you mind telling me the quickest way to the hospital?",
                                "Phiền bạn chỉ giúp tôi đường nhanh nhất đến bệnh viện được không?",
                                "Would you mind telling me the quickest way to the hospital?", 3),
                        s("I think I'm lost. Could you point me in the right direction?",
                                "Hình như tôi bị lạc. Bạn chỉ giúp tôi đúng hướng được không?",
                                "I think I'm lost. Could you point me in the right direction?", 3))),
                new TopicSeed(sen, "Công sở", "Mẫu câu giao tiếp nơi công sở", "business_center_rounded", List.of(
                        s("Let me check my schedule and get back to you.", "Để tôi xem lịch rồi trả lời bạn sau.",
                                "Let me check my schedule and get back to you this afternoon.", 2),
                        s("Would it be possible to push the deadline back a few days?",
                                "Có thể lùi hạn chót lại vài ngày được không?",
                                "Would it be possible to push the deadline back a few days?", 3),
                        s("I'd like to follow up on the proposal I sent last week.",
                                "Tôi muốn hỏi thêm về bản đề xuất tôi gửi tuần trước.",
                                "Hi Nam, I'd like to follow up on the proposal I sent last week.", 3))),
                new TopicSeed(sen, "Điện thoại", "Mẫu câu gọi điện thoại", "call_rounded", List.of(
                        s("Could you speak a little more slowly, please?", "Bạn nói chậm lại một chút được không?",
                                "Sorry, could you speak a little more slowly, please?", 2),
                        s("I'm afraid he's in a meeting. Can I take a message?",
                                "E là anh ấy đang họp. Tôi nhận lời nhắn giúp nhé?",
                                "I'm afraid he's in a meeting. Can I take a message?", 3),
                        s("Sorry, the line is breaking up. Could you repeat that?",
                                "Xin lỗi, đường truyền bị ngắt quãng. Bạn nhắc lại được không?",
                                "Sorry, the line is breaking up. Could you repeat that?", 3))),

                // ---------------- NGỮ PHÁP: thêm điểm vào chủ đề cũ ----------------
                new TopicSeed(gr, "Thì hiện tại", "Present Simple, Continuous, Perfect", "schedule_rounded", List.of(
                        s("Present Perfect - ever/never",
                                "Hỏi/kể trải nghiệm từ trước tới nay: Have you ever + V3? / S + have never + V3.",
                                "Have you ever been to Japan?", 2))),
                new TopicSeed(gr, "Thì quá khứ", "Past Simple, Continuous, Perfect", "history_rounded", List.of(
                        s("Was/were going to", "Dự định trong quá khứ nhưng đã không thực hiện.",
                                "I was going to call you, but I forgot.", 3))),
                new TopicSeed(gr, "Thì tương lai", "Future Simple, Be going to, Future Perfect", "update_rounded", List.of(
                        s("Present Simple for timetables", "Dùng hiện tại đơn cho lịch trình, thời khoá biểu cố định.",
                                "The train leaves at 7 a.m. tomorrow.", 2),
                        s("Be about to", "Sắp sửa xảy ra ngay lập tức. CT: S + am/is/are about to + V.",
                                "Hurry up, the film is about to start.", 2),
                        s("Future Perfect Continuous",
                                "Nhấn mạnh thời gian kéo dài tới 1 mốc tương lai. CT: S + will have been + V-ing.",
                                "By June, I will have been working here for ten years.", 3))),
                new TopicSeed(gr, "Câu điều kiện", "Conditional sentences type 0-3", "alt_route_rounded", List.of(
                        s("Unless", "Unless = if not: trừ khi.", "You will miss the bus unless you hurry.", 2),
                        s("Wish + past simple", "Ước điều trái với hiện tại. CT: S + wish + S + V2/ed.",
                                "I wish I spoke French fluently.", 3),
                        s("Inversion in conditionals",
                                "Đảo ngữ câu điều kiện loại 3: Had + S + V3 thay cho If + S + had + V3.",
                                "Had I known about the meeting, I would have come.", 3))),
                new TopicSeed(gr, "Câu bị động", "Passive voice ở các thì khác nhau", "swap_horiz_rounded", List.of(
                        s("Passive - Future Simple", "S + will be + V3.", "The results will be announced next week.", 2),
                        s("Passive - Present Continuous", "S + am/is/are being + V3.", "The road is being repaired.", 3),
                        s("Causative have/get something done",
                                "Nhờ/thuê người khác làm gì: have/get + O + V3.", "I had my hair cut yesterday.", 3))),
                new TopicSeed(gr, "Danh từ & Mạo từ", "Countable/uncountable nouns, a/an/the", "text_fields_rounded", List.of(
                        s("Much / Many", "many + danh từ đếm được số nhiều; much + danh từ không đếm được.",
                                "How much water do you drink every day?", 1),
                        s("A few / A little", "a few + danh từ đếm được số nhiều; a little + danh từ không đếm được.",
                                "I have a few friends and a little free time.", 2))),
                new TopicSeed(gr, "Giới từ", "Prepositions of time, place, movement", "place_rounded", List.of(
                        s("By vs Until", "by = trước hoặc muộn nhất là lúc; until = kéo dài cho tới lúc.",
                                "Please finish the report by Friday.", 2),
                        s("Phrasal verbs", "Động từ + giới từ/trạng từ tạo nghĩa mới (look after, give up).",
                                "She looks after her younger brother.", 3))),
                new TopicSeed(gr, "So sánh", "Comparatives & Superlatives", "compare_arrows_rounded", List.of(
                        s("Irregular comparatives", "So sánh bất quy tắc: good-better-best, bad-worse-worst.",
                                "Her English is better than mine.", 1),
                        s("Much / Far + comparative", "Nhấn mạnh so sánh hơn: much/far + adj-er/more + adj.",
                                "This phone is much cheaper than that one.", 2))),

                // ---------------- NGỮ PHÁP: chủ đề mới ----------------
                new TopicSeed(gr, "Động từ khuyết thiếu", "Modal verbs: can, must, should, may...", "gavel_rounded", List.of(
                        s("Can / Could", "Chỉ khả năng hoặc xin phép (could lịch sự hơn).",
                                "Could I open the window, please?", 1),
                        s("Should / Ought to", "Đưa ra lời khuyên. CT: S + should + V.", "You should see a doctor.", 1),
                        s("Must / Have to", "Bắt buộc: must (người nói thấy cần), have to (quy định bên ngoài).",
                                "We have to wear a uniform at school.", 2),
                        s("May / Might", "Khả năng có thể xảy ra (might ít chắc chắn hơn).", "It might rain later.", 2),
                        s("Mustn't vs Don't have to", "mustn't = cấm; don't have to = không cần thiết.",
                                "You don't have to come early, but you mustn't be late.", 3),
                        s("Should have + V3", "Tiếc nuối/trách điều đã không làm trong quá khứ.",
                                "You should have told me earlier.", 3))),
                new TopicSeed(gr, "Mệnh đề quan hệ", "Relative clauses: who, which, that, whose...", "link_rounded", List.of(
                        s("Relative pronoun who", "who thay cho danh từ chỉ người.",
                                "The man who lives next door is a doctor.", 1),
                        s("Relative pronoun which", "which thay cho danh từ chỉ vật.",
                                "The book which I bought is interesting.", 1),
                        s("Relative pronoun that", "that thay cho who/which trong mệnh đề xác định.",
                                "This is the house that my grandfather built.", 2),
                        s("Relative pronoun whose", "whose chỉ sở hữu (của người/vật đứng trước).",
                                "That's the girl whose bag was stolen.", 2),
                        s("Relative adverbs where / when", "where thay cho nơi chốn, when thay cho thời gian.",
                                "This is the café where we first met.", 2),
                        s("Non-defining relative clauses",
                                "Mệnh đề bổ sung thông tin, đặt giữa dấu phẩy, không dùng that.",
                                "My brother, who lives in Hanoi, is a teacher.", 3))),
                new TopicSeed(gr, "Câu gián tiếp", "Reported speech: câu kể, câu hỏi, câu mệnh lệnh", "record_voice_over_rounded", List.of(
                        s("Say vs Tell", "say + something; tell + somebody + something.", "She told me the news yesterday.", 1),
                        s("Reported statements", "Lùi thì khi tường thuật: am/is → was, will → would.",
                                "She said that she was tired.", 2),
                        s("Reported commands", "Tường thuật mệnh lệnh/yêu cầu: tell/ask + O + to V.",
                                "The teacher told us to be quiet.", 2),
                        s("Reported questions", "Câu hỏi gián tiếp không đảo ngữ; câu hỏi Yes/No dùng if/whether.",
                                "He asked me where I lived.", 3),
                        s("Time and place changes", "Đổi trạng từ: today → that day, tomorrow → the next day, here → there.",
                                "He said he would come the next day.", 3),
                        s("Reporting verbs", "Động từ tường thuật có cấu trúc riêng: promise/refuse + to V, suggest + V-ing.",
                                "She promised to help me with my homework.", 3))),
                new TopicSeed(gr, "Danh động từ & To-V", "Gerunds & infinitives", "extension_rounded", List.of(
                        s("Verb + V-ing", "Một số động từ theo sau là V-ing: enjoy, finish, avoid, mind.",
                                "I enjoy reading books in the evening.", 2),
                        s("Verb + to V", "Một số động từ theo sau là to V: want, decide, hope, plan.",
                                "She decided to study abroad.", 2),
                        s("Gerund as subject", "V-ing đứng đầu câu làm chủ ngữ.", "Swimming is good for your health.", 2),
                        s("Preposition + V-ing", "Sau giới từ luôn dùng V-ing.",
                                "He is interested in learning Japanese.", 2),
                        s("Too / Enough + to V", "too + adj + to V (quá... không thể); adj + enough + to V (đủ... để).",
                                "He is too young to drive a car.", 2),
                        s("Remember / Stop + V-ing or to V",
                                "Đổi nghĩa theo dạng: remember to V (nhớ phải làm), remember V-ing (nhớ đã làm).",
                                "Remember to lock the door before you leave.", 3))));
    }
}

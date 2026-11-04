package com.nguyentuanminh.e_app.config;

import com.nguyentuanminh.e_app.domain.LearningCategory;
import com.nguyentuanminh.e_app.domain.LearningItem;
import com.nguyentuanminh.e_app.domain.LearningTopic;
import com.nguyentuanminh.e_app.repository.LearningItemRepository;
import com.nguyentuanminh.e_app.repository.LearningTopicRepository;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * Seed ngân hàng nội dung cho môi trường dev (Vocabulary >= 200 từ, Grammar và
 * Sentence mỗi mảng ~40 mục qua 8 chủ đề) — chỉ chạy khi DB đang trống. Đây là
 * nội dung mẫu để phát triển/demo, không phải nội dung biên tập cuối cùng cho
 * sản phẩm thật.
 */
@Component
@org.springframework.core.annotation.Order(1)
public class LearningContentSeeder implements CommandLineRunner {

    private final LearningTopicRepository topicRepository;
    private final LearningItemRepository itemRepository;

    public LearningContentSeeder(LearningTopicRepository topicRepository,
                                  LearningItemRepository itemRepository) {
        this.topicRepository = topicRepository;
        this.itemRepository = itemRepository;
    }

    private record Seed(String term, String phonetic, String meaning, String example, int level) {
    }

    private static Seed w(String term, String phonetic, String meaning, String example, int level) {
        return new Seed(term, phonetic, meaning, example, level);
    }

    /** Không có phiên âm — dùng cho Grammar/Sentence. */
    private static Seed g(String term, String meaning, String example, int level) {
        return new Seed(term, null, meaning, example, level);
    }

    @Override
    public void run(String... args) {
        if (topicRepository.count() > 0) {
            return;
        }

        seedVocabulary();
        seedGrammar();
        seedSentences();
    }

    private void seedVocabulary() {
        seedTopic(LearningCategory.VOCABULARY, "Du lịch", "Từ vựng thường gặp khi đi du lịch", "flight_takeoff_rounded", List.of(
                w("trip", "/trɪp/", "chuyến đi", "We're planning a trip to Da Nang next month.", 1),
                w("ticket", "/ˈtɪkɪt/", "vé", "I bought two tickets for the train.", 1),
                w("passport", "/ˈpæspɔːrt/", "hộ chiếu", "Don't forget to bring your passport.", 1),
                w("luggage", "/ˈlʌɡɪdʒ/", "hành lý", "My luggage was lost at the airport.", 1),
                w("hotel", "/hoʊˈtel/", "khách sạn", "We stayed at a cheap hotel near the beach.", 1),
                w("map", "/mæp/", "bản đồ", "Use the map to find the museum.", 1),
                w("tourist", "/ˈtʊrɪst/", "khách du lịch", "The city is full of tourists in summer.", 1),
                w("journey", "/ˈdʒɜːrni/", "hành trình", "It was a long journey by bus.", 2),
                w("itinerary", "/aɪˈtɪnərəri/", "lịch trình", "Our travel agent sent us a detailed itinerary.", 3),
                w("accommodation", "/əˌkɒməˈdeɪʃn/", "chỗ ở", "We booked our accommodation two months in advance.", 3),
                w("boarding pass", "/ˈbɔːrdɪŋ pɑːs/", "thẻ lên máy bay", "Please have your boarding pass ready at the gate.", 2),
                w("layover", "/ˈleɪoʊvər/", "thời gian quá cảnh", "We have a three-hour layover in Singapore.", 3),
                w("souvenir", "/ˌsuːvəˈnɪr/", "quà lưu niệm", "I bought a souvenir for my sister.", 2),
                w("customs", "/ˈkʌstəmz/", "hải quan", "We had to go through customs at the airport.", 2),
                w("visa", "/ˈviːzə/", "thị thực", "You need a visa to enter that country.", 2),
                w("departure", "/dɪˈpɑːrtʃər/", "sự khởi hành", "The departure time was delayed by an hour.", 2),
                w("destination", "/ˌdestɪˈneɪʃn/", "điểm đến", "Our final destination is Ha Long Bay.", 2),
                w("reservation", "/ˌrezərˈveɪʃn/", "sự đặt trước", "I made a reservation at a seaside restaurant.", 2),
                w("sightseeing", "/ˈsaɪtsiːɪŋ/", "tham quan", "We spent the day sightseeing around the old town.", 2),
                w("backpack", "/ˈbækpæk/", "ba lô", "He carried all his gear in a backpack.", 1),
                w("currency exchange", "/ˈkʌrənsi ɪksˈtʃeɪndʒ/", "đổi tiền", "There's a currency exchange counter near the exit.", 3),
                w("excursion", "/ɪkˈskɜːrʒn/", "chuyến đi ngắn/tham quan", "We joined a boat excursion to the islands.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Công việc", "Từ vựng giao tiếp nơi công sở", "work_outline_rounded", List.of(
                w("job", "/dʒɒb/", "công việc", "She found a new job last week.", 1),
                w("office", "/ˈɒfɪs/", "văn phòng", "I work in an office downtown.", 1),
                w("meeting", "/ˈmiːtɪŋ/", "cuộc họp", "We have a meeting at 9 a.m.", 1),
                w("salary", "/ˈsæləri/", "lương", "The salary here is quite competitive.", 1),
                w("colleague", "/ˈkɒliːɡ/", "đồng nghiệp", "My colleague helped me finish the presentation.", 2),
                w("deadline", "/ˈdedlaɪn/", "hạn chót", "We need to finish the report before the deadline.", 2),
                w("resume", "/ˈrezʊmeɪ/", "sơ yếu lý lịch", "Please attach your resume to the email.", 2),
                w("interview", "/ˈɪntərvjuː/", "phỏng vấn", "I have a job interview tomorrow morning.", 1),
                w("promotion", "/prəˈmoʊʃn/", "sự thăng chức", "She got a promotion after two years.", 2),
                w("negotiate", "/nɪˈɡoʊʃieɪt/", "đàm phán", "They negotiated a better price with the supplier.", 3),
                w("supervisor", "/ˈsuːpərvaɪzər/", "người giám sát", "My supervisor reviewed my work today.", 2),
                w("client", "/ˈklaɪənt/", "khách hàng (doanh nghiệp)", "We are meeting an important client this afternoon.", 2),
                w("contract", "/ˈkɒntrækt/", "hợp đồng", "Both parties signed the contract yesterday.", 2),
                w("budget", "/ˈbʌdʒɪt/", "ngân sách", "The project went over budget.", 2),
                w("teamwork", "/ˈtiːmwɜːrk/", "làm việc nhóm", "Good teamwork helped us finish early.", 1),
                w("overtime", "/ˈoʊvərtaɪm/", "làm thêm giờ", "He worked overtime to meet the deadline.", 2),
                w("resign", "/rɪˈzaɪn/", "từ chức", "She decided to resign from her position.", 3),
                w("recruit", "/rɪˈkruːt/", "tuyển dụng", "The company plans to recruit ten new staff.", 3),
                w("productivity", "/ˌproʊdʌkˈtɪvəti/", "năng suất", "New tools improved our productivity.", 3),
                w("presentation", "/ˌprezənˈteɪʃn/", "bài thuyết trình", "He gave a great presentation to the board.", 2),
                w("qualification", "/ˌkwɒlɪfɪˈkeɪʃn/", "bằng cấp/trình độ", "This job requires a specific qualification.", 3),
                w("workload", "/ˈwɜːrkloʊd/", "khối lượng công việc", "Her workload increased after the merger.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Đời sống", "Từ vựng sinh hoạt hàng ngày", "home_rounded", List.of(
                w("house", "/haʊs/", "ngôi nhà", "They bought a small house in the suburbs.", 1),
                w("grocery", "/ˈɡroʊsəri/", "hàng tạp hoá", "I need to buy some groceries after work.", 1),
                w("chore", "/tʃɔːr/", "việc nhà", "Doing the dishes is my least favorite chore.", 1),
                w("neighbor", "/ˈneɪbər/", "hàng xóm", "My neighbor is very friendly.", 1),
                w("laundry", "/ˈlɔːndri/", "đồ giặt/giặt giũ", "I usually do laundry on weekends.", 1),
                w("furniture", "/ˈfɜːrnɪtʃər/", "đồ nội thất", "We bought new furniture for the living room.", 2),
                w("routine", "/ruːˈtiːn/", "thói quen hàng ngày", "Exercise is part of my daily routine.", 2),
                w("errand", "/ˈerənd/", "việc vặt (đi ra ngoài làm)", "I have a few errands to run this morning.", 2),
                w("appliance", "/əˈplaɪəns/", "thiết bị gia dụng", "The washing machine is a useful appliance.", 2),
                w("landlord", "/ˈlændlɔːrd/", "chủ nhà (cho thuê)", "The landlord fixed the leaking roof.", 2),
                w("utility bill", "/juːˈtɪləti bɪl/", "hoá đơn tiện ích", "We pay the utility bill every month.", 3),
                w("commute", "/kəˈmjuːt/", "đi làm/đi học hàng ngày", "My commute takes about 30 minutes.", 2),
                w("housework", "/ˈhaʊswɜːrk/", "việc nhà (nói chung)", "We share the housework equally.", 1),
                w("tidy up", "/ˈtaɪdi ʌp/", "dọn dẹp gọn gàng", "Let's tidy up before guests arrive.", 1),
                w("babysit", "/ˈbeɪbisɪt/", "trông trẻ", "She babysits her niece on Fridays.", 2),
                w("appointment", "/əˈpɔɪntmənt/", "cuộc hẹn", "I have a dentist appointment tomorrow.", 2),
                w("subscription", "/səbˈskrɪpʃn/", "gói đăng ký (dịch vụ)", "I cancelled my streaming subscription.", 3),
                w("mortgage", "/ˈmɔːrɡɪdʒ/", "khoản vay mua nhà", "They are still paying off their mortgage.", 3),
                w("household", "/ˈhaʊshoʊld/", "hộ gia đình", "Every household received a notice.", 2),
                w("recycle", "/riːˈsaɪkl/", "tái chế", "We recycle paper and plastic at home.", 1),
                w("maintenance", "/ˈmeɪntənəns/", "bảo trì", "The building needs regular maintenance.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Giáo dục", "Từ vựng học tập, trường lớp", "school_rounded", List.of(
                w("student", "/ˈstuːdnt/", "học sinh/sinh viên", "She is a student at the local university.", 1),
                w("teacher", "/ˈtiːtʃər/", "giáo viên", "Our teacher explained the lesson clearly.", 1),
                w("classroom", "/ˈklæsruːm/", "lớp học", "The classroom was quiet during the test.", 1),
                w("homework", "/ˈhoʊmwɜːrk/", "bài tập về nhà", "I finished my homework before dinner.", 1),
                w("exam", "/ɪɡˈzæm/", "kỳ thi", "The final exam is next week.", 1),
                w("lecture", "/ˈlektʃər/", "bài giảng", "The professor gave an interesting lecture.", 2),
                w("scholarship", "/ˈskɒlərʃɪp/", "học bổng", "She received a full scholarship.", 2),
                w("curriculum", "/kəˈrɪkjələm/", "chương trình học", "The curriculum was recently updated.", 3),
                w("graduate", "/ˈɡrædʒueɪt/", "tốt nghiệp", "He will graduate next spring.", 2),
                w("semester", "/sɪˈmestər/", "học kỳ", "This semester has six subjects.", 2),
                w("assignment", "/əˈsaɪnmənt/", "bài tập lớn", "The assignment is due on Friday.", 2),
                w("textbook", "/ˈtekstbʊk/", "sách giáo khoa", "Bring your textbook to class.", 1),
                w("attendance", "/əˈtendəns/", "sự chuyên cần/điểm danh", "Attendance is checked every lesson.", 2),
                w("plagiarism", "/ˈpleɪdʒərɪzəm/", "đạo văn", "Plagiarism can lead to failing the course.", 3),
                w("tuition", "/tuˈɪʃn/", "học phí", "Tuition fees increased this year.", 3),
                w("dormitory", "/ˈdɔːrmətɔːri/", "ký túc xá", "Most freshmen live in the dormitory.", 3),
                w("major", "/ˈmeɪdʒər/", "chuyên ngành", "Her major is computer science.", 2),
                w("lecture hall", "/ˈlektʃər hɔːl/", "giảng đường", "The lecture hall was completely full.", 2),
                w("literacy", "/ˈlɪtərəsi/", "khả năng đọc viết", "The program improves literacy in rural areas.", 3),
                w("supervisor (academic)", "/ˈsuːpərvaɪzər/", "giảng viên hướng dẫn", "My supervisor reviewed my thesis draft.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Công nghệ", "Từ vựng công nghệ, thiết bị số", "devices_rounded", List.of(
                w("computer", "/kəmˈpjuːtər/", "máy tính", "I use my computer for work every day.", 1),
                w("internet", "/ˈɪntərnet/", "internet", "The internet connection is very slow today.", 1),
                w("password", "/ˈpæswɜːrd/", "mật khẩu", "Please choose a strong password.", 1),
                w("app", "/æp/", "ứng dụng", "I downloaded a new app for learning English.", 1),
                w("software", "/ˈsɒftwer/", "phần mềm", "This software helps manage our finances.", 2),
                w("upload", "/ʌpˈloʊd/", "tải lên", "Upload your photos to the shared folder.", 1),
                w("download", "/ˌdaʊnˈloʊd/", "tải xuống", "You can download the file for free.", 1),
                w("device", "/dɪˈvaɪs/", "thiết bị", "This device connects to Wi-Fi automatically.", 1),
                w("battery", "/ˈbætəri/", "pin", "My phone battery dies quickly.", 1),
                w("update", "/ʌpˈdeɪt/", "cập nhật", "Please update the app to the latest version.", 1),
                w("network", "/ˈnetwɜːrk/", "mạng lưới", "The office network went down this morning.", 2),
                w("server", "/ˈsɜːrvər/", "máy chủ", "The server crashed during peak hours.", 2),
                w("database", "/ˈdeɪtəbeɪs/", "cơ sở dữ liệu", "All records are stored in the database.", 2),
                w("encryption", "/ɪnˈkrɪpʃn/", "mã hoá", "The app uses encryption to protect data.", 3),
                w("bandwidth", "/ˈbændwɪdθ/", "băng thông", "Video calls use a lot of bandwidth.", 3),
                w("firmware", "/ˈfɜːrmwer/", "phần mềm firmware/vi chương trình", "The router needs a firmware update.", 3),
                w("cybersecurity", "/ˈsaɪbərsɪˌkjʊərəti/", "an ninh mạng", "The company invested more in cybersecurity.", 3),
                w("cloud storage", "/klaʊd ˈstɔːrɪdʒ/", "lưu trữ đám mây", "I back up my photos to cloud storage.", 2),
                w("glitch", "/ɡlɪtʃ/", "lỗi nhỏ/trục trặc", "There's a glitch in the login page.", 3),
                w("troubleshoot", "/ˈtrʌblʃuːt/", "khắc phục sự cố", "Our team will troubleshoot the issue today.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Sức khoẻ", "Từ vựng sức khoẻ, y tế", "favorite_rounded", List.of(
                w("health", "/helθ/", "sức khoẻ", "Regular exercise is good for your health.", 1),
                w("doctor", "/ˈdɒktər/", "bác sĩ", "I saw a doctor about my headache.", 1),
                w("medicine", "/ˈmedsn/", "thuốc/y học", "Take this medicine after meals.", 1),
                w("hospital", "/ˈhɒspɪtl/", "bệnh viện", "She was taken to the hospital last night.", 1),
                w("symptom", "/ˈsɪmptəm/", "triệu chứng", "Fever is a common symptom of the flu.", 2),
                w("exercise", "/ˈeksərsaɪz/", "tập thể dục", "I exercise three times a week.", 1),
                w("diet", "/ˈdaɪət/", "chế độ ăn", "He follows a strict diet.", 2),
                w("nutrition", "/nuˈtrɪʃn/", "dinh dưỡng", "Good nutrition helps children grow.", 2),
                w("prescription", "/prɪˈskrɪpʃn/", "đơn thuốc", "The pharmacist filled my prescription.", 2),
                w("injury", "/ˈɪndʒəri/", "chấn thương", "He suffered a minor injury while playing football.", 2),
                w("recover", "/rɪˈkʌvər/", "hồi phục", "It took her a week to recover from the cold.", 2),
                w("vaccine", "/vækˈsiːn/", "vắc-xin", "The vaccine is given in two doses.", 2),
                w("checkup", "/ˈtʃekʌp/", "khám sức khoẻ định kỳ", "I go for a checkup every year.", 2),
                w("allergy", "/ˈælərdʒi/", "dị ứng", "She has an allergy to peanuts.", 2),
                w("insomnia", "/ɪnˈsɒmniə/", "chứng mất ngủ", "Stress can cause insomnia.", 3),
                w("immune system", "/ɪˈmjuːn ˈsɪstəm/", "hệ miễn dịch", "Vitamin C supports the immune system.", 3),
                w("physical therapy", "/ˈfɪzɪkl ˈθerəpi/", "vật lý trị liệu", "He needs physical therapy after the surgery.", 3),
                w("chronic", "/ˈkrɒnɪk/", "mãn tính", "Diabetes is a chronic condition.", 3),
                w("wellbeing", "/wel ˈbiːɪŋ/", "sự khoẻ mạnh, hạnh phúc", "Mental wellbeing is just as important.", 3),
                w("dosage", "/ˈdoʊsɪdʒ/", "liều lượng", "Follow the correct dosage on the label.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Ẩm thực", "Từ vựng đồ ăn, nấu nướng", "restaurant_rounded", List.of(
                w("meal", "/miːl/", "bữa ăn", "We had a big meal with the family.", 1),
                w("recipe", "/ˈresəpi/", "công thức nấu ăn", "She followed a recipe for chicken soup.", 1),
                w("ingredient", "/ɪnˈɡriːdiənt/", "nguyên liệu", "Sugar is the main ingredient in this cake.", 2),
                w("flavor", "/ˈfleɪvər/", "hương vị", "This soup has a rich flavor.", 1),
                w("delicious", "/dɪˈlɪʃəs/", "ngon", "The food at that restaurant is delicious.", 1),
                w("appetizer", "/ˈæpɪtaɪzər/", "món khai vị", "We ordered spring rolls as an appetizer.", 2),
                w("dessert", "/dɪˈzɜːrt/", "món tráng miệng", "Ice cream is my favorite dessert.", 1),
                w("leftover", "/ˈleftoʊvər/", "đồ ăn thừa", "I'll have the leftovers for lunch tomorrow.", 2),
                w("season (verb)", "/ˈsiːzn/", "nêm gia vị", "Season the meat with salt and pepper.", 2),
                w("boil", "/bɔɪl/", "luộc/đun sôi", "Boil the noodles for five minutes.", 1),
                w("roast", "/roʊst/", "quay/nướng", "We roasted a whole chicken for dinner.", 2),
                w("marinate", "/ˈmærɪneɪt/", "ướp", "Marinate the beef overnight for better flavor.", 3),
                w("cuisine", "/kwɪˈziːn/", "ẩm thực (nói chung)", "Vietnamese cuisine is famous worldwide.", 2),
                w("beverage", "/ˈbevərɪdʒ/", "đồ uống", "Water is the healthiest beverage.", 2),
                w("nutritious", "/nuˈtrɪʃəs/", "bổ dưỡng", "Vegetables are nutritious and low in calories.", 2),
                w("garnish", "/ˈɡɑːrnɪʃ/", "trang trí món ăn", "Garnish the dish with fresh herbs.", 3),
                w("simmer", "/ˈsɪmər/", "đun nhỏ lửa", "Let the sauce simmer for ten minutes.", 3),
                w("staple food", "/ˈsteɪpl fuːd/", "lương thực chính", "Rice is a staple food in many countries.", 3),
                w("leftovers", "/ˈleftoʊvərz/", "thức ăn thừa (số nhiều)", "We packed the leftovers in containers.", 2),
                w("savory", "/ˈseɪvəri/", "vị mặn/đậm đà", "I prefer savory snacks over sweet ones.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Mua sắm", "Từ vựng mua sắm, cửa hàng", "shopping_bag_rounded", List.of(
                w("shop", "/ʃɒp/", "cửa hàng", "There's a small shop on the corner.", 1),
                w("price", "/praɪs/", "giá cả", "The price of milk went up this month.", 1),
                w("discount", "/ˈdɪskaʊnt/", "giảm giá", "I got a 20% discount on shoes.", 1),
                w("receipt", "/rɪˈsiːt/", "hoá đơn", "Keep the receipt in case you need a refund.", 1),
                w("cashier", "/kæˈʃɪr/", "thu ngân", "The cashier gave me the wrong change.", 1),
                w("refund", "/ˈriːfʌnd/", "hoàn tiền", "I asked for a refund on the broken item.", 2),
                w("customer", "/ˈkʌstəmər/", "khách hàng", "The customer complained about the service.", 1),
                w("bargain", "/ˈbɑːrɡɪn/", "món hời/mặc cả", "She found a great bargain at the market.", 2),
                w("checkout", "/ˈtʃekaʊt/", "quầy thanh toán", "The line at the checkout was very long.", 1),
                w("warranty", "/ˈwɔːrənti/", "bảo hành", "This laptop comes with a two-year warranty.", 2),
                w("purchase", "/ˈpɜːrtʃəs/", "mua/sự mua hàng", "Keep your purchase receipt for returns.", 2),
                w("delivery", "/dɪˈlɪvəri/", "giao hàng", "Delivery usually takes three days.", 1),
                w("exchange", "/ɪksˈtʃeɪndʒ/", "đổi hàng", "You can exchange the shirt for a bigger size.", 2),
                w("installment", "/ɪnˈstɔːlmənt/", "trả góp", "I'm paying for the phone in installments.", 3),
                w("retailer", "/ˈriːteɪlər/", "nhà bán lẻ", "The retailer offers free shipping over $50.", 3),
                w("browse", "/braʊz/", "xem hàng/lướt xem", "We browsed the store without buying anything.", 2),
                w("out of stock", "/aʊt əv stɒk/", "hết hàng", "That size is currently out of stock.", 2),
                w("voucher", "/ˈvaʊtʃər/", "phiếu giảm giá", "I used a voucher to get a free coffee.", 3),
                w("wholesale", "/ˈhoʊlseɪl/", "bán buôn", "They sell fabric at wholesale prices.", 3),
                w("consumer", "/kənˈsuːmər/", "người tiêu dùng", "Consumers are demanding more eco-friendly products.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Thời tiết", "Từ vựng thời tiết, khí hậu", "wb_sunny_rounded", List.of(
                w("weather", "/ˈweðər/", "thời tiết", "The weather is nice today.", 1),
                w("rain", "/reɪn/", "mưa", "It might rain later this afternoon.", 1),
                w("sunny", "/ˈsʌni/", "nắng", "It was a sunny day at the beach.", 1),
                w("cloudy", "/ˈklaʊdi/", "nhiều mây", "The sky is cloudy this morning.", 1),
                w("temperature", "/ˈtemprətʃər/", "nhiệt độ", "The temperature dropped suddenly at night.", 1),
                w("storm", "/stɔːrm/", "bão", "A storm is expected this weekend.", 2),
                w("humid", "/ˈhjuːmɪd/", "ẩm ướt", "Summers here are hot and humid.", 2),
                w("forecast", "/ˈfɔːrkæst/", "dự báo thời tiết", "The forecast predicts heavy rain tomorrow.", 2),
                w("breeze", "/briːz/", "gió nhẹ", "A cool breeze came from the sea.", 2),
                w("drought", "/draʊt/", "hạn hán", "The region suffered a severe drought.", 3),
                w("flood", "/flʌd/", "lũ lụt", "Heavy rain caused flooding in the city.", 2),
                w("thunder", "/ˈθʌndər/", "sấm", "We heard thunder in the distance.", 2),
                w("lightning", "/ˈlaɪtnɪŋ/", "sét/chớp", "Lightning struck a tree near our house.", 2),
                w("frost", "/frɒst/", "sương giá", "There was frost on the windows this morning.", 3),
                w("humidity", "/hjuˈmɪdəti/", "độ ẩm", "Humidity levels are high in the rainforest.", 3),
                w("climate", "/ˈklaɪmət/", "khí hậu", "The climate here is mild all year round.", 2),
                w("blizzard", "/ˈblɪzərd/", "bão tuyết", "A blizzard shut down the airport for two days.", 3),
                w("overcast", "/ˈoʊvərkæst/", "u ám", "The sky was overcast all afternoon.", 3)
        ));

        seedTopic(LearningCategory.VOCABULARY, "Cảm xúc", "Từ vựng miêu tả cảm xúc, tính cách", "emoji_emotions_rounded", List.of(
                w("happy", "/ˈhæpi/", "vui vẻ", "She felt happy after the good news.", 1),
                w("sad", "/sæd/", "buồn", "He looked sad after losing the match.", 1),
                w("angry", "/ˈæŋɡri/", "tức giận", "She was angry about the delay.", 1),
                w("excited", "/ɪkˈsaɪtɪd/", "phấn khích", "The kids were excited about the trip.", 1),
                w("nervous", "/ˈnɜːrvəs/", "lo lắng, hồi hộp", "I feel nervous before every exam.", 1),
                w("confident", "/ˈkɒnfɪdənt/", "tự tin", "She spoke confidently during the interview.", 2),
                w("anxious", "/ˈæŋkʃəs/", "lo âu", "He was anxious about the results.", 2),
                w("grateful", "/ˈɡreɪtfl/", "biết ơn", "I'm grateful for your help.", 2),
                w("frustrated", "/frʌˈstreɪtɪd/", "bực bội, thất vọng", "She felt frustrated with the slow internet.", 2),
                w("embarrassed", "/ɪmˈbærəst/", "xấu hổ, ngại ngùng", "He was embarrassed after tripping in public.", 2),
                w("relieved", "/rɪˈliːvd/", "nhẹ nhõm", "I was relieved when the test was over.", 2),
                w("jealous", "/ˈdʒeləs/", "ghen tị", "She felt jealous of her friend's new car.", 2),
                w("optimistic", "/ˌɒptɪˈmɪstɪk/", "lạc quan", "He stayed optimistic despite the challenges.", 3),
                w("overwhelmed", "/ˌoʊvərˈwelmd/", "quá tải, choáng ngợp", "She felt overwhelmed by the workload.", 3),
                w("content (adj)", "/kənˈtent/", "hài lòng, mãn nguyện", "He seemed content with his simple life.", 3),
                w("resentful", "/rɪˈzentfl/", "oán giận", "She grew resentful after being ignored.", 3),
                w("empathetic", "/ˌempəˈθetɪk/", "đồng cảm", "A good teacher is empathetic toward students.", 3),
                w("indifferent", "/ɪnˈdɪfrənt/", "thờ ơ, dửng dưng", "He seemed indifferent to the outcome.", 3)
        ));
    }

    private void seedGrammar() {
        seedTopic(LearningCategory.GRAMMAR, "Thì hiện tại", "Present Simple, Continuous, Perfect", "schedule_rounded", List.of(
                g("Present Simple", "Diễn tả thói quen, sự thật hiển nhiên. CT: S + V(s/es).", "She works at a bank every day.", 1),
                g("Present Simple - question", "Câu hỏi dùng do/does. CT: Do/Does + S + V?", "Do you like coffee?", 1),
                g("Present Continuous", "Diễn tả hành động đang xảy ra. CT: S + am/is/are + V-ing.", "They are studying English right now.", 1),
                g("Present Continuous - future plan", "Dùng để nói kế hoạch đã sắp xếp trong tương lai gần.", "I am meeting her tomorrow.", 2),
                g("Present Perfect", "Hành động đã xảy ra, còn liên quan đến hiện tại. CT: S + have/has + V3.", "I have lived here for five years.", 2),
                g("Present Perfect Continuous", "Nhấn mạnh khoảng thời gian hành động kéo dài đến hiện tại.", "She has been working since 8 a.m.", 3),
                g("Stative verbs", "Động từ trạng thái (like, want, know) thường không chia thì tiếp diễn.", "I know the answer, not 'I am knowing'.", 2),
                g("Simple vs Continuous", "So sánh thói quen (simple) và hành động đang diễn ra (continuous).", "I usually walk to work, but today I am driving.", 2)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Thì quá khứ", "Past Simple, Continuous, Perfect", "history_rounded", List.of(
                g("Past Simple", "Hành động đã kết thúc trong quá khứ. CT: S + V2/ed.", "I visited my grandparents last weekend.", 1),
                g("Past Simple - irregular verbs", "Nhiều động từ có dạng quá khứ bất quy tắc (go->went).", "She went to the market yesterday.", 1),
                g("Past Continuous", "Hành động đang xảy ra tại 1 thời điểm quá khứ. CT: S + was/were + V-ing.", "She was cooking when I arrived.", 2),
                g("Past Perfect", "Hành động xảy ra trước 1 hành động khác trong quá khứ. CT: S + had + V3.", "He had left before I got there.", 2),
                g("Past Perfect Continuous", "Nhấn mạnh khoảng thời gian trước 1 mốc quá khứ khác.", "They had been waiting for an hour when the bus came.", 3),
                g("Used to", "Thói quen/trạng thái trong quá khứ nay không còn.", "I used to play football every weekend.", 2),
                g("Past Simple vs Present Perfect", "Past Simple có mốc thời gian cụ thể, Present Perfect thì không.", "I visited Paris in 2019 (not: I have visited in 2019).", 3)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Thì tương lai", "Future Simple, Be going to, Future Perfect", "update_rounded", List.of(
                g("Future Simple (will)", "Dự đoán/quyết định tức thời. CT: S + will + V.", "I will call you tomorrow.", 1),
                g("Be going to", "Dự định đã lên kế hoạch từ trước. CT: S + am/is/are going to + V.", "We are going to travel next month.", 1),
                g("Will vs Be going to", "Will cho quyết định tức thời, going to cho kế hoạch đã định.", "Look at those clouds! It's going to rain.", 2),
                g("Future Continuous", "Hành động đang diễn ra tại 1 thời điểm trong tương lai.", "This time tomorrow, I will be flying to Hanoi.", 2),
                g("Future Perfect", "Hành động hoàn thành trước 1 thời điểm trong tương lai.", "By next year, she will have graduated.", 3)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Câu điều kiện", "Conditional sentences type 0-3", "alt_route_rounded", List.of(
                g("Conditional type 0", "Sự thật hiển nhiên. If + hiện tại đơn, hiện tại đơn.", "If you heat ice, it melts.", 1),
                g("Conditional type 1", "Điều kiện có thể xảy ra ở tương lai. If + hiện tại đơn, will + V.", "If it rains, we will stay home.", 2),
                g("Conditional type 2", "Điều kiện không có thật ở hiện tại. If + quá khứ đơn, would + V.", "If I were rich, I would travel the world.", 2),
                g("Conditional type 3", "Điều kiện không có thật trong quá khứ. If + had + V3, would have + V3.", "If she had studied harder, she would have passed.", 3),
                g("Mixed conditional", "Kết hợp điều kiện quá khứ với kết quả ở hiện tại.", "If I had taken that job, I would be rich now.", 3)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Câu bị động", "Passive voice ở các thì khác nhau", "swap_horiz_rounded", List.of(
                g("Passive - Present Simple", "S + am/is/are + V3 (+ by O), nhấn mạnh đối tượng chịu tác động.", "The report is checked every day.", 2),
                g("Passive - Past Simple", "S + was/were + V3.", "The window was broken by the storm.", 2),
                g("Passive - Present Perfect", "S + have/has been + V3.", "The house has been sold.", 3),
                g("Passive with modal verbs", "S + modal + be + V3.", "The task must be finished today.", 3),
                g("Active vs Passive", "Đổi câu chủ động sang bị động: đối tượng nhận hành động lên làm chủ ngữ.", "Active: They built this house in 1990. Passive: This house was built in 1990.", 2)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Danh từ & Mạo từ", "Countable/uncountable nouns, a/an/the", "text_fields_rounded", List.of(
                g("Countable nouns", "Danh từ đếm được có dạng số nhiều (book -> books).", "I bought three books yesterday.", 1),
                g("Uncountable nouns", "Danh từ không đếm được, không có số nhiều (information, water).", "I need some information about the course.", 1),
                g("Article a/an", "Dùng trước danh từ số ít, chưa xác định.", "She bought an umbrella.", 1),
                g("Article the", "Dùng khi danh từ đã được xác định/nhắc tới trước đó.", "The book on the table is mine.", 2),
                g("No article", "Không dùng mạo từ với danh từ số nhiều chung chung hoặc tên riêng.", "Dogs are loyal animals.", 2),
                g("Irregular plural nouns", "Một số danh từ số nhiều bất quy tắc: child -> children, foot -> feet.", "The children are playing outside.", 2)
        ));

        seedTopic(LearningCategory.GRAMMAR, "Giới từ", "Prepositions of time, place, movement", "place_rounded", List.of(
                g("Prepositions of time", "in/on/at dùng cho thời gian (in 2000, on Monday, at 6 p.m.).", "I was born in 2000, on Monday, at 6 p.m.", 1),
                g("Prepositions of place", "in/on/at dùng cho địa điểm (in the box, on the table, at home).", "The keys are in the drawer, on the table.", 1),
                g("Prepositions of movement", "to/into/through diễn tả sự di chuyển.", "She walked into the room.", 2),
                g("Dependent prepositions", "Một số tính từ/động từ đi kèm giới từ cố định (interested in, good at).", "He is good at math.", 3),
                g("Prepositions of direction", "above/below/between diễn tả vị trí tương đối.", "The lamp is above the table.", 2)
        ));

        seedTopic(LearningCategory.GRAMMAR, "So sánh", "Comparatives & Superlatives", "compare_arrows_rounded", List.of(
                g("Comparative adjectives", "So sánh hơn: adj+er hoặc more + adj.", "This book is more interesting than that one.", 1),
                g("Superlative adjectives", "So sánh nhất: the + adj+est hoặc the most + adj.", "She is the tallest student in class.", 1),
                g("As...as", "So sánh bằng: as + adj + as.", "He is as tall as his brother.", 2),
                g("Less...than", "So sánh kém hơn: less + adj + than.", "This test is less difficult than the last one.", 2),
                g("Double comparative", "Diễn tả sự thay đổi tăng dần: the more..., the more...", "The more you practice, the better you get.", 3)
        ));
    }

    private void seedSentences() {
        seedTopic(LearningCategory.SENTENCE, "Chào hỏi", "Mẫu câu chào hỏi thông dụng", "waving_hand_rounded", List.of(
                g("Hello! How are you?", "Xin chào! Bạn khoẻ không?", "A: Hello! How are you? B: I'm fine, thanks!", 1),
                g("Good morning!", "Chào buổi sáng!", "Good morning! Did you sleep well?", 1),
                g("Nice to meet you.", "Rất vui được gặp bạn.", "A: Nice to meet you. B: Nice to meet you too.", 1),
                g("Long time no see!", "Lâu rồi không gặp!", "Long time no see! How have you been?", 2),
                g("See you later.", "Hẹn gặp lại sau.", "I have to go now, see you later!", 1),
                g("Take care.", "Bảo trọng nhé.", "Take care and have a safe trip!", 1)
        ));

        seedTopic(LearningCategory.SENTENCE, "Giới thiệu bản thân", "Mẫu câu tự giới thiệu", "badge_rounded", List.of(
                g("What's your name?", "Tên bạn là gì?", "A: What's your name? B: My name is Minh.", 1),
                g("Where are you from?", "Bạn đến từ đâu?", "Where are you from? — I'm from Vietnam.", 1),
                g("What do you do?", "Bạn làm nghề gì?", "What do you do? — I'm a student.", 1),
                g("How old are you?", "Bạn bao nhiêu tuổi?", "How old are you? — I'm 20 years old.", 1),
                g("This is my friend, Lan.", "Đây là bạn tôi, Lan.", "This is my friend, Lan. She works at a bank.", 2)
        ));

        seedTopic(LearningCategory.SENTENCE, "Tại nhà hàng", "Mẫu câu khi đi ăn ở nhà hàng", "restaurant_menu_rounded", List.of(
                g("Can I see the menu, please?", "Cho tôi xem thực đơn được không?", "Waiter: Here you are. Can I see the menu, please?", 1),
                g("I'd like to order the fried rice.", "Tôi muốn gọi món cơm chiên.", "I'd like to order the fried rice, please.", 1),
                g("Could we have the bill, please?", "Cho chúng tôi xin hoá đơn.", "Could we have the bill, please?", 2),
                g("Is this dish spicy?", "Món này có cay không?", "Is this dish spicy? I can't eat spicy food.", 2),
                g("Enjoy your meal!", "Chúc ngon miệng!", "Here's your order. Enjoy your meal!", 1)
        ));

        seedTopic(LearningCategory.SENTENCE, "Tại sân bay", "Mẫu câu khi đi máy bay", "flight_rounded", List.of(
                g("Where is the check-in counter?", "Quầy làm thủ tục ở đâu?", "Excuse me, where is the check-in counter?", 1),
                g("I'd like a window seat.", "Tôi muốn ghế cạnh cửa sổ.", "I'd like a window seat, please.", 1),
                g("What time does the flight depart?", "Chuyến bay khởi hành lúc mấy giờ?", "What time does the flight depart?", 2),
                g("Where can I collect my luggage?", "Tôi có thể lấy hành lý ở đâu?", "Where can I collect my luggage?", 2),
                g("Is this seat taken?", "Chỗ này có ai ngồi chưa?", "Excuse me, is this seat taken?", 1)
        ));

        seedTopic(LearningCategory.SENTENCE, "Mua sắm", "Mẫu câu khi đi mua sắm", "local_mall_rounded", List.of(
                g("How much is this?", "Cái này giá bao nhiêu?", "How much is this shirt?", 1),
                g("Can I try it on?", "Tôi thử được không?", "Can I try it on before buying?", 1),
                g("Do you have a smaller size?", "Có size nhỏ hơn không?", "Do you have a smaller size?", 1),
                g("I'm just looking, thanks.", "Tôi chỉ xem thôi, cảm ơn.", "Assistant: Can I help? — I'm just looking, thanks.", 2),
                g("Can I pay by card?", "Tôi trả bằng thẻ được không?", "Can I pay by card?", 1)
        ));

        seedTopic(LearningCategory.SENTENCE, "Hỏi đường", "Mẫu câu hỏi và chỉ đường", "signpost_rounded", List.of(
                g("Excuse me, how do I get to the station?", "Xin lỗi, làm sao để đến ga tàu?", "Excuse me, how do I get to the station?", 1),
                g("Is it far from here?", "Có xa đây không?", "Is it far from here? — No, it's just 5 minutes.", 1),
                g("Go straight and turn left.", "Đi thẳng rồi rẽ trái.", "Go straight and turn left at the corner.", 2),
                g("Could you show me on the map?", "Bạn chỉ giúp tôi trên bản đồ được không?", "Could you show me on the map?", 2)
        ));

        seedTopic(LearningCategory.SENTENCE, "Công sở", "Mẫu câu giao tiếp nơi công sở", "business_center_rounded", List.of(
                g("Could you send me the report?", "Bạn gửi báo cáo cho tôi được không?", "Could you send me the report by email?", 2),
                g("I'll have it done by Friday.", "Tôi sẽ hoàn thành trước thứ Sáu.", "I'll have it done by Friday, no problem.", 2),
                g("Let's schedule a meeting.", "Hãy lên lịch một cuộc họp.", "Let's schedule a meeting for next week.", 2),
                g("Can I take a day off?", "Tôi xin nghỉ một ngày được không?", "Can I take a day off next Monday?", 1)
        ));

        seedTopic(LearningCategory.SENTENCE, "Điện thoại", "Mẫu câu gọi điện thoại", "call_rounded", List.of(
                g("Hello, may I speak to Mr. Nam?", "Alo, cho tôi nói chuyện với anh Nam.", "Hello, may I speak to Mr. Nam, please?", 1),
                g("Can you hold on a second?", "Bạn chờ máy một chút nhé.", "Can you hold on a second? I'll transfer your call.", 2),
                g("I'll call you back later.", "Tôi sẽ gọi lại cho bạn sau.", "I'm busy now, I'll call you back later.", 1),
                g("Sorry, you have the wrong number.", "Xin lỗi, bạn gọi nhầm số rồi.", "Sorry, you have the wrong number.", 2)
        ));
    }

    private void seedTopic(LearningCategory category, String name, String description, String icon, List<Seed> words) {
        LearningTopic topic = topicRepository.save(new LearningTopic(null, name, description, icon, category));
        itemRepository.saveAll(words.stream()
                .map(s -> {
                    LearningItem item = new LearningItem();
                    item.setTerm(s.term());
                    item.setPhonetic(s.phonetic());
                    item.setMeaning(s.meaning());
                    item.setExample(s.example());
                    item.setDifficultyLevel(s.level());
                    item.setTopic(topic);
                    return item;
                })
                .toList());
    }
}

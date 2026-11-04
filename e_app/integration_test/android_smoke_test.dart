// Kiểm thử tích hợp trên thiết bị Android thật:
//   adb reverse tcp:8080 tcp:8080
//   adb shell pm grant com.example.e_app android.permission.RECORD_AUDIO
//   flutter drive -d <id> --driver=test_driver/integration_test.dart --target=integration_test/android_smoke_test.dart
// Chạy app thật với kho token trong bộ nhớ (không đụng phiên đăng nhập đang lưu trên máy) và backend thật
// ở localhost:8080: đăng ký tài khoản mới → khảo sát → duyệt các màn chính → chụp ảnh từng màn.
import 'package:e_app/core/network/token_storage.dart';
import 'package:e_app/core/router/app_router.dart';
import 'package:e_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryTokenStorage extends TokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Duyệt toàn bộ app trên Android', (tester) async {
    final problems = <String>[];
    final flutterErrors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString().split('\n').first;
      flutterErrors.add(text);
      debugPrint('FLUTTER_ERROR: $text');
      previous?.call(details);
    };

    Future<void> pumpFor(double seconds) async {
      final end = DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    var surfaceConverted = false;
    Future<void> shot(String name) async {
      if (!surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
      }
      await tester.pump();
      await binding.takeScreenshot(name);
    }

    Future<void> section(String name, Future<void> Function() body) async {
      final errorsBefore = flutterErrors.length;
      debugPrint('=== $name');
      try {
        await body();
      } catch (e) {
        problems.add('$name: ${e.toString().split('\n').first}');
        debugPrint('SECTION_FAIL $name: $e');
        try {
          await shot('fail_${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}');
        } catch (_) {}
      }
      for (final e in flutterErrors.skip(errorsBefore)) {
        problems.add('$name [Flutter]: $e');
      }
    }

    Future<void> tapText(String text, {double wait = 1.5}) async {
      final f = find.text(text);
      expect(f, findsWidgets, reason: 'Không thấy "$text"');
      await tester.ensureVisible(f.first);
      await tester.tap(f.first, warnIfMissed: false);
      await pumpFor(wait);
    }

    GoRouterLike router() {
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      return GoRouterLike(container.read(appRouterProvider));
    }

    Future<void> visit(String path, String name, {double wait = 3.5}) async {
      router().go(path);
      await pumpFor(wait);
      await shot(name);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_MemoryTokenStorage())],
        child: const MyApp(),
      ),
    );
    await pumpFor(4);

    final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
    final email = 'and$stamp@x.com';

    await section('01 Onboarding', () async {
      await shot('01_onboarding');
      await tapText('Tiếp tục');
      await shot('01b_onboarding_2');
      await tapText('Bỏ qua', wait: 1.5);
      await shot('01c_onboarding_last');
      expect(find.text('Đăng ký ngay!'), findsOneWidget);
    });

    await section('02 Đăng ký', () async {
      await tapText('Đăng ký ngay!', wait: 2.5);
      await shot('02_signup');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), 'secret123');
      await tester.enterText(fields.at(2), 'secret123');
      await pumpFor(0.5);
      final check = find.byType(Checkbox);
      if (check.evaluate().isNotEmpty) await tester.tap(check.first);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpFor(0.5);
      await shot('03_signup_filled');
      final submit = find.widgetWithText(ElevatedButton, 'Đăng ký');
      await tester.ensureVisible(submit);
      await tester.tap(submit, warnIfMissed: false);
      await pumpFor(4);
      expect(find.text('Chúng tôi có thể gọi bạn là gì?'), findsOneWidget, reason: 'phải sang khảo sát');
      await shot('04_survey_1');
    });

    await section('03 Khảo sát', () async {
      await tester.enterText(find.byType(TextField).first, 'Tester Android');
      await pumpFor(0.5);
      await tapText('DD / MM / YYYY');
      await shot('05_survey_datepicker');
      await tapText('OK');
      await tapText('Nam');
      await shot('06_survey_1_filled');
      await tapText('Tiếp tục');
      await shot('07_survey_2');
      await tester.tap(find.byType(InkWell).at(1), warnIfMissed: false);
      await pumpFor(0.8);
      await tapText('Tiếp tục');
      await shot('08_survey_3');
      await tapText('10 phút/ngày');
      await tapText('Tiếp tục');
      await shot('09_survey_4');
      await tapText('Bắt đầu từ đầu');
      await tapText('Bắt đầu', wait: 5);
      await shot('10_home_after_survey');
      expect(find.text('Trang chủ'), findsWidgets, reason: 'phải vào Home');
    });

    await section('04 Tab Thư viện', () async {
      await tapText('Thư viện');
      await shot('11_library');
    });
    await section('06 Tab Đánh giá', () async {
      await tapText('Đánh giá');
      await shot('13_assessments');
    });
    await section('07 Tab Hồ sơ', () async {
      await tapText('Hồ sơ');
      await shot('14_profile');
    });

    await section('08 Từ vựng', () async => visit('/vocabulary', '20_vocab_topics'));
    await section('09 Flashcard', () async {
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      expect(container, isNotNull);
      await tapText('Du lịch', wait: 2);
      await shot('21_study_mode_sheet');
      await tapText('Flashcard', wait: 3);
      await shot('22_flashcard');
      final card = find.textContaining('Chạm để xem nghĩa');
      if (card.evaluate().isNotEmpty) {
        await tester.tap(card.first, warnIfMissed: false);
        await pumpFor(1.2);
        await shot('23_flashcard_flipped');
      }
    });
    await section('10 Trắc nghiệm', () async {
      router().go('/vocabulary');
      await pumpFor(2.5);
      await tapText('Du lịch', wait: 2);
      await tapText('Trắc nghiệm', wait: 3);
      await shot('24_quiz');
    });
    await section('11 Sắp xếp câu', () async {
      router().go('/vocabulary');
      await pumpFor(2.5);
      await tapText('Du lịch', wait: 2);
      await tapText('Sắp xếp câu', wait: 3);
      await shot('25_word_order');
    });
    await section('11b Luyện tổng hợp (Ghép cặp...)', () async {
      router().go('/vocabulary');
      await pumpFor(2.5);
      await tapText('Du lịch', wait: 2);
      await tapText('Luyện tổng hợp', wait: 3);
      await shot('25b_mixed_practice');
    });
    await section('12 Ngữ pháp', () async => visit('/grammar', '26_grammar'));
    await section('13 Mẫu câu', () async => visit('/sentences', '27_sentences'));
    await section('14 Luyện Nghe', () async {
      await visit('/listening-practice', '30_listening');
      final speaker = find.byIcon(Icons.volume_up_rounded);
      if (speaker.evaluate().isNotEmpty) {
        await tester.tap(speaker.first, warnIfMissed: false);
        await pumpFor(2);
        await shot('31_listening_speaking');
      }
    });
    await section('15 Luyện Nói', () async {
      await visit('/speaking-practice', '32_speaking');
      await tapText('Nghe mẫu', wait: 2.5);
      await tapText('Ghi âm', wait: 3);
      await shot('33_recording');
      await tapText('Dừng ghi', wait: 1.5);
      await tapText('Phát lại', wait: 2);
      await shot('34_playback');
    });
    await section('16 Luyện Đọc', () async => visit('/reading-practice', '35_reading'));
    await section('17 Luyện Viết', () async => visit('/writing-practice', '36_writing'));
    await section('18 Khoá học', () async {
      await visit('/courses', '40_courses');
      await tapText('Từ vựng căn bản', wait: 3);
      await shot('41_course_detail');
    });
    await section('19 Bạn bè', () async => visit('/friends', '42_friends'));
    await section('20 Thông báo', () async => visit('/notifications', '43_notifications'));
    await section('21 Bộ thẻ của tôi', () async {
      await visit('/my-decks', '44_my_decks');
      await tapText('Tạo bộ thẻ', wait: 1.5);
      await tester.enterText(find.byType(TextField).first, 'Bộ thẻ Android');
      await pumpFor(0.5);
      await shot('45_create_deck_dialog');
      await tapText('Tạo', wait: 3);
      await shot('46_new_deck');
    });
    await section('22 Lịch sử', () async => visit('/attempt-history', '47_history'));
    await section('23 Tìm kiếm', () async => visit('/search', '48_search'));
    await section('24 Ôn tập lỗi sai', () async => visit('/review-mistakes', '49_review'));
    await section('25 TOEIC', () async => visit('/toeic-practice', '50_toeic'));
    await section('26 Quên mật khẩu', () async => visit('/forgot-password', '51_forgot'));

    await section('27 Chế độ tối', () async {
      await visit('/home', '52_home_back', wait: 3);
      await tapText('Hồ sơ');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
      await pumpFor(1);
      await tapText('Tối', wait: 2.5);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await pumpFor(1);
      await shot('53_dark_profile');
      await tapText('Trang chủ', wait: 2);
      await shot('54_dark_home');
      // trả về chế độ cũ (Tự động) để không đổi cài đặt giao diện đang lưu trên máy
      await tapText('Hồ sơ');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
      await pumpFor(1);
      await tapText('Tự động', wait: 2);
    });

    await section('28 Đăng xuất → Đăng nhập', () async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await pumpFor(1);
      await tapText('Đăng xuất', wait: 3);
      await shot('55_after_logout');
      router().go('/login');
      await pumpFor(2.5);
      await shot('56_login');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), 'secret123');
      await pumpFor(0.5);
      final submit = find.widgetWithText(ElevatedButton, 'Đăng nhập');
      await tester.tap(submit, warnIfMissed: false);
      await pumpFor(4);
      await shot('57_login_ok');
      expect(find.text('Trang chủ'), findsWidgets, reason: 'đăng nhập lại phải vào Home');
    });

    await section('29 Nút Google', () async {
      await tapText('Hồ sơ');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await pumpFor(1);
      await tapText('Đăng xuất', wait: 3);
      router().go('/login');
      await pumpFor(2.5);
      await tester.tap(find.byIcon(Icons.g_mobiledata_rounded), warnIfMissed: false);
      await pumpFor(6);
      await shot('58_google_result');
    });

    FlutterError.onError = previous;
    debugPrint('SUMMARY problems=${problems.length}');
    for (final p in problems) {
      debugPrint('PROBLEM: $p');
    }
    expect(problems, isEmpty);
  });
}

/// Bọc GoRouter để test chỉ phụ thuộc `go`.
class GoRouterLike {
  GoRouterLike(this._r);
  final dynamic _r;
  void go(String path) => _r.go(path);
}

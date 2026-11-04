import 'package:e_app/core/theme/app_colors.dart';
import 'package:e_app/core/theme/app_theme.dart';
import 'package:e_app/core/theme/theme_controller.dart';
import 'package:e_app/features/attempts/domain/attempt.dart';
import 'package:e_app/features/decks/data/deck_repository.dart';
import 'package:e_app/features/notifications/notifications_screen.dart';
import 'package:e_app/features/social/social.dart';
import 'package:e_app/features/vocabulary/domain/vocabulary_models.dart';
import 'package:e_app/features/vocabulary/presentation/widgets/item_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.setDark(false));

  test('VocabularyItem/VocabularyTopic parse explanation, image, audio, guide and share code', () {
    final item = VocabularyItem.fromJson({
      'id': '1',
      'term': 'apple',
      'phonetic': null,
      'meaning': 'quả táo',
      'example': 'I eat an apple',
      'mastered': false,
      'difficultyLevel': 2,
      'explanation': 'Danh từ đếm được',
      'imageUrl': 'data:image/png;base64,AAAA',
      'audioUrl': 'https://example.com/a.mp3',
    });
    expect(item.explanation, 'Danh từ đếm được');
    expect(item.audioUrl, 'https://example.com/a.mp3');
    // copyWith giữ nguyên các trường mới
    final marked = item.copyWith(mastered: true);
    expect(marked.mastered, isTrue);
    expect(marked.imageUrl, item.imageUrl);
    expect(marked.explanation, item.explanation);

    final topic = VocabularyTopic.fromJson({
      'id': '9',
      'name': 'Du lịch',
      'wordCount': 3,
      'guide': 'Bước 1\nBước 2',
      'shareCode': 'ABCD2345',
    });
    expect(topic.guide, 'Bước 1\nBước 2');
    expect(topic.shareCode, 'ABCD2345');
  });

  test('ImportResult and SharedDeck parse the API payloads', () {
    final result = ImportResult.fromJson({
      'added': 4,
      'skipped': 1,
      'errors': ['Dòng 5: cần có đủ từ và nghĩa.'],
    });
    expect(result.added, 4);
    expect(result.errors, hasLength(1));
    final deck = SharedDeck.fromJson({
      'code': 'ABCD2345',
      'name': 'IELTS',
      'description': null,
      'wordCount': 12,
      'ownerName': 'Lan',
    });
    expect(deck.ownerName, 'Lan');
  });

  test('PublicUser maps every FriendRelation value', () {
    PublicUser user(String relation) => PublicUser.fromJson(
        {'id': '1', 'displayName': 'A', 'avatar': null, 'relation': relation});
    expect(user('NONE').relation, FriendRelation.none);
    expect(user('REQUEST_SENT').relation, FriendRelation.requestSent);
    expect(user('REQUEST_RECEIVED').relation, FriendRelation.requestReceived);
    expect(user('FRIEND').relation, FriendRelation.friend);
    expect(user('BLOCKED').relation, FriendRelation.blocked);
  });

  test('AttemptAnswerView carries explanation and LISTENING attempts are recognised', () {
    final a = AttemptAnswerView.fromJson({
      'itemId': '1',
      'term': 'x',
      'meaning': 'y',
      'mode': 'MEANING',
      'answer': null,
      'correct': false,
      'correctAnswer': 'y',
      'explanation': 'Giải thích',
      'imageUrl': null,
    });
    expect(a.explanation, 'Giải thích');
    expect(attemptTypeFromString('LISTENING'), AttemptType.listening);
    expect(AttemptType.listening.apiValue, 'LISTENING');
  });

  test('AppNotification.copyWith only changes the read flag', () {
    const n = AppNotification(
      key: 'due:2026-10-05',
      icon: Icons.alarm_rounded,
      color: Colors.orange,
      title: 't',
      body: 'b',
      route: '/x',
    );
    expect(n.read, isFalse);
    final read = n.copyWith(read: true);
    expect(read.read, isTrue);
    expect(read.key, n.key);
    expect(read.route, '/x');
  });

  test('AppColors switches palette and the theme follows it', () {
    AppColors.setDark(false);
    final lightBg = AppColors.background;
    expect(AppTheme.build().brightness, Brightness.light);
    AppColors.setDark(true);
    expect(AppColors.background, isNot(lightBg));
    final dark = AppTheme.build();
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, AppColors.background);
    // màu nhấn giữ nguyên ở cả hai chế độ
    expect(AppColors.primary, const Color(0xFF2FAE60));
  });

  test('ThemeController updates the selected mode even without secure storage', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeControllerProvider), ThemeMode.system);
    await container.read(themeControllerProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeControllerProvider), ThemeMode.dark);
  });

  testWidgets('ItemImage renders data URLs and hides unsupported schemes', (tester) async {
    const png =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        ItemImage(url: png, height: 40),
        ItemImage(url: 'javascript:alert(1)', height: 40),
      ]),
    ));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });
}

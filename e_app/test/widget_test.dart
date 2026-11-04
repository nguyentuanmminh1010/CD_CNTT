import 'package:e_app/core/network/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_app/main.dart';

/// Tránh gọi plugin platform channel thật (flutter_secure_storage) trong
/// widget test — coi như luôn chưa đăng nhập.
class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

void main() {
  testWidgets('App boots and shows the splash screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Learn E'), findsOneWidget);

    // Flush the splash screen's auto-navigate timer before the test ends.
    await tester.pump(const Duration(milliseconds: 2000));
  });
}

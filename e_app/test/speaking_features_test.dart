import 'package:e_app/features/speaking/application/speech_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareWords', () {
    test('đánh dấu từ bị bỏ sót', () {
      final r = compareWords('i like coffee', 'I really like coffee');
      expect(r.map((w) => w.word), ['i', 'really', 'like', 'coffee']);
      expect(r.map((w) => w.matched), [true, false, true, true]);
    });

    test('nói đúng hết thì mọi từ khớp, nói rỗng thì không từ nào khớp', () {
      expect(compareWords('Good morning!', 'good morning').every((w) => w.matched), isTrue);
      expect(compareWords('', 'good morning').any((w) => w.matched), isFalse);
    });

    test('từ nói thừa không làm sai từ mẫu', () {
      final r = compareWords('well I see you', 'I see you');
      expect(r.every((w) => w.matched), isTrue);
    });
  });

  group('speakingPace', () {
    test('tính từ/phút và bỏ qua khi quá ngắn', () {
      expect(speakingPace('one two three four', const Duration(seconds: 2)), 120);
      expect(speakingPace('hello', const Duration(seconds: 3)), isNull);
      expect(speakingPace('one two three', const Duration(milliseconds: 500)), isNull);
    });

    test('nhãn theo ngưỡng', () {
      expect(paceLabel(40), contains('chậm'));
      expect(paceLabel(120), contains('tự nhiên'));
      expect(paceLabel(220), contains('nhanh'));
    });
  });
}

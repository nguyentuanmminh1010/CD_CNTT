import 'package:e_app/features/decks/application/deck_csv.dart';
import 'package:e_app/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item(String term, String meaning, {String? example, String? phonetic}) =>
    VocabularyItem(
      id: '1',
      term: term,
      phonetic: phonetic,
      meaning: meaning,
      example: example,
      mastered: false,
    );

void main() {
  test('buildDeckCsv: có tiêu đề, đặt mọi trường trong ngoặc kép và thoát dấu ngoặc kép', () {
    final csv = buildDeckCsv([
      _item('apple', 'quả táo, đỏ', example: 'I said "hi"', phonetic: '/ˈæp.əl/'),
      _item('run', 'chạy'),
    ]);
    final lines = csv.split('\n');
    expect(lines.first, '"term","meaning","example","phonetic"');
    expect(lines[1], '"apple","quả táo, đỏ","I said ""hi""","/ˈæp.əl/"');
    expect(lines[2], '"run","chạy","",""');
  });

  test('buildDeckCsv: xuống dòng trong trường được gộp thành khoảng trắng', () {
    final csv = buildDeckCsv([_item('a', 'dòng 1\ndòng 2')]);
    expect(csv.split('\n').length, 2);
    expect(csv, contains('dòng 1 dòng 2'));
  });

  test('decodeImportedFile bỏ BOM của Excel và đọc UTF-8 tiếng Việt', () {
    expect(decodeImportedFile(const [0xEF, 0xBB, 0xBF, 0x61]), 'a');
    expect(decodeImportedFile(const [0xE1, 0xBA, 0xA3]), 'ả');
  });
}

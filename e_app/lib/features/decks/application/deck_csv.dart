import 'dart:convert';

import '../../vocabulary/domain/vocabulary_models.dart';

/// Xuất bộ thẻ thành CSV chuẩn (mọi trường đặt trong ngoặc kép, có dòng tiêu đề) — backend nhập lại
/// được nguyên vẹn qua "Nhập hàng loạt" (`DeckService.importItems` nhận dòng bắt đầu bằng `"`).
/// Giải thích/ảnh/audio không nằm trong CSV (chỉ term, nghĩa, ví dụ, phiên âm).
String buildDeckCsv(List<VocabularyItem> items) {
  String q(String? v) =>
      '"${(v ?? '').replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAll('"', '""')}"';
  final lines = ['"term","meaning","example","phonetic"'];
  for (final it in items) {
    lines.add(
      [q(it.term), q(it.meaning), q(it.example), q(it.phonetic)].join(','),
    );
  }
  return lines.join('\n');
}

/// Giải mã nội dung file đã chọn (UTF-8, bỏ BOM mà Excel thêm khi lưu CSV).
String decodeImportedFile(List<int> bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);
  return text.startsWith('\uFEFF') ? text.substring(1) : text;
}

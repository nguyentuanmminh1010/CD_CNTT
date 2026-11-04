import 'package:flutter/material.dart';

/// 4 kỹ năng theo đặc tả — độc lập với category nội dung (Vocabulary/Grammar/
/// Sentence): mỗi kỹ năng là một CÁCH luyện tập (Trắc nghiệm = Đọc, Dịch câu =
/// Viết...) áp dụng được lên mục nội dung của bất kỳ category nào.
enum SkillType { reading, writing, listening, speaking }

extension SkillTypeApi on SkillType {
  String get apiValue => switch (this) {
        SkillType.reading => 'READING',
        SkillType.writing => 'WRITING',
        SkillType.listening => 'LISTENING',
        SkillType.speaking => 'SPEAKING',
      };

  String get label => switch (this) {
        SkillType.reading => 'Đọc',
        SkillType.writing => 'Viết',
        SkillType.listening => 'Nghe',
        SkillType.speaking => 'Nói',
      };

  IconData get icon => switch (this) {
        SkillType.reading => Icons.menu_book_rounded,
        SkillType.writing => Icons.edit_note_rounded,
        SkillType.listening => Icons.headphones_rounded,
        SkillType.speaking => Icons.mic_rounded,
      };
}

SkillType skillTypeFromString(String value) {
  return switch (value) {
    'WRITING' => SkillType.writing,
    'LISTENING' => SkillType.listening,
    'SPEAKING' => SkillType.speaking,
    _ => SkillType.reading,
  };
}

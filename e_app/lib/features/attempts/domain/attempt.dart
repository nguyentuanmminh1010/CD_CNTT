import 'package:flutter/material.dart';

/// Loại lượt làm bài lưu vào lịch sử — khớp enum `AttemptType` ở backend.
enum AttemptType { assessment, placement, toeic, reading, writing, speaking, listening }

extension AttemptTypeInfo on AttemptType {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
        AttemptType.assessment => 'Đánh giá',
        AttemptType.placement => 'Xếp lớp',
        AttemptType.toeic => 'Luyện thi TOEIC',
        AttemptType.reading => 'Luyện Đọc',
        AttemptType.writing => 'Luyện Viết',
        AttemptType.speaking => 'Luyện Nói',
        AttemptType.listening => 'Luyện Nghe',
      };

  IconData get icon => switch (this) {
        AttemptType.assessment => Icons.fact_check_rounded,
        AttemptType.placement => Icons.flag_rounded,
        AttemptType.toeic => Icons.workspace_premium_rounded,
        AttemptType.reading => Icons.menu_book_rounded,
        AttemptType.writing => Icons.edit_note_rounded,
        AttemptType.speaking => Icons.mic_rounded,
        AttemptType.listening => Icons.headphones_rounded,
      };
}

AttemptType attemptTypeFromString(String value) {
  return AttemptType.values.firstWhere(
    (t) => t.apiValue == value,
    orElse: () => AttemptType.assessment,
  );
}

/// Một câu của lượt làm bài (đã chấm ở backend) — để xem lại đáp án.
class AttemptAnswerView {
  const AttemptAnswerView({
    required this.itemId,
    required this.term,
    required this.meaning,
    required this.mode,
    required this.answer,
    required this.correct,
    required this.correctAnswer,
    this.explanation,
    this.imageUrl,
  });

  final String itemId;
  final String term;
  final String meaning;
  final String mode;
  final String? answer;
  final bool correct;
  final String correctAnswer;

  /// Lời giải thích (do biên tập nhập hoặc backend sinh từ nghĩa + ví dụ) và hình minh hoạ.
  final String? explanation;
  final String? imageUrl;

  factory AttemptAnswerView.fromJson(Map<String, dynamic> json) => AttemptAnswerView(
        itemId: json['itemId'] as String,
        term: json['term'] as String,
        meaning: json['meaning'] as String,
        mode: json['mode'] as String,
        answer: json['answer'] as String?,
        correct: json['correct'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        explanation: json['explanation'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}

/// Một lượt làm bài đã hoàn thành (query `myAttempts`).
class Attempt {
  const Attempt({
    required this.id,
    required this.type,
    required this.title,
    required this.totalQuestions,
    required this.correctCount,
    required this.scorePercent,
    required this.createdAt,
  });

  final String id;
  final AttemptType type;
  final String title;
  final int totalQuestions;
  final int correctCount;
  final int scorePercent;
  final DateTime createdAt;

  /// "dd/MM/yyyy HH:mm" theo giờ máy người dùng.
  String get dateLabel {
    final d = createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['id'] as String,
      type: attemptTypeFromString(json['type'] as String),
      title: json['title'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      scorePercent: json['scorePercent'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

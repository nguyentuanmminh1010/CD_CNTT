class VocabularyTopic {
  const VocabularyTopic({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.wordCount,
    this.category = 'VOCABULARY',
    this.mine = false,
    this.editable = false,
    this.guide,
    this.shareCode,
  });

  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int wordCount;

  /// 'VOCABULARY' | 'GRAMMAR' | 'SENTENCE'.
  final String category;

  /// Bộ thẻ riêng do chính người dùng tạo (không phải chủ đề hệ thống).
  final bool mine;

  /// Người dùng hiện tại sửa được chủ đề này (chủ bộ thẻ, hoặc admin với chủ đề hệ thống).
  final bool editable;

  /// Nội dung tab "Hướng dẫn" (mỗi dòng một bước); null = dùng các bước mặc định ở client.
  final String? guide;

  /// Mã chia sẻ bộ thẻ riêng (chỉ chủ bộ thẻ thấy); null = không chia sẻ.
  final String? shareCode;

  factory VocabularyTopic.fromJson(Map<String, dynamic> json) {
    return VocabularyTopic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      wordCount: json['wordCount'] as int? ?? 0,
      category: json['category'] as String? ?? 'VOCABULARY',
      mine: json['mine'] as bool? ?? false,
      editable: json['editable'] as bool? ?? false,
      guide: json['guide'] as String?,
      shareCode: json['shareCode'] as String?,
    );
  }
}

class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.term,
    required this.phonetic,
    required this.meaning,
    required this.example,
    required this.mastered,
    this.difficultyLevel = 1,
    this.explanation,
    this.imageUrl,
    this.audioUrl,
  });

  final String id;
  final String term;
  final String? phonetic;
  final String meaning;
  final String? example;
  final bool mastered;
  /// 1 = cơ bản, 2 = trung bình, 3 = nâng cao (xem `LearningItem.difficultyLevel` ở backend).
  final int difficultyLevel;

  /// Lời giải thích (null = chưa có), hình minh hoạ (URL http(s) hoặc data URL) và link audio (null = đọc bằng TTS).
  final String? explanation;
  final String? imageUrl;
  final String? audioUrl;

  VocabularyItem copyWith({bool? mastered}) {
    return VocabularyItem(
      id: id,
      term: term,
      phonetic: phonetic,
      meaning: meaning,
      example: example,
      mastered: mastered ?? this.mastered,
      difficultyLevel: difficultyLevel,
      explanation: explanation,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
    );
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      term: json['term'] as String,
      phonetic: json['phonetic'] as String?,
      meaning: json['meaning'] as String,
      example: json['example'] as String?,
      mastered: json['mastered'] as bool? ?? false,
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      explanation: json['explanation'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
    );
  }
}

const _difficultyLabels = {1: 'Cơ bản', 2: 'Trung bình', 3: 'Nâng cao'};

extension VocabularyItemDifficulty on VocabularyItem {
  String get difficultyLabel => _difficultyLabels[difficultyLevel] ?? 'Cơ bản';
}

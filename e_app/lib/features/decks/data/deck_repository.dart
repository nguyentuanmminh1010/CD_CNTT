import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../../vocabulary/domain/vocabulary_models.dart';

/// Kết quả nhập hàng loạt thẻ.
class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.errors,
  });

  final int added;
  final int skipped;
  final List<String> errors;

  factory ImportResult.fromJson(Map<String, dynamic> json) => ImportResult(
    added: json['added'] as int,
    skipped: json['skipped'] as int,
    errors: (json['errors'] as List<dynamic>).cast<String>(),
  );
}

/// Bản xem trước bộ thẻ được chia sẻ qua mã.
class SharedDeck {
  const SharedDeck({
    required this.code,
    required this.name,
    required this.description,
    required this.wordCount,
    required this.ownerName,
  });

  final String code;
  final String name;
  final String? description;
  final int wordCount;
  final String ownerName;

  factory SharedDeck.fromJson(Map<String, dynamic> json) => SharedDeck(
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    wordCount: json['wordCount'] as int,
    ownerName: json['ownerName'] as String,
  );
}

/// Bộ thẻ bạn bè gửi riêng cho bạn, đang chờ nhận hoặc từ chối.
class DeckGift {
  const DeckGift({
    required this.id,
    required this.name,
    required this.wordCount,
    required this.senderName,
  });

  final String id;
  final String name;
  final int wordCount;
  final String senderName;

  factory DeckGift.fromJson(Map<String, dynamic> json) => DeckGift(
    id: json['id'].toString(),
    name: json['name'] as String,
    wordCount: json['wordCount'] as int,
    senderName: json['senderName'] as String,
  );
}

/// Quản lý bộ thẻ riêng của người dùng (chủ đề + thẻ) và, với admin, nội dung chủ đề hệ thống.
/// Quyền được backend kiểm tra ở từng mutation (`DeckService`).
class DeckRepository {
  DeckRepository(this._client);

  final GraphQLClient _client;

  static const _topicFields =
      'id name description icon wordCount category mine editable guide shareCode';

  Future<Map<String, dynamic>> _query(
    String doc, [
    Map<String, dynamic>? vars,
  ]) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(doc),
        variables: vars ?? const {},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw GraphQLFailure.fromException(result.exception!);
    }
    return result.data!;
  }

  Future<Map<String, dynamic>> _mutate(
    String doc,
    Map<String, dynamic> vars,
  ) async {
    final result = await _client.mutate(
      MutationOptions(document: gql(doc), variables: vars),
    );
    if (result.hasException) {
      throw GraphQLFailure.fromException(result.exception!);
    }
    return result.data!;
  }

  List<VocabularyTopic> _topics(Object? raw) => (raw as List<dynamic>)
      .map((e) => VocabularyTopic.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<VocabularyTopic>> fetchMyDecks() async =>
      _topics((await _query('{ myDecks { $_topicFields } }'))['myDecks']);

  /// Admin: toàn bộ chủ đề hệ thống (mọi category).
  Future<List<VocabularyTopic>> fetchSystemTopics() async => _topics(
    (await _query('{ systemTopics { $_topicFields } }'))['systemTopics'],
  );

  Future<VocabularyTopic> createDeck(String name, String? description) async {
    final data = await _mutate(
      'mutation(\$n: String!, \$d: String) { createDeck(name: \$n, description: \$d) { $_topicFields } }',
      {'n': name, 'd': description},
    );
    return VocabularyTopic.fromJson(data['createDeck'] as Map<String, dynamic>);
  }

  Future<VocabularyTopic> updateTopic(
    String topicId, {
    String? name,
    String? description,
    String? guide,
  }) async {
    final data = await _mutate(
      'mutation(\$t: ID!, \$n: String, \$d: String, \$g: String) '
      '{ updateTopic(topicId: \$t, name: \$n, description: \$d, guide: \$g) { $_topicFields } }',
      {'t': topicId, 'n': name, 'd': description, 'g': guide},
    );
    return VocabularyTopic.fromJson(
      data['updateTopic'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteTopic(String topicId) async {
    await _mutate('mutation(\$t: ID!) { deleteTopic(topicId: \$t) }', {
      't': topicId,
    });
  }

  Future<void> addItem(
    String topicId, {
    required String term,
    String? phonetic,
    required String meaning,
    String? example,
    int difficulty = 1,
    String? explanation,
    String? imageUrl,
    String? audioUrl,
  }) async {
    await _mutate(
      'mutation(\$t: ID!, \$a: String!, \$p: String, \$m: String!, \$e: String, \$l: Int, \$x: String, \$im: String, \$au: String) '
      '{ addItem(topicId: \$t, term: \$a, phonetic: \$p, meaning: \$m, example: \$e, difficultyLevel: \$l, '
      'explanation: \$x, imageUrl: \$im, audioUrl: \$au) { id } }',
      {
        't': topicId,
        'a': term,
        'p': phonetic,
        'm': meaning,
        'e': example,
        'l': difficulty,
        'x': explanation,
        'im': imageUrl,
        'au': audioUrl,
      },
    );
  }

  Future<void> updateItem(
    String itemId, {
    required String term,
    String? phonetic,
    required String meaning,
    String? example,
    int difficulty = 1,
    String? explanation,
    String? imageUrl,
    String? audioUrl,
  }) async {
    await _mutate(
      'mutation(\$i: ID!, \$a: String!, \$p: String, \$m: String!, \$e: String, \$l: Int, \$x: String, \$im: String, \$au: String) '
      '{ updateItem(itemId: \$i, term: \$a, phonetic: \$p, meaning: \$m, example: \$e, difficultyLevel: \$l, '
      'explanation: \$x, imageUrl: \$im, audioUrl: \$au) { id } }',
      {
        'i': itemId,
        'a': term,
        'p': phonetic,
        'm': meaning,
        'e': example,
        'l': difficulty,
        'x': explanation,
        'im': imageUrl,
        'au': audioUrl,
      },
    );
  }

  Future<void> deleteItem(String itemId) async {
    await _mutate('mutation(\$i: ID!) { deleteItem(itemId: \$i) }', {
      'i': itemId,
    });
  }

  /// Nhập nhiều thẻ từ văn bản dán vào (mỗi dòng: term | nghĩa | ví dụ | phiên âm).
  Future<ImportResult> importItems(String topicId, String text) async {
    final data = await _mutate(
      'mutation(\$t: ID!, \$x: String!) { importItems(topicId: \$t, text: \$x) { added skipped errors } }',
      {'t': topicId, 'x': text},
    );
    return ImportResult.fromJson(data['importItems'] as Map<String, dynamic>);
  }

  /// Bật chia sẻ bộ thẻ và trả mã chia sẻ.
  Future<String> shareDeck(String topicId) async {
    final data = await _mutate(
      'mutation(\$t: ID!) { shareDeck(topicId: \$t) }',
      {'t': topicId},
    );
    return data['shareDeck'] as String;
  }

  Future<void> unshareDeck(String topicId) async {
    await _mutate('mutation(\$t: ID!) { unshareDeck(topicId: \$t) }', {
      't': topicId,
    });
  }

  Future<SharedDeck> fetchSharedDeck(String code) async {
    final data = await _query(
      'query(\$c: String!) { sharedDeck(code: \$c) { code name description wordCount ownerName } }',
      {'c': code},
    );
    return SharedDeck.fromJson(data['sharedDeck'] as Map<String, dynamic>);
  }

  /// Sao chép bộ thẻ được chia sẻ về thành bộ thẻ riêng của bạn.
  Future<VocabularyTopic> importSharedDeck(String code) async {
    final data = await _mutate(
      'mutation(\$c: String!) { importSharedDeck(code: \$c) { $_topicFields } }',
      {'c': code},
    );
    return VocabularyTopic.fromJson(
      data['importSharedDeck'] as Map<String, dynamic>,
    );
  }

  /// Gửi bộ thẻ riêng của bạn cho một người bạn (đã kết bạn).
  Future<void> sendDeckToFriend(String topicId, String friendId) async {
    await _mutate(
      'mutation(\$t: ID!, \$f: ID!) { sendDeckToFriend(topicId: \$t, friendId: \$f) }',
      {'t': topicId, 'f': friendId},
    );
  }

  /// Bộ thẻ bạn bè đã gửi riêng cho bạn và đang chờ nhận.
  Future<List<DeckGift>> fetchDeckGifts() async {
    final data = await _query('{ deckGifts { id name wordCount senderName } }');
    return (data['deckGifts'] as List<dynamic>)
        .map((e) => DeckGift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Nhận (trả về bộ thẻ mới đã sao chép) hoặc từ chối (trả null) bộ thẻ được gửi.
  Future<VocabularyTopic?> respondDeckGift(
    String giftId, {
    required bool accept,
  }) async {
    final data = await _mutate(
      'mutation(\$g: ID!, \$a: Boolean!) { respondDeckGift(giftId: \$g, accept: \$a) { $_topicFields } }',
      {'g': giftId, 'a': accept},
    );
    final raw = data['respondDeckGift'];
    return raw == null
        ? null
        : VocabularyTopic.fromJson(raw as Map<String, dynamic>);
  }
}

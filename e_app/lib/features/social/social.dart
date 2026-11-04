import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

import '../../core/network/graphql_client.dart';
import '../../core/network/graphql_failure.dart';

/// Quan hệ của người dùng hiện tại với một người khác — khớp enum `FriendRelation` ở backend.
enum FriendRelation { none, requestSent, requestReceived, friend, blocked }

FriendRelation _relationFrom(String value) => switch (value) {
      'REQUEST_SENT' => FriendRelation.requestSent,
      'REQUEST_RECEIVED' => FriendRelation.requestReceived,
      'FRIEND' => FriendRelation.friend,
      'BLOCKED' => FriendRelation.blocked,
      _ => FriendRelation.none,
    };

/// Thông tin công khai của một người dùng (không có email) — dùng cho tìm bạn/danh sách bạn bè.
class PublicUser {
  const PublicUser({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.relation,
  });

  final String id;
  final String displayName;
  final String? avatar;
  final FriendRelation relation;

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        avatar: json['avatar'] as String?,
        relation: _relationFrom(json['relation'] as String),
      );
}

/// Bạn bè HAI CHIỀU: gửi lời mời → đối phương chấp nhận/từ chối; có thể huỷ kết bạn và chặn.
/// Bảng xếp hạng "Bạn bè" chỉ tính những người đã chấp nhận.
class SocialRepository {
  SocialRepository(this._client);

  final GraphQLClient _client;

  static const _fields = 'id displayName avatar relation';

  Future<Map<String, dynamic>> _query(String doc, [Map<String, dynamic>? vars]) async {
    final result = await _client.query(QueryOptions(
      document: gql(doc),
      variables: vars ?? const {},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return result.data!;
  }

  Future<void> _mutate(String name, String userId, {bool? accept}) async {
    final withAccept = accept != null;
    final result = await _client.mutate(MutationOptions(
      document: gql(
        'mutation(\$u: ID!${withAccept ? ', \$a: Boolean!' : ''}) '
        '{ $name(userId: \$u${withAccept ? ', accept: \$a' : ''}) { $_fields } }',
      ),
      variables: {'u': userId, if (withAccept) 'a': accept},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
  }

  List<PublicUser> _list(Object? raw) =>
      (raw as List<dynamic>).map((e) => PublicUser.fromJson(e as Map<String, dynamic>)).toList();

  Future<List<PublicUser>> search(String query) async =>
      _list((await _query('query(\$q: String!) { searchUsers(query: \$q) { $_fields } }', {'q': query}))['searchUsers']);

  Future<List<PublicUser>> friends() async =>
      _list((await _query('{ friends { $_fields } }'))['friends']);

  /// Lời mời kết bạn đang chờ bạn trả lời.
  Future<List<PublicUser>> friendRequests() async =>
      _list((await _query('{ friendRequests { $_fields } }'))['friendRequests']);

  /// Người vừa chấp nhận lời mời của bạn trong 7 ngày qua (nguồn cho thông báo).
  Future<List<PublicUser>> recentFriends() async =>
      _list((await _query('{ recentFriends { $_fields } }'))['recentFriends']);

  Future<List<PublicUser>> blockedUsers() async =>
      _list((await _query('{ blockedUsers { $_fields } }'))['blockedUsers']);

  Future<void> sendRequest(String userId) => _mutate('sendFriendRequest', userId);

  Future<void> respond(String userId, {required bool accept}) =>
      _mutate('respondFriendRequest', userId, accept: accept);

  /// Huỷ kết bạn hoặc thu hồi lời mời đã gửi.
  Future<void> remove(String userId) => _mutate('removeFriend', userId);

  Future<void> block(String userId) => _mutate('blockUser', userId);

  Future<void> unblock(String userId) => _mutate('unblockUser', userId);
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(graphQLClientProvider));
});

final friendsProvider = FutureProvider.autoDispose<List<PublicUser>>((ref) {
  return ref.watch(socialRepositoryProvider).friends();
});

final friendRequestsProvider = FutureProvider.autoDispose<List<PublicUser>>((ref) {
  return ref.watch(socialRepositoryProvider).friendRequests();
});

final recentFriendsProvider = FutureProvider.autoDispose<List<PublicUser>>((ref) {
  return ref.watch(socialRepositoryProvider).recentFriends();
});

final blockedUsersProvider = FutureProvider.autoDispose<List<PublicUser>>((ref) {
  return ref.watch(socialRepositoryProvider).blockedUsers();
});

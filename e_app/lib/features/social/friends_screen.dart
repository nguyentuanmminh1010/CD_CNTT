import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../profile/presentation/widgets/user_avatar.dart';
import 'social.dart';

/// Bạn bè hai chiều: danh sách bạn, lời mời đang chờ, tìm người để kết bạn, người đã chặn.
/// Bảng xếp hạng "Bạn bè" chỉ gồm những người đã chấp nhận lời mời.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(friendRequestsProvider).valueOrNull?.length ?? 0;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Bạn bè'),
          bottom: TabBar(
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: 'Bạn bè'),
              Tab(text: requests > 0 ? 'Lời mời ($requests)' : 'Lời mời'),
              const Tab(text: 'Tìm bạn'),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: const TabBarView(
                children: [_FriendsTab(), _RequestsTab(), _SearchTab()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng người dùng: ảnh đại diện + tên + [trailing] (nút kích thước cố định, xem gotcha ở CLAUDE.md).
class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.trailing});

  final PublicUser user;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          UserAvatar(avatar: user.avatar, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

Widget _sizedButton({
  required String label,
  required VoidCallback? onPressed,
  bool outlined = false,
  double width = 112,
}) {
  return SizedBox(
    width: width,
    height: 40,
    child: outlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            onPressed: onPressed,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            onPressed: onPressed,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ),
  );
}

void _snack(BuildContext context, Object e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Widget _empty(IconData icon, String title, String body) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );

// ───────────────────────── Tab Bạn bè (+ đã chặn) ─────────────────────────

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(friendsProvider);
      ref.invalidate(blockedUsersProvider);
    } catch (e) {
      if (context.mounted) _snack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final blocked = ref.watch(blockedUsersProvider).valueOrNull ?? const <PublicUser>[];
    final repo = ref.read(socialRepositoryProvider);
    return friends.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(friendsProvider),
          child: const Text('Không tải được. Thử lại'),
        ),
      ),
      data: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (list.isEmpty)
            SizedBox(
              height: 260,
              child: _empty(Icons.group_outlined, 'Chưa có bạn bè',
                  'Vào tab "Tìm bạn" để gửi lời mời. Khi họ chấp nhận, hai bạn sẽ thấy nhau trong bảng xếp hạng "Bạn bè".'),
            ),
          for (final u in list)
            _UserRow(
              user: u,
              trailing: PopupMenuButton<String>(
                tooltip: 'Tuỳ chọn',
                onSelected: (v) => _run(context, ref, () async {
                  if (v == 'remove') await repo.remove(u.id);
                  if (v == 'block') await repo.block(u.id);
                }),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remove', child: Text('Huỷ kết bạn')),
                  PopupMenuItem(value: 'block', child: Text('Chặn')),
                ],
              ),
            ),
          if (blocked.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Đã chặn (${blocked.length})',
                style: TextStyle(
                    color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 13)),
            for (final u in blocked)
              _UserRow(
                user: u,
                trailing: _sizedButton(
                  label: 'Bỏ chặn',
                  outlined: true,
                  onPressed: () => _run(context, ref, () => repo.unblock(u.id)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Tab Lời mời ─────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  Future<void> _respond(BuildContext context, WidgetRef ref, PublicUser u, bool accept) async {
    try {
      await ref.read(socialRepositoryProvider).respond(u.id, accept: accept);
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsProvider);
    } catch (e) {
      if (context.mounted) _snack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestsProvider);
    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: OutlinedButton(
          onPressed: () => ref.invalidate(friendRequestsProvider),
          child: const Text('Không tải được. Thử lại'),
        ),
      ),
      data: (list) => list.isEmpty
          ? _empty(Icons.mail_outline_rounded, 'Không có lời mời nào',
              'Khi ai đó gửi lời mời kết bạn, bạn sẽ thấy ở đây (và trong Thông báo).')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final u in list)
                  _UserRow(
                    user: u,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _sizedButton(
                          label: 'Chấp nhận',
                          width: 104,
                          onPressed: () => _respond(context, ref, u, true),
                        ),
                        IconButton(
                          tooltip: 'Từ chối',
                          onPressed: () => _respond(context, ref, u, false),
                          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ───────────────────────── Tab Tìm bạn ─────────────────────────

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _controller = TextEditingController();
  List<PublicUser> _results = [];
  bool _loading = false;
  String? _message;
  int _requestId = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _message = null;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final found = await ref.read(socialRepositoryProvider).search(query.trim());
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = found;
        _message = found.isEmpty ? 'Không tìm thấy người dùng nào.' : null;
      });
    } catch (e) {
      if (mounted && id == _requestId) setState(() => _message = 'Không tìm được. Vui lòng thử lại.');
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  /// Chạy một thao tác rồi tìm lại để cập nhật quan hệ hiển thị.
  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsProvider);
      ref.invalidate(blockedUsersProvider);
      await _search(_controller.text);
    } catch (e) {
      if (mounted) _snack(context, e);
    }
  }

  Widget _trailing(PublicUser u) {
    final repo = ref.read(socialRepositoryProvider);
    return switch (u.relation) {
      FriendRelation.none => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sizedButton(
              label: 'Kết bạn',
              width: 96,
              onPressed: () => _act(() => repo.sendRequest(u.id)),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tuỳ chọn',
              onSelected: (_) => _act(() => repo.block(u.id)),
              itemBuilder: (_) => const [PopupMenuItem(value: 'block', child: Text('Chặn'))],
            ),
          ],
        ),
      FriendRelation.requestSent => _sizedButton(
          label: 'Đã gửi · Thu hồi',
          outlined: true,
          width: 152,
          onPressed: () => _act(() => repo.remove(u.id)),
        ),
      FriendRelation.requestReceived => _sizedButton(
          label: 'Chấp nhận',
          width: 112,
          onPressed: () => _act(() => repo.respond(u.id, accept: true)),
        ),
      FriendRelation.friend => const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              SizedBox(width: 4),
              Text('Bạn bè',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      FriendRelation.blocked => _sizedButton(
          label: 'Bỏ chặn',
          outlined: true,
          onPressed: () => _act(() => repo.unblock(u.id)),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gửi lời mời để xem thứ hạng của nhau ở mục "Bạn bè".',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Nhập tên hoặc email (ít nhất 2 ký tự)',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!, style: TextStyle(color: AppColors.textSecondary)),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final u in _results) _UserRow(user: u, trailing: _trailing(u)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/graphql_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_controller.dart';

/// Đặt lại mật khẩu 2 bước: (1) nhập email để nhận mã 6 số, (2) nhập mã + mật khẩu mới.
/// Backend luôn báo "đã gửi" dù email có tồn tại hay không (không lộ danh sách tài khoản).
/// ⚠️ Mã hiện chỉ được GHI VÀO LOG MÁY CHỦ (chưa cấu hình gửi email thật) — xem `ResetCodeSender`.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on GraphQLFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
        final email = _email.text.trim();
        if (!email.contains('@')) {
          throw const GraphQLFailure('Vui lòng nhập email hợp lệ.');
        }
        await ref.read(authRepositoryProvider).requestPasswordReset(email);
        if (mounted) setState(() => _codeSent = true);
      });

  Future<void> _reset() => _run(() async {
        if (_password.text.length < 6) {
          throw const GraphQLFailure('Mật khẩu mới cần có ít nhất 6 ký tự.');
        }
        await ref.read(authRepositoryProvider).resetPassword(
              _email.text.trim(),
              _code.text.trim(),
              _password.text,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đổi mật khẩu. Hãy đăng nhập lại.')),
        );
        context.pop();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Quên mật khẩu'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  _codeSent
                      ? 'Nếu email này có tài khoản, một mã 6 số (hiệu lực 15 phút) đã được gửi. Nhập mã và mật khẩu mới bên dưới.'
                      : 'Nhập email đã đăng ký, chúng tôi sẽ gửi mã 6 số để bạn đặt lại mật khẩu.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _email,
                  enabled: !_codeSent && !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Mã 6 số',
                      prefixIcon: Icon(Icons.pin_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
                  child: Text(_busy
                      ? 'Đang xử lý...'
                      : _codeSent
                          ? 'Đặt lại mật khẩu'
                          : 'Gửi mã'),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _error = null;
                              _code.clear();
                              _password.clear();
                            }),
                    child: const Text('Gửi lại mã / đổi email'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

/// Phát âm nội dung học: mục có `audioUrl` thì phát file bằng `just_audio`; không có thì đọc `term`/câu
/// bằng giọng máy (`flutter_tts`, en-US) — nên mọi mục đều nghe được dù chưa có file audio biên tập.
/// Một đối tượng dùng chung toàn app để không phát chồng nhiều âm thanh cùng lúc.
class ItemAudio {
  ItemAudio._();

  static final ItemAudio instance = ItemAudio._();

  FlutterTts? _tts;
  AudioPlayer? _player;
  bool _ttsReady = false;

  /// Đang phát (để nút loa đổi biểu tượng).
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  Future<FlutterTts> _ensureTts() async {
    final tts = _tts ??= FlutterTts();
    if (!_ttsReady) {
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.45);
      tts.setCompletionHandler(() => speaking.value = false);
      tts.setCancelHandler(() => speaking.value = false);
      tts.setErrorHandler((_) => speaking.value = false);
      _ttsReady = true;
    }
    return tts;
  }

  /// Phát [text] (hoặc file [audioUrl] nếu có); [slow] đọc chậm hơn (luyện nghe). Trả về false nếu
  /// thiết bị không phát được.
  Future<bool> speak(String text, {String? audioUrl, bool slow = false}) async {
    await stop();
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        final player = _player ??= AudioPlayer();
        await player.setUrl(audioUrl);
        await player.setSpeed(slow ? 0.7 : 1.0);
        speaking.value = true;
        await player.play();
        speaking.value = false;
        return true;
      } catch (e) {
        debugPrint('Phát file audio thất bại, chuyển sang đọc bằng giọng máy: $e');
        speaking.value = false;
      }
    }
    try {
      final tts = await _ensureTts();
      await tts.setSpeechRate(slow ? 0.25 : 0.45);
      speaking.value = true;
      await tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('Đọc bằng giọng máy thất bại: $e');
      speaking.value = false;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      await _tts?.stop();
    } catch (e) {
      debugPrint('Dừng phát âm thất bại: $e');
    }
    speaking.value = false;
  }
}
